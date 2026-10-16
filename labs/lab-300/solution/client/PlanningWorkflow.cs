using Microsoft.Agents.AI;
using Microsoft.Agents.AI.Workflows;

public static class PlanningWorkflow
{
    public static Workflow Build(
        AIAgent picker, AIAgent scheduler, AIAgent reviewer,
        Func<DateOnly, CancellationToken, Task<SessionOption[]>> loadSessions)
    {
        var pick = new SessionPicker(picker, loadSessions);
        var schedule = new ScheduleBuilder(scheduler);
        var review = new PlanReviewer(reviewer);
        // This terminal executor returns the state unchanged; final output needs no extra model call.
        Func<PlanState, PlanState> finish = state => state;
        var output = finish.BindAsExecutor("FinalPlan");

        // Each pair of conditional edges is mutually exclusive: only one route receives the state.
        // The graph, not a coordinating agent or a manual retry loop, decides what runs next.
        return new WorkflowBuilder(pick)
            .AddEdge<PlanState>(pick, schedule, state => state is not null && state.Candidates.Length > 0)
            .AddEdge<PlanState>(pick, output, state => state is not null && state.Candidates.Length == 0)
            .AddEdge(schedule, review)
            // Rejection loops back with feedback until acceptance or the three-draft limit.
            .AddEdge<PlanState>(review, schedule, state => state is not null && state.ShouldRevise)
            .AddEdge<PlanState>(review, output, state => state is not null && !state.ShouldRevise)
            // Intermediate executor events remain visible, but only FinalPlan is a workflow output.
            .WithOutputFrom(output)
            .Build();
    }
}

// Returning PlanState from HandleAsync sends it along matching edges; no explicit SendMessageAsync is needed.
public sealed class SessionPicker(
    AIAgent agent, Func<DateOnly, CancellationToken, Task<SessionOption[]>> loadSessions)
    : Executor<PlanState, PlanState>("SessionPicker")
{
    public override async ValueTask<PlanState> HandleAsync(
        PlanState state, IWorkflowContext context, CancellationToken cancellationToken = default)
    {
        if (state.Request.Until <= state.Request.From || string.IsNullOrWhiteSpace(state.Request.Interests))
            throw new InvalidOperationException("Supply interests and a same-day time window with From before Until.");

        // The delegate retrieves one day through MCP; checks can substitute a small local catalog.
        SessionOption[] catalog = await loadSessions(state.Request.Date, cancellationToken);
        if (catalog.Any(item => item.Date != state.Request.Date || item.End <= item.Start)
            || catalog.Select(item => item.Id).Distinct(StringComparer.Ordinal).Count() != catalog.Length)
            throw new InvalidOperationException("The MCP server returned inconsistent session dates, times or IDs.");

        // Code enforces availability before the model judges relevance. No eligible slots means no inference.
        SessionOption[] eligible = catalog
            .Where(item => item.Start >= state.Request.From && item.End <= state.Request.Until).ToArray();
        if (eligible.Length == 0)
            return state with { Catalog = catalog, Review = new(false, "No agenda sessions fit this date/time window.") };

        // Overlapping alternatives are allowed here; selecting a conflict-free subset is the builder's job.
        CandidateSelection selection = await PlanningAgents.AskAsync<CandidateSelection>(
            agent, new { state.Request, Sessions = eligible }, cancellationToken);
        // A valid JSON shape does not prove that IDs or recommendation reasons are valid.
        if (selection.Sessions is null || selection.Sessions.Any(choice =>
                choice is null || string.IsNullOrWhiteSpace(choice.Reason)
                || !eligible.Any(item => item.Id == choice.SessionId))
            || selection.Sessions.Select(item => item.SessionId).Distinct(StringComparer.Ordinal).Count()
                != selection.Sessions.Length)
            throw new InvalidOperationException("Session Picker returned invalid or duplicate candidate IDs/reasons.");

        // Preserve canonical agenda data alongside model choices for later validation and display.
        return state with
        {
            Catalog = catalog,
            Candidates = selection.Sessions,
            Review = new(false, selection.Sessions.Length == 0
                ? "No sessions matched these interests. Try broader interests." : "Candidates selected.")
        };
    }
}

public sealed class ScheduleBuilder(AIAgent agent) : Executor<PlanState, PlanState>("ScheduleBuilder")
{
    public override async ValueTask<PlanState> HandleAsync(
        PlanState state, IWorkflowContext context, CancellationToken cancellationToken = default)
    {
        // Revisions use explicit inputs, not hidden conversation history from an earlier invocation.
        ScheduleDraft draft = await PlanningAgents.AskAsync<ScheduleDraft>(agent, new
        {
            state.Request,
            Candidates = state.Candidates.Select(choice => new
            {
                Session = state.Catalog.Single(item => item.Id == choice.SessionId),
                choice.Reason
            }),
            PreviousDraft = state.Draft,
            ValidationErrors = state.Errors,
            ReviewerFeedback = state.Review.Feedback
        }, cancellationToken);
        if (draft.Sessions is null || draft.Sessions.Any(item => item is null))
            throw new InvalidOperationException("Schedule Builder returned a malformed session list.");

        return state with
        {
            Draft = draft.Sessions,
            // Empty or invalid drafts still consume an attempt, so they cannot cause an endless cycle.
            DraftNumber = state.DraftNumber + 1
        };
    }
}

public sealed class PlanReviewer(AIAgent agent) : Executor<PlanState, PlanState>("PlanReviewer")
{
    public override async ValueTask<PlanState> HandleAsync(
        PlanState state, IWorkflowContext context, CancellationToken cancellationToken = default)
    {
        // C# checks facts and constraints; the reviewer adds a judgment about usefulness and relevance.
        string[] errors = PlanRules.Validate(state);
        PlanReview review = await PlanningAgents.AskAsync<PlanReview>(agent, new
        {
            state.Request,
            state.Catalog,
            state.Candidates,
            state.Draft,
            ValidationErrors = errors
        }, cancellationToken);
        if (string.IsNullOrWhiteSpace(review.Feedback))
            throw new InvalidOperationException("Plan Reviewer returned no feedback.");

        // Keep both verdicts: model approval alone cannot make PlanState.Accepted true.
        return state with { Errors = errors, Review = review };
    }
}
