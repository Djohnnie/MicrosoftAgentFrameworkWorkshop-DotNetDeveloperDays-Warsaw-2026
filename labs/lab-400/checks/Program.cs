using System.Text.Json;
using Microsoft.Agents.AI;
using Microsoft.Agents.AI.Workflows;
using Microsoft.Extensions.AI;

// A/B overlap while A/C are adjacent, making both scheduling outcomes deterministic without Foundry.
var date = new DateOnly(2026, 10, 20);
SessionOption[] catalog =
[
    new("a", date, new(9, 0), new(10, 0), "Room 1", "AI", "AI introduction", ["Speaker A"]),
    new("b", date, new(9, 30), new(10, 30), "Room 2", "Security", "Security introduction", ["Speaker B"]),
    new("c", date, new(10, 0), new(11, 0), "Room 1", ".NET", ".NET introduction", ["Speaker C"])
];
var request = new PlanRequest(date, new(9, 0), new(12, 0), "AI and .NET");
SessionChoice a = new("a", "Learn AI");
SessionChoice b = new("b", "Learn security");
SessionChoice c = new("c", "Learn .NET");
var candidates = new CandidateSelection([a, b, c]);
var approve = new PlanReview(true, "Useful plan.");
var reject = new PlanReview(false, "Prefer the .NET session: revision-marker.");
int passed = 0;

var first = await ExecuteAsync(request, catalog, candidates, new ScheduleDraft([a, c]), approve);
Check(first.State.Accepted && first.State.DraftNumber == 1, "First-draft approval");
Check(first.Steps.SequenceEqual(["SessionPicker", "ScheduleBuilder", "PlanReviewer", "FinalPlan"]),
    "Sequential typed executor handoffs and one final output");

var revised = await ExecuteAsync(request, catalog, candidates,
    new ScheduleDraft([a]), reject, new ScheduleDraft([a, c]), approve);
Check(revised.State.Accepted && revised.State.DraftNumber == 2, "Reviewer-driven revision");
Check(revised.Prompts[3].Contains("revision-marker", StringComparison.Ordinal),
    "Reviewer feedback reaches the next builder call");

var overlap = await ExecuteAsync(request, catalog, candidates,
    new ScheduleDraft([a, b]), approve, new ScheduleDraft([a, c]), approve);
Check(overlap.State.Accepted && overlap.State.DraftNumber == 2,
    "C# rejects overlap even if the model approves it");
Check(overlap.Prompts[3].Contains("Overlap:", StringComparison.Ordinal),
    "C# validation errors reach the next builder call");

var exhausted = await ExecuteAsync(request, catalog, candidates,
    new ScheduleDraft([a]), reject, new ScheduleDraft([a]), reject, new ScheduleDraft([a]), reject);
Check(!exhausted.State.Accepted && exhausted.State.DraftNumber == 3 && !exhausted.State.ShouldRevise,
    "Exactly two revisions, with explicit unapproved final output");
Check(exhausted.Steps.Count(step => step == "PlanReviewer") == 3, "Bounded graph cycle");

var emptyDraft = await ExecuteAsync(request, catalog, candidates,
    new ScheduleDraft([]), approve, new ScheduleDraft([]), approve, new ScheduleDraft([]), approve);
Check(!emptyDraft.State.Accepted && emptyDraft.State.DraftNumber == 3, "Empty drafts cannot bypass the cap");

var noMatch = await ExecuteAsync(request, catalog, new CandidateSelection([]));
Check(!noMatch.State.Accepted && noMatch.Steps.SequenceEqual(["SessionPicker", "FinalPlan"]),
    "No matches bypass scheduling and review");
var noDate = await ExecuteAsync(request, []);
Check(!noDate.State.Accepted && noDate.Prompts.Length == 0, "Empty agenda skips all model calls");
var noWindow = await ExecuteAsync(request with { From = new(17, 0), Until = new(18, 0) }, catalog);
Check(!noWindow.State.Accepted && noWindow.Prompts.Length == 0, "Unavailable time window skips model calls");

PlanState valid = new(request)
{
    Catalog = catalog, Candidates = candidates.Sessions, Draft = [a, c], Review = approve, DraftNumber = 1
};
Check(PlanRules.Validate(valid).Length == 0, "Adjacent sessions do not overlap");
Check(PlanRules.Validate(valid with { Draft = [a, a] }).Any(error => error.StartsWith("Duplicate")),
    "Duplicate IDs rejected");
Check(PlanRules.Validate(valid with { Draft = [new("invented", "Fake")] })
    .Any(error => error.StartsWith("Unknown")), "Invented session IDs rejected");
