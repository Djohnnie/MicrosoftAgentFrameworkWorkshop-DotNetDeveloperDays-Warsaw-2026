using Azure.AI.Extensions.OpenAI;
using Azure.AI.Projects;
using Azure.Identity;
using OpenAI;
using OpenAI.Responses;

#pragma warning disable OPENAI001

var endpoint = Environment.GetEnvironmentVariable("FOUNDRY_ENDPOINT")
    ?? throw new InvalidOperationException("Set FOUNDRY_ENDPOINT to your Foundry project endpoint");
const string agentName = "developerdays";
const string userMessage = "Hi developerdays";

// Foundry agent endpoints require Microsoft Entra ID, not an API key.
AIProjectClient projectClient = new(
    endpoint: new Uri(endpoint),
    tokenProvider: new DefaultAzureCredential());

ProjectResponsesClient agentClient =
    projectClient.ProjectOpenAIClient.GetProjectResponsesClientForAgentEndpoint(agentName);

ProjectConversationsClient conversationClient = new(
    agentClient.Pipeline,
    new OpenAIClientOptions { Endpoint = agentClient.Endpoint });
ProjectConversation conversation = await conversationClient.CreateProjectConversationAsync();

ProjectResponsesClient responseClient =
    projectClient.ProjectOpenAIClient.GetProjectResponsesClientForAgentEndpoint(
        agentName, defaultConversationId: conversation.Id);

Console.WriteLine($"[USER]: {userMessage}");
ResponseResult response = await responseClient.CreateResponseAsync(userMessage);
Console.WriteLine($"[ASSISTANT]: {response.GetOutputText()}");
