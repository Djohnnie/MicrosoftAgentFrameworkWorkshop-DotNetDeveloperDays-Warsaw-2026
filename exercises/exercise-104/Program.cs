using System.ClientModel;
using System.Text.Json;
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

Console.WriteLine("Generate a fictional employee with structured output. Type 'quit' to exit.");

while (true)
{
    Console.Write("[USER]: ");
    var input = Console.ReadLine();
    if (input is null || input.Equals("quit", StringComparison.OrdinalIgnoreCase))
        break;

    if (string.IsNullOrWhiteSpace(input))
        continue;

    var response = await chatClient.GetResponseAsync<Employee>(
        $"Generate one fictional adult employee based on this request: {input}. " +
        "Name is the family name. Salary is the annual gross salary in EUR.",
        useJsonSchemaResponseFormat: true);

    Employee employee = response.Result;
    Console.WriteLine($"[ASSISTANT]: {JsonSerializer.Serialize(employee, new JsonSerializerOptions { WriteIndented = true })}");
}