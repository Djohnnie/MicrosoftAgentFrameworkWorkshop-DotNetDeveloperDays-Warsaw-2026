using Microsoft.Agents.AI;
using Microsoft.Agents.AI.Workflows;

public sealed class PitchAgentExecutor(AIAgent agent) : Executor<string, string>("Founder")
{
    public override async ValueTask<string> HandleAsync(
        string message, IWorkflowContext context, CancellationToken cancellationToken = default)
    {
        AgentSession session = await agent.CreateSessionAsync(cancellationToken: cancellationToken);
        AgentResponse response = await agent.RunAsync(message, session, cancellationToken: cancellationToken);
        if (string.IsNullOrWhiteSpace(response.Text))
            throw new InvalidOperationException("The Founder returned an empty pitch.");
        return response.Text;
    }
}
