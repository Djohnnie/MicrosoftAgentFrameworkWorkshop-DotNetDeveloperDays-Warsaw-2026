using Microsoft.Agents.AI;
using Microsoft.Agents.AI.Workflows;

public sealed class PitchAgentExecutor(AIAgent agent, string id) : Executor<string, string>(id)
{
    public override async ValueTask<string> HandleAsync(
        string message, IWorkflowContext context, CancellationToken cancellationToken = default)
    {
        AgentSession session = await agent.CreateSessionAsync(cancellationToken: cancellationToken);
        AgentResponse response = await agent.RunAsync(message, session, cancellationToken: cancellationToken);
        if (string.IsNullOrWhiteSpace(response.Text))
            throw new InvalidOperationException($"{agent.Name} returned an empty response.");
        return response.Text;
    }
}
