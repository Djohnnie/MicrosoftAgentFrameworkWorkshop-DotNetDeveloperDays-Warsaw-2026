using Microsoft.Agents.AI;
using Microsoft.Agents.AI.Workflows;

public static class PlanningWorkflow
{
    // Each executor returns a PlanState message; workflow edges deliver it to the next matching stage.
    public static Workflow Build(
        AIAgent picker, AIAgent scheduler, AIAgent reviewer,
        Func<DateOnly, CancellationToken, Task<SessionOption[]>> loadSessions)
    {
        // TODO: Create the three executors and a final identity executor.
        // Start with Picker -> Builder -> Reviewer -> FinalPlan.
        // Then use conditional edges:
        // - no candidates: Picker -> FinalPlan
        // - candidates: Picker -> Builder
        // - ShouldRevise: Reviewer -> Builder
        // - otherwise: Reviewer -> FinalPlan
        // Register only FinalPlan with WithOutputFrom.
        // Paired conditions must be mutually exclusive to avoid running both routes.
        throw new NotImplementedException("Build the workflow graph.");
    }
}

public sealed class SessionPicker(
    AIAgent agent, Func<DateOnly, CancellationToken, Task<SessionOption[]>> loadSessions)
    : Executor<PlanState, PlanState>("SessionPicker")
{
    public override async ValueTask<PlanState> HandleAsync(
        PlanState state, IWorkflowContext context, CancellationToken cancellationToken = default)
    {
        // TODO: Load the requested day through MCP and validate its dates, times and unique IDs.
        // Filter sessions to the time window. If none fit, return an explicit no-match state.
        // Call PlanningAgents.AskAsync<CandidateSelection> with Request and eligible sessions.
        // Reject invented/duplicate candidate IDs or missing reasons.
        // Return state with Catalog, Candidates and meaningful Review feedback.
        await Task.CompletedTask;
        _ = agent;
        _ = loadSessions;
        throw new NotImplementedException("Pick relevant sessions.");
    }
}

public sealed class ScheduleBuilder(AIAgent agent) : Executor<PlanState, PlanState>("ScheduleBuilder")
{
    public override async ValueTask<PlanState> HandleAsync(
        PlanState state, IWorkflowContext context, CancellationToken cancellationToken = default)
    {
        // TODO: Pass Request, actual candidate sessions/reasons, PreviousDraft,
        // ValidationErrors and ReviewerFeedback to AskAsync<ScheduleDraft>.
        // Return state with the new Draft and DraftNumber incremented.
        // Even an empty draft consumes an attempt; revisions use state, not a reused AgentSession.
        await Task.CompletedTask;
        _ = agent;
        throw new NotImplementedException("Build or revise the schedule.");
    }
}

public sealed class PlanReviewer(AIAgent agent) : Executor<PlanState, PlanState>("PlanReviewer")
{
    public override async ValueTask<PlanState> HandleAsync(
        PlanState state, IWorkflowContext context, CancellationToken cancellationToken = default)
    {
        // TODO: Run PlanRules.Validate before asking the reviewer agent.
        // Pass Request, Catalog, Candidates, Draft and ValidationErrors to AskAsync<PlanReview>.
        // Return state with Errors and Review. PlanState.Accepted requires BOTH
        // C# validation success and model approval; ShouldRevise caps the loop.
        await Task.CompletedTask;
        _ = agent;
        throw new NotImplementedException("Review the draft.");
    }
}
