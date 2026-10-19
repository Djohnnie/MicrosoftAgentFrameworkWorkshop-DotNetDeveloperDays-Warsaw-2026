using Microsoft.Agents.AI;
using Microsoft.Agents.AI.Workflows;

public sealed record InvestorReview(string Investor, string Text);

public sealed class InvestorExecutor(AIAgent agent, string id) : Executor<string, InvestorReview>(id)
{
    public override async ValueTask<InvestorReview> HandleAsync(
        string pitch, IWorkflowContext context, CancellationToken cancellationToken = default)
    {
        AgentSession session = await agent.CreateSessionAsync(cancellationToken: cancellationToken);
        AgentResponse response = await agent.RunAsync(pitch, session, cancellationToken: cancellationToken);
        if (string.IsNullOrWhiteSpace(response.Text))
            throw new InvalidOperationException($"{Id} returned an empty review.");
        return new InvestorReview(Id, response.Text);
    }
}
