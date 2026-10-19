using System.ClientModel;
using System.Text.Json;
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

ResponsesClient client = new(new ApiKeyCredential(key), new ResponsesClientOptions
{
    Endpoint = new UriBuilder(endpoint) { Path = "/openai/v1" }.Uri
});
using IChatClient chatClient = client.AsIChatClient(model);

AIFunction getCurrentTime = new ApprovalRequiredAIFunction(
    AIFunctionFactory.Create(DateTimeTools.GetCurrentTime));
AIFunction getCurrentDate = new ApprovalRequiredAIFunction(
    AIFunctionFactory.Create(DateTimeTools.GetCurrentDate));

AIAgent agent = chatClient.AsAIAgent(new ChatClientAgentOptions
{
    ChatHistoryProvider = new InMemoryChatHistoryProvider(),
    ChatOptions = new ChatOptions
    {
        Instructions = """
            Use the tools to answer questions about the current local date or time.
            If approval is denied, explain that the requested clock tool was not run; do not invent its result.
            Do not retry a denied call unless the user explicitly asks again.
            """,
        Tools = [getCurrentTime, getCurrentDate],
        RawRepresentationFactory = _ => new CreateResponseOptions { StoredOutputEnabled = false }
    }
});
AgentSession session = await agent.CreateSessionAsync();

Console.WriteLine("Chatbot agent with tool approval. Ask for the current date or time.");
Console.WriteLine("Each clock tool requires approval. Type 'quit' to exit.");

while (true)
{
    Console.Write("[USER]: ");
    string? input = Console.ReadLine();
    if (input is null || input.Equals("quit", StringComparison.OrdinalIgnoreCase))
        break;
    if (string.IsNullOrWhiteSpace(input))
        continue;

    AgentResponse response = await agent.RunAsync(input, session);
    while (true)
    {
        var requests = response.Messages
            .SelectMany(message => message.Contents)
            .OfType<ToolApprovalRequestContent>()
            .ToArray();
        if (requests.Length == 0)
            break;

        List<AIContent> decisions = [];
        foreach (ToolApprovalRequestContent request in requests)
        {
            if (request.ToolCall is not FunctionCallContent call)
                throw new InvalidOperationException("Expected a function call requiring approval.");

            Console.WriteLine($"[APPROVAL]: Tool: {call.Name}; CallId: {call.CallId}");
            Console.WriteLine($"Arguments: {JsonSerializer.Serialize(call.Arguments)}");
            bool? approved = ReadApproval();
            if (approved is null)
            {
                Console.WriteLine("[APPROVAL]: Exiting without executing the pending batch.");
                return;
            }
            decisions.Add(request.CreateResponse(approved.Value));
        }

        // Resume using correlated decisions, not a plain-text "yes" sent to the model.
        response = await agent.RunAsync(new ChatMessage(ChatRole.User, decisions), session);
    }

    if (string.IsNullOrWhiteSpace(response.Text))
        throw new InvalidOperationException("The agent returned no answer or approval request.");
    Console.WriteLine($"[ASSISTANT]: {response.Text}");
}

static bool? ReadApproval()
{
    while (true)
    {
        Console.Write("[APPROVAL]: Approve? yes/no (Enter = no, quit = exit): ");
        string? input = Console.ReadLine()?.Trim();
        if (input is null || input.Equals("quit", StringComparison.OrdinalIgnoreCase))
            return null;
        if (input.Equals("yes", StringComparison.OrdinalIgnoreCase))
            return true;
        if (input.Length == 0 || input.Equals("no", StringComparison.OrdinalIgnoreCase))
            return false;
        Console.WriteLine("[APPROVAL]: Enter 'yes' or 'no'; no decision has been submitted.");
    }
}
