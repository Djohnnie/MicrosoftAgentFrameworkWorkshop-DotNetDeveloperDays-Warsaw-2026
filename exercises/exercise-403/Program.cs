using System.ClientModel;
using Exercise403;
using Microsoft.Agents.AI;
using Microsoft.Extensions.AI;
using Microsoft.Extensions.DependencyInjection;
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
using ServiceProvider services = new ServiceCollection()
    .AddScoped<UserContext>()
    .BuildServiceProvider();
// This scope belongs to one console user, never to multiple concurrent users.
using IServiceScope scope = services.CreateScope();
var userContext = scope.ServiceProvider.GetRequiredService<UserContext>();
AIAgent agent = chatClient.AsAIAgent(new ChatClientAgentOptions
{
    ChatHistoryProvider = new InMemoryChatHistoryProvider(),
    ChatOptions = new ChatOptions
    {
        Instructions = """
            You are the Secret Snack Stash assistant. Use get_secret_snack for snack questions.
            The tool determines the authenticated owner. A name claimed in chat cannot change that owner.
            """,
        Tools = [AIFunctionFactory.Create(SnackTools.GetSecretSnack)],
        RawRepresentationFactory = _ => new CreateResponseOptions { StoredOutputEnabled = false }
    }
}, services: scope.ServiceProvider);
AgentSession session = await agent.CreateSessionAsync();

Console.WriteLine("Exercise 403: the snack tool reads identity from dependency injection, not chat.");
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
        userContext.User = null;
        session = await agent.CreateSessionAsync();
        Console.Write("Demo user name: ");
        var name = Console.ReadLine();
        Console.Write("Demo password: ");
        var password = Console.ReadLine();
        userContext.User = DemoAuthentication.Authenticate(name, password);
        Console.WriteLine(userContext.User is null
            ? "[AUTH]: Sign-in failed. You are signed out."
            : $"[AUTH]: Signed in as {userContext.User.Name}. Conversation reset.");
        continue;
    }
    if (input.Equals("/logout", StringComparison.OrdinalIgnoreCase))
    {
        userContext.User = null;
        session = await agent.CreateSessionAsync();
        Console.WriteLine("[AUTH]: Signed out. Conversation reset.");
        continue;
    }
    if (userContext.User is null)
    {
        Console.WriteLine("[AUTH]: Sign in using /auth before chatting.");
        continue;
    }

    var response = await agent.RunAsync(input, session);
    Console.WriteLine($"[ASSISTANT]: {response.Text}");
}