Check(PlanRules.Validate(valid with { Candidates = [a], Draft = [c] })
    .Any(error => error.StartsWith("Unknown")), "Non-candidate IDs rejected");
Check(PlanRules.Validate(valid with { Request = request with { Until = new(9, 45) } }).Length > 0,
    "Time window enforced");
Check(PlanRules.Validate(valid with { Request = request with { Date = date.AddDays(1) } }).Length > 0,
    "Date enforced");
Check(PlanRules.Validate(valid with { Draft = [new("a", "")] }).Length > 0, "Reasons required");

await CheckFailureAsync(() => ExecuteAsync(request, catalog,
    new CandidateSelection([new("invented", "Fake")])), "Invented picker candidates fail visibly");
await CheckFailureAsync(() => ExecuteAsync(request, catalog,
    new CandidateSelection([a, a])), "Duplicate picker candidates fail visibly");
await CheckFailureAsync(() => ExecuteAsync(request with { Until = new(8, 0) }, catalog),
    "Invalid request fails before inference");
await CheckFailureAsync(() => ExecuteAsync(request, [catalog[0], catalog[0]]),
    "Duplicate catalog IDs fail before inference");
await CheckFailureAsync(() => ExecuteAsync(request, catalog, "not-json"), "Malformed model JSON fails visibly");
await CheckFailureAsync(() => ExecuteAsync(request, catalog, candidates, new ScheduleDraft([a]),
    new PlanReview(true, "")), "Missing reviewer feedback fails visibly");

SessionOption[] actual = ConferenceAgenda.Load();
Check(actual.Length > 0 && actual.All(item => item.Start < item.End),
    "Embedded agenda has real sessions and intervals");
Check(actual.Select(item => item.Id).Distinct().Count() == actual.Length,
    "Canonical session IDs are unique");
Check(actual.All(item => item.Id == $"{item.Date:yyyy-MM-dd}|{item.Start:HH:mm}|{item.Room}"),
    "Canonical IDs match the hosted picker's documented contract");
Check(actual.All(item => item.Title != "Registration" && item.Title != "Lunch"),
    "Breaks are excluded");
SessionOption firstActual = actual.First(item => item.Date == date && item.Start >= request.From
    && item.End <= request.Until);
SessionChoice realChoice = new(firstActual.Id, "Real agenda session");
var integration = await ExecuteAsync(request, actual.Where(item => item.Date == date).ToArray(),
    new CandidateSelection([realChoice]), new ScheduleDraft([realChoice]), approve);
Check(integration.State.Accepted, "Real embedded data passes through the workflow");
Check(!integration.Prompts[0].Contains(firstActual.Title, StringComparison.Ordinal)
    && integration.Prompts[0].Contains(JsonSerializer.Serialize(request, JsonSerializerOptions.Web),
        StringComparison.Ordinal),
    "Hosted picker receives the request and output contract, not the local agenda");
Check(integration.Prompts[0].Contains("sessionId", StringComparison.Ordinal)
    && integration.Prompts[0].Contains("date + \"|\" + start + \"|\" + room", StringComparison.Ordinal),
    "Hosted picker prompt specifies the JSON property and canonical ID construction");
await CheckFailureAsync(() => ExecuteAsync(
    request with { Until = new(10, 0) }, catalog, new CandidateSelection([c])),
    "Hosted candidates outside availability fail visibly");
await CheckFailureAsync(() => ExecuteAsync(request, catalog,
    new CandidateSelection([new("a", "")])), "Missing hosted relevance reasons fail visibly");

await CheckFailureAsync(() => ExecuteAsync(request, catalog,
    new CandidateSelection([new("invented", "Fake")])), "Unknown candidate diagnostics identify the ID and date",
    "sessions[0].sessionId 'invented'", "2026-10-20", "Eligible session IDs: a, b, c");
await CheckFailureAsync(() => ExecuteAsync(request, catalog,
    new CandidateSelection([a, a])), "Duplicate candidate diagnostics identify the second occurrence",
    "sessions[1].sessionId 'a' is duplicated");
await CheckFailureAsync(() => ExecuteAsync(request with { Until = new(10, 0) }, catalog,
    new CandidateSelection([c])), "Availability diagnostics show actual and requested times",
    "runs 10:00-11:00", "requested 09:00-10:00");
await CheckFailureAsync(() => ExecuteAsync(request, catalog,
    """{"sessions":[{"id":"a","reason":"AI"}]}"""), "Wrong ID property has an actionable diagnostic",
    "sessions[0].sessionId is missing or blank");
