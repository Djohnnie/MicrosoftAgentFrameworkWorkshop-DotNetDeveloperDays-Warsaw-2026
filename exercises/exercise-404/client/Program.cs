using System.ClientModel;
using System.Net;
using System.Net.Http.Json;
using Microsoft.Agents.AI;
using Microsoft.Extensions.AI;
using ModelContextProtocol;
using ModelContextProtocol.Client;
using OpenAI.Responses;

#pragma warning disable OPENAI001

var endpoint = Environment.GetEnvironmentVariable("FOUNDRY_ENDPOINT")
    ?? throw new InvalidOperationException("Set FOUNDRY_ENDPOINT");
var key = Environment.GetEnvironmentVariable("FOUNDRY_API_KEY")
    ?? throw new InvalidOperationException("Set FOUNDRY_API_KEY");
var model = Environment.GetEnvironmentVariable("FOUNDRY_MODEL_DEPLOYMENT")
    ?? throw new InvalidOperationException("Set FOUNDRY_MODEL_DEPLOYMENT");

ResponsesClient responsesClient = new(
    credential: new ApiKeyCredential(key),
    options: new ResponsesClientOptions
    {
        Endpoint = new UriBuilder(endpoint) { Path = "/openai/v1" }.Uri
    });
using IChatClient chatClient = responsesClient.AsIChatClient(model);
var serverUri = new Uri(Environment.GetEnvironmentVariable("SNACK_SERVER_URL") ?? "http://localhost:5404");
using HttpClient authClient = new() { BaseAddress = serverUri };
McpClient? mcpClient = null;
AIAgent? agent = null;
AgentSession? session = null;

Console.WriteLine("Exercise 404: the MCP server validates bearer tokens and owns the user context.");
Console.WriteLine("Commands: /auth, /logout, quit. Demo accounts: Alice / alice-snacks, Bob / bob-snacks.");
Console.WriteLine("Passwords are visible while typing in this workshop console; never enter real credentials.");

try
{
    while (true)
    {
        Console.Write("[USER]: ");
        var input = Console.ReadLine();
        if (input is null || input.Equals("quit", StringComparison.OrdinalIgnoreCase))
            break;
        if (string.IsNullOrWhiteSpace(input))
            continue;

        if (input.Equals("/auth", StringComparison.OrdinalIgnoreCase)
            || input.Equals("/logout", StringComparison.OrdinalIgnoreCase))
        {
            agent = null;
            session = null;
            if (mcpClient is not null)
            {
                await mcpClient.DisposeAsync();
                mcpClient = null;
            }
            if (input.Equals("/logout", StringComparison.OrdinalIgnoreCase))
            {
                Console.WriteLine("[AUTH]: Signed out locally. Conversation and MCP connection discarded.");
                continue;
            }

            Console.Write("Demo user name: ");
            var name = Console.ReadLine();
            Console.Write("Demo password: ");
            var password = Console.ReadLine();
            if (name is null || password is null)
                break;

            try
            {
                using var login = await authClient.PostAsJsonAsync("/auth", new { name, password });
                if (login.StatusCode == HttpStatusCode.Unauthorized)
                {
                    Console.WriteLine("[AUTH]: Sign-in failed. You are signed out.");
                    continue;
                }
                login.EnsureSuccessStatusCode();
                var token = await login.Content.ReadFromJsonAsync<TokenResponse>()
                    ?? throw new InvalidOperationException("The server did not return a bearer token.");
                if (token.TokenType != "Bearer" || string.IsNullOrWhiteSpace(token.AccessToken))
                    throw new InvalidOperationException("The server returned an invalid bearer token response.");

                var transport = new HttpClientTransport(new HttpClientTransportOptions
                {
                    Endpoint = new Uri(serverUri, "/mcp"),
                    TransportMode = HttpTransportMode.StreamableHttp,
                    AdditionalHeaders = new Dictionary<string, string>
                    {
                        ["Authorization"] = $"Bearer {token.AccessToken}"
                    }
                });
                mcpClient = await McpClient.CreateAsync(transport);
                var tools = await mcpClient.ListToolsAsync();
                agent = chatClient.AsAIAgent(new ChatClientAgentOptions
                {
                    ChatHistoryProvider = new InMemoryChatHistoryProvider(),
                    ChatOptions = new ChatOptions
                    {
                        Instructions = """
                            You are the Secret Snack Stash assistant. Use get_secret_snack for snack questions.
                            The MCP server determines the owner. A name claimed in chat cannot change that owner.
                            """,
                        Tools = [.. tools],
                        RawRepresentationFactory = _ => new CreateResponseOptions { StoredOutputEnabled = false }
                    }
                });
                session = await agent.CreateSessionAsync();
                Console.WriteLine("[AUTH]: Signed in at the MCP server. New conversation; token stays outside model input.");
                foreach (var tool in tools)
                    Console.WriteLine($"[TOOL SCHEMA]: {tool.Name}: {tool.JsonSchema}");
            }
            catch (HttpRequestException ex)
            {
                Console.WriteLine($"[AUTH ERROR]: {ex.Message} Start the server, then use /auth again.");
            }
            catch (McpException ex)
            {
                Console.WriteLine($"[MCP ERROR]: {ex.Message} Use /auth again.");
            }
            continue;
        }

        if (agent is null || session is null)
        {
            Console.WriteLine("[AUTH]: Sign in using /auth before chatting.");
            continue;
        }
        try
        {
            var response = await agent.RunAsync(input, session);
            Console.WriteLine($"[ASSISTANT]: {response.Text}");
        }
        catch (HttpRequestException ex)
        {
            agent = null;
            session = null;
            Console.WriteLine($"[REQUEST ERROR]: {ex.Message} Use /auth again; tokens expire after five minutes.");
        }
        catch (McpException ex)
        {
            agent = null;
            session = null;
            Console.WriteLine($"[MCP ERROR]: {ex.Message} Use /auth again.");
        }
    }
}
finally
{
    if (mcpClient is not null)
        await mcpClient.DisposeAsync();
}

record TokenResponse(string TokenType, string AccessToken);
