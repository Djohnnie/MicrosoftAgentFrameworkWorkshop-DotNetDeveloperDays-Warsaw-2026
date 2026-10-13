using System.ClientModel;
using Microsoft.Extensions.AI;
using Microsoft.ML.Tokenizers;
using OpenAI.Responses;

TokenVisualizerUi.ShowBanner();

var endpoint = Environment.GetEnvironmentVariable("OPENAI_ENDPOINT");
var key = Environment.GetEnvironmentVariable("OPENAI_KEY");
var model = Environment.GetEnvironmentVariable("OPENAI_MODEL");

if (string.IsNullOrWhiteSpace(endpoint) || string.IsNullOrWhiteSpace(key) || string.IsNullOrWhiteSpace(model))
{
    TokenVisualizerUi.ShowMissingConfiguration();
    Environment.ExitCode = 1;
    return;
}

Uri endpointUri;
try
{
    endpointUri = FoundryEndpoint.Resolve(endpoint);
}
catch (ArgumentException exception)
{
    TokenVisualizerUi.ShowError(exception.Message);
    Environment.ExitCode = 1;
    return;
}

#pragma warning disable OPENAI001
ResponsesClient responsesClient = new(
    credential: new ApiKeyCredential(key),
    options: new ResponsesClientOptions { Endpoint = endpointUri });
using IChatClient chatClient = responsesClient.AsIChatClient(model);
#pragma warning restore OPENAI001

// GPT-4.1 and GPT-4o use the o200k_base tokenizer.
var tokenizer = TiktokenTokenizer.CreateForModel("gpt-4.1");
var history = new List<ChatMessage>
{
    new(ChatRole.System, "You are a helpful assistant. Give clear, concise answers.")
};

TokenVisualizerUi.ShowChatInstructions();

while (true)
{
    var input = TokenVisualizerUi.ReadInput();
    if (input.Equals("quit", StringComparison.OrdinalIgnoreCase))
        break;

    if (input.Equals("clear", StringComparison.OrdinalIgnoreCase))
    {
        history.RemoveAll(message => message.Role != ChatRole.System);
        TokenVisualizerUi.ShowHistoryCleared();
        continue;
    }

    if (string.IsNullOrWhiteSpace(input))
        continue;

    TokenVisualizerUi.ShowInputTokens(tokenizer.EncodeToTokens(input, out _));
    var localMessageCount = tokenizer.CountTokens(input);
    history.Add(new ChatMessage(ChatRole.User, input));
    var localHistoryCount = CountHistoryTokens(tokenizer, history);

    ChatResponse response;
    try
    {
        response = await TokenVisualizerUi.WaitForResponseAsync(() => chatClient.GetResponseAsync(history));
    }
    catch (ClientResultException exception)
    {
        history.RemoveAt(history.Count - 1);
        TokenVisualizerUi.ShowError($"Foundry request failed (HTTP {exception.Status}): {exception.Message}");
        continue;
    }

    var responseText = response.Text;
    history.Add(new ChatMessage(ChatRole.Assistant, responseText));
    TokenVisualizerUi.ShowResponse(responseText, tokenizer.EncodeToTokens(responseText, out _));
    TokenVisualizerUi.ShowComparison(
        localMessageCount, localHistoryCount, tokenizer.CountTokens(responseText), response.Usage);
}

TokenVisualizerUi.ShowGoodbye();

static int CountHistoryTokens(TiktokenTokenizer tokenizer, IList<ChatMessage> history)
{
    // Approximate chat framing; Responses API usage is the authoritative count.
    const int overheadPerMessage = 3;
    const int replyPrimer = 3;
    return history.Sum(message => tokenizer.CountTokens(message.Text ?? string.Empty))
        + history.Count * overheadPerMessage + replyPrimer;
}