await CheckFailureAsync(() => ExecuteAsync(request, catalog,
    """{"sessions":[{"sessionId":"a"}]}"""), "Missing reason identifies the JSON field",
    "sessions[0].reason is missing or blank");
await CheckFailureAsync(() => ExecuteAsync(request, catalog,
    """{"sessions":null}"""), "Null session list explains the response contract",
    "must contain a 'sessions' array");
await CheckFailureAsync(() => ExecuteAsync(request, catalog,
    """{"sessions":[null]}"""), "Null candidate identifies its array index",
    "sessions[0] is null");

Console.WriteLine($"Passed {passed} Lab 400 checks. No Foundry calls were made.");

void Check(bool condition, string name)
{
    if (!condition) throw new InvalidOperationException($"FAIL: {name}");
    passed++;
    Console.WriteLine($"PASS: {name}");
}

async Task CheckFailureAsync(Func<Task<Execution>> action, string name, params string[] expectedDetails)
{
    bool failed = false;
    try { await action(); }
    catch (Exception ex) when (ex is InvalidOperationException or JsonException)
    {
        string details = ex.ToString();
        failed = expectedDetails.All(expected => details.Contains(expected, StringComparison.Ordinal));
    }
    Check(failed, name);
}

static async Task<Execution> ExecuteAsync(PlanRequest request, SessionOption[] catalog, params object[] responses)
{
    using var client = new ScriptedChatClient(responses);
    AIAgent scheduler = PlanningAgents.Create<ScheduleDraft>(client, "ScheduleBuilder", "Build a schedule.");
    AIAgent reviewer = PlanningAgents.Create<PlanReview>(client, "PlanReviewer", "Review the schedule.");
    // Only the hosted transport is replaced; its prompt and JSON parsing still run.
    var workflow = PlanningWorkflow.Build(async (input, token) =>
        {
            ChatResponse response = await client.GetResponseAsync(
                [new ChatMessage(ChatRole.User, FoundrySessionPicker.CreatePrompt(input))],
                cancellationToken: token);
            return JsonSerializer.Deserialize<CandidateSelection>(response.Text, JsonSerializerOptions.Web)
                ?? throw new InvalidOperationException("Empty hosted response.");
        }, scheduler, reviewer,
        (_, _) => Task.FromResult(catalog));
    await using Run run = await InProcessExecution.RunAsync(workflow, new PlanState(request));
    // NewEvents drains events since its last access; capture once before making multiple assertions.
    WorkflowEvent[] events = run.NewEvents.ToArray();
    var failure = events.OfType<WorkflowErrorEvent>().FirstOrDefault();
    if (failure is not null)
        throw new InvalidOperationException("Workflow failed.", failure.Exception);
    PlanState result = events.OfType<WorkflowOutputEvent>().Select(evt => evt.Data).OfType<PlanState>().Single();
    if (client.Remaining != 0)
        throw new InvalidOperationException("Workflow did not consume the expected scripted responses.");
    return new(result, events.OfType<ExecutorCompletedEvent>().Select(evt => evt.ExecutorId).ToArray(),
        client.Prompts.ToArray());
}

sealed record Execution(PlanState State, string[] Steps, string[] Prompts);

// Only the inference boundary is replaced: real agents, executors, conditional edges and rules still run.
sealed class ScriptedChatClient(IEnumerable<object> responses) : IChatClient
{
    private readonly Queue<object> _responses = new(responses);
    public List<string> Prompts { get; } = [];
    public int Remaining => _responses.Count;

    public Task<ChatResponse> GetResponseAsync(
        IEnumerable<ChatMessage> messages, ChatOptions? options = null, CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        Prompts.Add(string.Join("\n", messages.Select(message => message.Text)));
        if (_responses.Count == 0)
            throw new InvalidOperationException("Unexpected extra agent call.");
        object response = _responses.Dequeue();
        string json = response is string text ? text : JsonSerializer.Serialize(response, JsonSerializerOptions.Web);
        return Task.FromResult(new ChatResponse(new ChatMessage(ChatRole.Assistant, json)));
    }

    public IAsyncEnumerable<ChatResponseUpdate> GetStreamingResponseAsync(
        IEnumerable<ChatMessage> messages, ChatOptions? options = null, CancellationToken cancellationToken = default) =>
        throw new NotSupportedException("These checks use non-streaming agent responses inside a real workflow.");

    public object? GetService(Type serviceType, object? serviceKey = null) =>
        serviceKey is null && serviceType.IsInstanceOfType(this) ? this : null;

    public void Dispose() { }
}
