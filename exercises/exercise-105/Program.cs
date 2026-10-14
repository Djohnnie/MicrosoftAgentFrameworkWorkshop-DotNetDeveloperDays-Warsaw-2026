using Microsoft.Extensions.AI;
using OllamaSharp;

using IChatClient chatClient = new OllamaApiClient(
    new Uri("http://localhost:11434"), "qwen2.5:7b");

List<ChatMessage> history = [];

Console.WriteLine("Local Ollama chatbot with history. Type 'quit' to exit.");

while (true)
{
    Console.Write("[USER]: ");
    var input = Console.ReadLine();
    if (input is null || input.Equals("quit", StringComparison.OrdinalIgnoreCase))
        break;

    if (string.IsNullOrWhiteSpace(input))
        continue;

    history.Add(new ChatMessage(ChatRole.User, input));

    var response = await chatClient.GetResponseAsync(history);
    history.AddRange(response.Messages);

    Console.WriteLine($"[ASSISTANT]: {response.Text}");
}