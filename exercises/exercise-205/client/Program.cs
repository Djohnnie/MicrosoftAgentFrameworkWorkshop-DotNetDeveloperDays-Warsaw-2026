using System.ClientModel;
using Microsoft.Agents.AI;
using Microsoft.Extensions.AI;
using ModelContextProtocol.Client;
using OpenAI;
using OpenAI.Responses;

#pragma warning disable OPENAI001

var transport = new HttpClientTransport(new HttpClientTransportOptions
{
    Endpoint = new Uri("http://localhost:5285/mcp"),
    TransportMode = HttpTransportMode.StreamableHttp
});
await using McpClient mcpClient = await McpClient.CreateAsync(transport);
IList<McpClientTool> mcpTools = await mcpClient.ListToolsAsync();

Console.WriteLine("Date and time tools available from the local MCP server:");
foreach (McpClientTool tool in mcpTools)
    Console.WriteLine(SingleLine($"- {tool.Name}: {tool.Description}"));

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

AIAgent agent = chatClient.AsAIAgent(new ChatClientAgentOptions
{
    ChatHistoryProvider = new InMemoryChatHistoryProvider(),
    ChatOptions = new ChatOptions
    {
        Tools = [.. mcpTools],
        RawRepresentationFactory = _ => new CreateResponseOptions
        {
            StoredOutputEnabled = false
        }
    }
});
AgentSession session = await agent.CreateSessionAsync();

Console.WriteLine("\nAsk for the current date or time. Type 'quit' to exit.");

while (true)
{
    Console.Write("[USER]: ");
    var input = Console.ReadLine();
    if (input is null || input.Equals("quit", StringComparison.OrdinalIgnoreCase))
        break;

    if (string.IsNullOrWhiteSpace(input))
        continue;

    var response = await agent.RunAsync(input, session);
    Console.WriteLine($"[ASSISTANT]: {response.Text}");
    DebugHistory(session);
}

static void DebugHistory(AgentSession session)
{
    Console.WriteLine("\n--- DEBUG: AgentSession local in-memory history ---");
    if (!session.TryGetInMemoryChatHistory(out var messages))
        throw new InvalidOperationException("Expected local chat history in the AgentSession.");

    Console.WriteLine($"Stored messages: {messages.Count}");
    for (var i = 0; i < messages.Count; i++)
    {
        var message = messages[i];
        foreach (var content in message.Contents)
        {
            switch (content)
            {
                case FunctionCallContent functionCall:
                    Console.WriteLine(SingleLine(
                        $"  {i + 1}. [FunctionCallContent] CallId: {functionCall.CallId}, Name: {functionCall.Name}"));
                    break;
                case FunctionResultContent functionResult:
                    Console.WriteLine(SingleLine(
                        $"  {i + 1}. [FunctionResultContent] CallId: {functionResult.CallId}, Result: {functionResult.Result}"));
                    break;
                default:
                    Console.WriteLine(SingleLine($"  {i + 1}. [{message.Role}]: {content}"));
                    break;
            }
        }
    }

    Console.WriteLine("--- END HISTORY ---\n");
}

static string SingleLine(string? text)
{
    const int maxLength = 180;

    if (string.IsNullOrWhiteSpace(text))
        return string.Empty;

    var singleLine = string.Join(' ', text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries));
    var lineLimit = Console.IsOutputRedirected
        ? maxLength
        : Math.Min(maxLength, Math.Max(1, Console.WindowWidth - 1));

    return singleLine.Length <= lineLimit
        ? singleLine
        : lineLimit <= 3
            ? singleLine[..lineLimit]
            : $"{singleLine[..(lineLimit - 3)]}...";
}
