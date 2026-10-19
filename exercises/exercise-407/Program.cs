using System.ClientModel;
using System.Text.Json;
using Microsoft.Agents.AI;
using Microsoft.Extensions.AI;
using OpenAI;
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

AIAgent agent = chatClient.AsAIAgent(new ChatClientAgentOptions
{
    Name = "HistoryAgent",
    ChatHistoryProvider = new InMemoryChatHistoryProvider(),
    ChatOptions = new ChatOptions
    {
        Instructions = """
            You are a helpful workshop assistant. Give short, friendly answers.
            Remember facts shared in this conversation.
            If the conversation does not contain an answer, say so instead of guessing.
            """,
        RawRepresentationFactory = _ => new CreateResponseOptions
        {
            StoredOutputEnabled = false
        }
    }
});

AgentSession session = await agent.CreateSessionAsync();
var sessionPath = Path.Combine(AppContext.BaseDirectory, "session.json");

Console.WriteLine("Local session persistence. Type 'quit' to exit.");
Console.WriteLine("Commands: /save, /load, /new, /history.");
Console.WriteLine($"Snapshot file: {sessionPath}");

while (true)
{
    Console.Write("[USER]: ");
    var input = Console.ReadLine();
    if (input is null || input.Equals("quit", StringComparison.OrdinalIgnoreCase))
        break;

    if (string.IsNullOrWhiteSpace(input))
        continue;

    switch (input.Trim().ToLowerInvariant())
    {
        case "/save":
            JsonElement snapshot = await agent.SerializeSessionAsync(session);
            await File.WriteAllTextAsync(sessionPath + ".tmp", snapshot.GetRawText());
            File.Move(sessionPath + ".tmp", sessionPath, overwrite: true);
            Console.WriteLine($"Saved session to {sessionPath}");
            continue;
        case "/load":
            if (!File.Exists(sessionPath))
            {
                Console.WriteLine("No saved session exists. Use /save first.");
                continue;
            }

            using (JsonDocument snapshotFile = JsonDocument.Parse(await File.ReadAllTextAsync(sessionPath)))
            {
                session = await agent.DeserializeSessionAsync(snapshotFile.RootElement);
            }
            Console.WriteLine("Loaded the saved session, replacing the current conversation.");
            PrintHistory(session);
            continue;
        case "/new":
            session = await agent.CreateSessionAsync();
            Console.WriteLine("Started an empty session. The saved file is unchanged.");
            continue;
        case "/history":
            PrintHistory(session);
            continue;
    }

    var response = await agent.RunAsync(input, session);
    if (string.IsNullOrWhiteSpace(response.Text))
        throw new InvalidOperationException("The agent returned an empty answer.");

    Console.WriteLine($"[ASSISTANT]: {response.Text}");
}

static void PrintHistory(AgentSession session)
{
    if (!session.TryGetInMemoryChatHistory(out var messages))
    {
        Console.WriteLine("Stored messages: 0 (history has not been initialized yet).");
        return;
    }

    Console.WriteLine($"Stored messages: {messages.Count}");
    foreach (var message in messages)
        Console.WriteLine($"  [{message.Role}]: {message.Text}");
}
