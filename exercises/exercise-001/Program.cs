using System.ClientModel;
using Microsoft.ML.Tokenizers;
using OpenAI;
using OpenAI.Responses;

#pragma warning disable OPENAI001

TokenVisualizerUi.ShowBanner();

var endpoint = Environment.GetEnvironmentVariable("FOUNDRY_ENDPOINT");
var key = Environment.GetEnvironmentVariable("FOUNDRY_API_KEY");
var model = Environment.GetEnvironmentVariable("FOUNDRY_MODEL_DEPLOYMENT");

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

ResponsesClient client = new(
    model: model,
    credential: new ApiKeyCredential(key),
    options: new OpenAIClientOptions { Endpoint = endpointUri });

// GPT-4.1 and GPT-4o use the o200k_base tokenizer.
var tokenizer = TiktokenTokenizer.CreateForModel("gpt-4.1");
const string instructions = "You are a helpful assistant. Give clear, concise answers.";
var history = new List<(string Text, ResponseItem Item)>
{
    (instructions, ResponseItem.CreateSystemMessageItem(instructions))
};

TokenVisualizerUi.ShowChatInstructions();

while (true)
{
    var input = TokenVisualizerUi.ReadInput();
    if (input.Equals("quit", StringComparison.OrdinalIgnoreCase))
        break;

    if (input.Equals("clear", StringComparison.OrdinalIgnoreCase))
    {
        history.RemoveRange(1, history.Count - 1);
        TokenVisualizerUi.ShowHistoryCleared();
        continue;
    }

    if (string.IsNullOrWhiteSpace(input))
        continue;

    TokenVisualizerUi.ShowInputTokens(tokenizer.EncodeToTokens(input, out _));
    var localMessageCount = tokenizer.CountTokens(input);
    history.Add((input, ResponseItem.CreateUserMessageItem(input)));
    var localHistoryCount = CountHistoryTokens(tokenizer, history);

    CreateResponseOptions options = new();
    foreach (var message in history)
        options.InputItems.Add(message.Item);

    ResponseResult response;
    try
    {
        response = await TokenVisualizerUi.WaitForResponseAsync(async () => await client.CreateResponseAsync(options));
    }
    catch (ClientResultException exception)
    {
        history.RemoveAt(history.Count - 1);
        TokenVisualizerUi.ShowError($"Foundry request failed (HTTP {exception.Status}): {exception.Message}");
        continue;
    }

    var responseText = response.GetOutputText();
    history.Add((responseText, ResponseItem.CreateAssistantMessageItem(responseText)));
    TokenVisualizerUi.ShowResponse(responseText, tokenizer.EncodeToTokens(responseText, out _));
    TokenVisualizerUi.ShowComparison(
        localMessageCount, localHistoryCount, tokenizer.CountTokens(responseText), response.Usage);
}

TokenVisualizerUi.ShowGoodbye();

static int CountHistoryTokens(TiktokenTokenizer tokenizer, IList<(string Text, ResponseItem Item)> history)
{
    // Approximate chat framing; Responses API usage is the authoritative count.
    const int overheadPerMessage = 3;
    const int replyPrimer = 3;
    return history.Sum(message => tokenizer.CountTokens(message.Text))
        + history.Count * overheadPerMessage + replyPrimer;
}
