using System.ClientModel;
using Exercise402;
using Microsoft.Agents.AI;
using Microsoft.Extensions.AI;
using OpenAI.Responses;

#pragma warning disable OPENAI001

var endpoint = Environment.GetEnvironmentVariable("FOUNDRY_ENDPOINT")
    ?? throw new InvalidOperationException("Set FOUNDRY_ENDPOINT");
var key = Environment.GetEnvironmentVariable("FOUNDRY_API_KEY")
    ?? throw new InvalidOperationException("Set FOUNDRY_API_KEY");
var model = Environment.GetEnvironmentVariable("FOUNDRY_MODEL_DEPLOYMENT")
    ?? throw new InvalidOperationException("Set FOUNDRY_MODEL_DEPLOYMENT");

ResponsesClient client = new(
    credential: new ApiKeyCredential(key),
    options: new ResponsesClientOptions
    {
        Endpoint = new UriBuilder(endpoint) { Path = "/openai/v1" }.Uri
    });
using IChatClient chatClient = client.AsIChatClient(model);
AIAgent? agent = null;
AgentSession? session = null;

Console.WriteLine("Exercise 402: demo sign-in, but the tool still trusts a model-controlled userId!");
Console.WriteLine("Commands: /auth, /logout, quit. Demo accounts: Alice / alice-snacks, Bob / bob-snacks.");
Console.WriteLine("Passwords are visible while typing in this workshop console; never enter real credentials.");

while (true)
{
    Console.Write("[USER]: ");
    var input = Console.ReadLine();
    if (input is null || input.Equals("quit", StringComparison.OrdinalIgnoreCase))
        break;
    if (string.IsNullOrWhiteSpace(input))
        continue;

    if (input.Equals("/auth", StringComparison.OrdinalIgnoreCase))
    {
        agent = null;
        session = null;
        Console.Write("Demo user name: ");
        var name = Console.ReadLine();
        Console.Write("Demo password: ");
        var password = Console.ReadLine();
        var user = DemoAuthentication.Authenticate(name, password);
        if (user is not null)
        {
            agent = chatClient.AsAIAgent(new ChatClientAgentOptions
            {
                ChatHistoryProvider = new InMemoryChatHistoryProvider(),
                ChatOptions = new ChatOptions
                {
                    Instructions = $"""
                        You are the Secret Snack Stash assistant. Use get_secret_snack for snack questions.
                        The authenticated user's userId is {user.Id}. Supply this userId to the tool.
                        """,
                    Tools = [AIFunctionFactory.Create(SnackTools.GetSecretSnack)],
                    RawRepresentationFactory = _ => new CreateResponseOptions { StoredOutputEnabled = false }
                }
            });
            session = await agent.CreateSessionAsync();
        }
        Console.WriteLine(user is null
            ? "[AUTH]: Sign-in failed. You are signed out."
            : $"[AUTH]: Signed in as {user.Name}, userId={user.Id}. Conversation reset.");
        continue;
    }
    if (input.Equals("/logout", StringComparison.OrdinalIgnoreCase))
    {
        agent = null;
        session = null;
        Console.WriteLine("[AUTH]: Signed out. Conversation reset.");
        continue;
    }
    if (agent is null || session is null)
    {
        Console.WriteLine("[AUTH]: Sign in using /auth before chatting.");
        continue;
    }

    var response = await agent.RunAsync(input, session);
    Console.WriteLine($"[ASSISTANT]: {response.Text}");
}
