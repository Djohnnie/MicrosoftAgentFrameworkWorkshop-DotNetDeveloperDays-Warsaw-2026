using Azure.AI.Extensions.OpenAI;
using Azure.AI.Projects;
using Azure.Identity;
using Microsoft.Agents.AI;
using Microsoft.Agents.AI.Foundry;

var tenantId = Environment.GetEnvironmentVariable("TENANT_ID")
    ?? throw new InvalidOperationException("Set TENANT_ID");
var clientId = Environment.GetEnvironmentVariable("CLIENT_ID")
    ?? throw new InvalidOperationException("Set CLIENT_ID");
var clientSecret = Environment.GetEnvironmentVariable("CLIENT_SECRET")
    ?? throw new InvalidOperationException("Set CLIENT_SECRET");
var endpoint = Environment.GetEnvironmentVariable("FOUNDRY_ENDPOINT")
    ?? throw new InvalidOperationException("Set FOUNDRY_ENDPOINT to your Foundry project endpoint");
var agentName = Environment.GetEnvironmentVariable("FOUNDRY_AGENT_NAME")
    ?? throw new InvalidOperationException("Set FOUNDRY_AGENT_NAME to your Foundry prompt agent's name");
var agentVersion = Environment.GetEnvironmentVariable("FOUNDRY_AGENT_VERSION")
    ?? throw new InvalidOperationException("Set FOUNDRY_AGENT_VERSION to an existing agent version");

var credential = new ClientSecretCredential(tenantId, clientId, clientSecret);
var projectClient = new AIProjectClient(new Uri(endpoint), credential);
FoundryAgent agent = projectClient.AsAIAgent(new AgentReference(agentName, agentVersion));
ChatClientAgentSession session = await agent.CreateConversationSessionAsync();

Console.WriteLine("Foundry prompt agent. Type 'quit' to exit.");

Console.WriteLine($"Conversation: {session.ConversationId}");

while (true)
{
    Console.Write("[USER]: ");
    var input = Console.ReadLine();
    if (input is null || input.Equals("quit", StringComparison.OrdinalIgnoreCase))
        break;

    if (string.IsNullOrWhiteSpace(input))
        continue;

    var response = await agent.RunAsync(input, session);
    foreach (var message in response.Messages)
    {
        if (!string.IsNullOrWhiteSpace(message.Text))
            Console.WriteLine($"[ASSISTANT]: {message.Text}");
    }
}
