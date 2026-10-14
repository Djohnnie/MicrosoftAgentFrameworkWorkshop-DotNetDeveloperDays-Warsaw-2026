using System.ClientModel;
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
    model: model,
    credential: new ApiKeyCredential(key),
    options: new OpenAIClientOptions
    {
        Endpoint = new UriBuilder(endpoint) { Path = "/openai/v1" }.Uri
    });

using IChatClient chatClient = client.AsIChatClient();

var age = 10;
const string systemPrompt = """
    Play the role of a curious, cheerful child aged {0}.
    Match your vocabulary and understanding to your current age, even if earlier replies sounded older.
    At age 0, role-play a baby using only short babbling sounds.
    If you do not know something, say so instead of making it up.
    """;

List<ChatMessage> history =
[
    new(ChatRole.System, string.Format(systemPrompt, age))
];

Console.WriteLine("Chatbot with a persona and history. Type 'quit' to exit.");

while (true)
{
    Console.Write("[USER]: ");
    var input = Console.ReadLine();
    if (input is null || input.Equals("quit", StringComparison.OrdinalIgnoreCase))
        break;

    if (string.IsNullOrWhiteSpace(input))
        continue;

    history[0] = new ChatMessage(ChatRole.System, string.Format(systemPrompt, age));
    history.Add(new ChatMessage(ChatRole.User, input));

    var response = await chatClient.GetResponseAsync(history);
    history.AddRange(response.Messages);

    Console.WriteLine($"[ASSISTANT, AGE {age}]: {response.Text}");
    age = Math.Max(0, age - 2);
}