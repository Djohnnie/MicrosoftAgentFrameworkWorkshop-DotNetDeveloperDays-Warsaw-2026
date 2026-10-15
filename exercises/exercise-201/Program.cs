using System.ClientModel;
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

using IChatClient chatClient = client.AsIChatClient(model)
    .AsBuilder()
    .UseFunctionInvocation()
    .Build();

var getCurrentTime = AIFunctionFactory.Create(DateTimeTools.GetCurrentTime);
var getCurrentDate = AIFunctionFactory.Create(DateTimeTools.GetCurrentDate);
AIAgent agent = chatClient.AsAIAgent(new ChatClientAgentOptions
{
    ChatHistoryProvider = new InMemoryChatHistoryProvider(),
    ChatOptions = new ChatOptions
    {
        Tools = [getCurrentTime, getCurrentDate],
        RawRepresentationFactory = _ => new CreateResponseOptions
        {
            StoredOutputEnabled = false
        }
    }
});
AgentSession session = await agent.CreateSessionAsync();

Console.WriteLine("Chatbot agent with tools. Ask for the current date or time, or type 'quit' to exit.");

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
                    Console.WriteLine(
                        $"  {i + 1}. [FunctionCallContent] CallId: {functionCall.CallId}, Name: {functionCall.Name}");
                    break;
                case FunctionResultContent functionResult:
                    Console.WriteLine(
                        $"  {i + 1}. [FunctionResultContent] CallId: {functionResult.CallId}, Result: {functionResult.Result}");
                    break;
                default:
                    Console.WriteLine($"  {i + 1}. [{message.Role}]: {content}");
                    break;
            }
        }
    }

    Console.WriteLine("--- END HISTORY ---\n");
}