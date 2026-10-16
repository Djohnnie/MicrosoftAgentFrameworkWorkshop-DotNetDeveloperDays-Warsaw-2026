public sealed record PlanRequest(DateOnly Date, TimeOnly From, TimeOnly Until, string Interests);

// Canonical session facts come from MCP. Agents return references to these records, not replacement facts.
public sealed record SessionOption(
    string Id, DateOnly Date, TimeOnly Start, TimeOnly End,
    string Room, string Title, string? Description, string[] Speakers);

// These DTOs form the agents' JSON-schema contracts: relevance choices, a draft, and a review verdict.
public sealed record SessionChoice(string SessionId, string Reason);
public sealed record CandidateSelection(SessionChoice[] Sessions);
public sealed record ScheduleDraft(SessionChoice[] Sessions);
public sealed record PlanReview(bool Approved, string Feedback);

// The workflow message carries all handoff/revision context. Executors return updated copies with "with".
public sealed record PlanState(PlanRequest Request)
{
    public SessionOption[] Catalog { get; init; } = [];
    public SessionChoice[] Candidates { get; init; } = [];
    public SessionChoice[] Draft { get; init; } = [];
    public string[] Errors { get; init; } = [];
    public PlanReview Review { get; init; } = new(false, "Not reviewed.");
    public int DraftNumber { get; init; }

    // Both deterministic validation and model review must succeed; neither replaces the other.
    public bool Accepted => Draft.Length > 0 && Errors.Length == 0 && Review.Approved;
    // Drafts 1, 2 and 3 mean one initial attempt plus at most two revisions.
    public bool ShouldRevise => Candidates.Length > 0 && !Accepted && DraftNumber < 3;
}
