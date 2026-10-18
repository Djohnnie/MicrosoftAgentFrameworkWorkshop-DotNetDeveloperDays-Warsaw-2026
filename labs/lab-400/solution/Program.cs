using System.ClientModel;
using System.Globalization;
using System.Text.Json;
using Azure.AI.Extensions.OpenAI;
using Azure.AI.Projects;
using Azure.Identity;
using Microsoft.Agents.AI;
using Microsoft.Agents.AI.Foundry;
using Microsoft.Agents.AI.Workflows;
using Microsoft.Extensions.AI;
using OpenAI.Responses;
using Spectre.Console;

var endpoint = Environment.GetEnvironmentVariable("FOUNDRY_ENDPOINT")
    ?? throw new InvalidOperationException("Set FOUNDRY_ENDPOINT to the full Foundry project endpoint");
var tenantId = Environment.GetEnvironmentVariable("TENANT_ID")
    ?? throw new InvalidOperationException("Set TENANT_ID");
var clientId = Environment.GetEnvironmentVariable("CLIENT_ID")
    ?? throw new InvalidOperationException("Set CLIENT_ID");
var clientSecret = Environment.GetEnvironmentVariable("CLIENT_SECRET")
    ?? throw new InvalidOperationException("Set CLIENT_SECRET");
var agentName = Environment.GetEnvironmentVariable("FOUNDRY_AGENT_NAME")
    ?? throw new InvalidOperationException("Set FOUNDRY_AGENT_NAME");
var agentVersion = Environment.GetEnvironmentVariable("FOUNDRY_AGENT_VERSION")
    ?? throw new InvalidOperationException("Set FOUNDRY_AGENT_VERSION to an existing version");
var key = Environment.GetEnvironmentVariable("FOUNDRY_API_KEY")
    ?? throw new InvalidOperationException("Set FOUNDRY_API_KEY");
var model = Environment.GetEnvironmentVariable("FOUNDRY_MODEL_DEPLOYMENT")
    ?? throw new InvalidOperationException("Set FOUNDRY_MODEL_DEPLOYMENT");

var credential = new ClientSecretCredential(tenantId, clientId, clientSecret);
var projectClient = new AIProjectClient(new Uri(endpoint), credential);
FoundryAgent picker = projectClient.AsAIAgent(new AgentReference(agentName, agentVersion));
SessionOption[] catalog = ConferenceAgenda.Load();

// API-key inference uses the resource's OpenAI v1 endpoint, not Foundry project-level agent APIs.
ResponsesClient responsesClient = new(new ApiKeyCredential(key), new ResponsesClientOptions
{
    Endpoint = new UriBuilder(endpoint) { Path = "/openai/v1" }.Uri
});
using IChatClient chatClient = responsesClient.AsIChatClient(model);

// Only these two agent definitions live in this process; their inference still runs in Foundry.
AIAgent scheduler = PlanningAgents.Create<ScheduleDraft>(chatClient, "ScheduleBuilder", """
    Build a chronological, non-overlapping itinerary using only the supplied candidate session IDs.
    Stay inside the attendee's date/time window. Include a short recommendation reason per session.
    Prefer relevant sessions, not simply the largest number of sessions. Gaps are allowed.
    If a previous draft was rejected, fix its validation errors and use the reviewer feedback.
    """);
AIAgent reviewer = PlanningAgents.Create<PlanReview>(chatClient, "PlanReviewer", """
    Review the draft against the attendee's interests and the supplied agenda candidates.
    Approve only if it is useful and the validation errors array is empty.
    Otherwise reject it with specific, actionable feedback for the Schedule Builder.
    Do not require every interest to have a matching talk if the agenda cannot support it.
    """);

AnsiConsole.Write(new FigletText("DevDays Buddy").Color(Color.OrangeRed1));
AnsiConsole.MarkupLine("[bold]Lab 400: A hosted picker, a local workflow[/]");
AnsiConsole.MarkupLine("[grey]Foundry Session Picker -> local Schedule Builder -> local Plan Reviewer[/]");
AnsiConsole.MarkupLine("[grey]At most two revisions. Canonical agenda checks in C#. Times are local Warsaw time.[/]");
AnsiConsole.MarkupLine("[grey]Each plan is independent. Use quit or /quit at any prompt to exit.[/]");

while (true)
{
    string? dateText = ReadInput("Date (yyyy-MM-dd, e.g. 2026-10-20)");
    if (dateText is null) break;
    string? fromText = ReadInput("Available from (HH:mm, e.g. 09:00)");
    if (fromText is null) break;
    string? untilText = ReadInput("Available until (HH:mm, e.g. 18:00)");
    if (untilText is null) break;
    string? interests = ReadInput("Interests (e.g. .NET, AI and security)");
    if (interests is null) break;

    // Parse hard constraints locally instead of asking a model to interpret dates or availability.
    if (!DateOnly.TryParseExact(dateText, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var date)
        || !TimeOnly.TryParseExact(fromText, "HH:mm", CultureInfo.InvariantCulture, DateTimeStyles.None, out var from)
        || !TimeOnly.TryParseExact(untilText, "HH:mm", CultureInfo.InvariantCulture, DateTimeStyles.None, out var until)
        || until <= from || string.IsNullOrWhiteSpace(interests))
    {
        AnsiConsole.MarkupLine("[red]Enter a valid date, a same-day window with start before end, and interests.[/]");
        continue;
    }

    try
    {
        Workflow workflow = PlanningWorkflow.Build(
            (request, token) => FoundrySessionPicker.PickAsync(picker, request, token),
            scheduler, reviewer,
            (day, _) => Task.FromResult(catalog.Where(item => item.Date == day).ToArray()));
        await using StreamingRun run = await InProcessExecution.RunStreamingAsync(
            workflow, new PlanState(new PlanRequest(date, from, until, interests)));
        bool receivedOutput = false;
        // Stream workflow progress, not model tokens: participants can see each completed handoff and route.
        await foreach (WorkflowEvent evt in run.WatchStreamAsync())
        {
            if (evt is WorkflowErrorEvent failure)
                throw new InvalidOperationException("Workflow failed.", failure.Exception);
            if (evt is ExecutorCompletedEvent completed && completed.Data is PlanState step
                && completed.ExecutorId != "FinalPlan")
                ShowStep(completed.ExecutorId, step);
            if (evt is WorkflowOutputEvent { Data: PlanState result })
            {
                receivedOutput = true;
                ShowResult(result);
            }
        }
        // An ended event stream is not proof that planning produced a result.
        if (!receivedOutput)
            throw new InvalidOperationException("The workflow ended without a final plan.");
    }
    catch (Exception ex) when (ex is InvalidOperationException or HttpRequestException or JsonException
        or ClientResultException or Azure.RequestFailedException or Azure.Identity.AuthenticationFailedException)
    {
        AnsiConsole.Write(new Panel(Markup.Escape(ex.ToString()))
            .Header("[red]Planning failed - no approved plan[/]").BorderColor(Color.Red));
    }
}

static string? ReadInput(string label)
{
    AnsiConsole.Markup($"[yellow]{Markup.Escape(label)}:[/] ");
    string? value = Console.ReadLine();
    return value is null || value.Equals("quit", StringComparison.OrdinalIgnoreCase)
        || value.Equals("/quit", StringComparison.OrdinalIgnoreCase) ? null : value.Trim();
}

static void ShowStep(string executorId, PlanState state)
{
    string details = executorId switch
    {
        "SessionPicker" => JsonSerializer.Serialize(state.Candidates, JsonSerializerOptions.Web),
        "ScheduleBuilder" => $"Draft {state.DraftNumber}\n"
            + JsonSerializer.Serialize(state.Draft, JsonSerializerOptions.Web),
        _ => $"Approved by reviewer: {state.Review.Approved}\n{state.Review.Feedback}\n"
            + string.Join("\n", state.Errors)
            + (state.ShouldRevise ? "\nRouting back to Schedule Builder." : "\nRouting to final output.")
    };
    AnsiConsole.Write(new Panel(Markup.Escape(details))
        .Header($"[deepskyblue1]{Markup.Escape(executorId)}[/]").Border(BoxBorder.Rounded));
}

static void ShowResult(PlanState state)
{
    if (!state.Accepted)
    {
        string reason = state.Candidates.Length == 0 ? state.Review.Feedback
            : $"No approved plan after {state.DraftNumber} drafts.\n{state.Review.Feedback}\n"
                + string.Join("\n", state.Errors);
        AnsiConsole.Write(new Panel(Markup.Escape(reason))
            .Header("[yellow]No approved itinerary[/]").BorderColor(Color.Yellow));
        return;
    }

    // Resolve accepted IDs against the local snapshot, never model-invented times or titles.
    var table = new Table().Border(TableBorder.Rounded)
        .Title("[bold green]Approved itinerary - Warsaw local time[/]")
        .AddColumn("Time").AddColumn("Session / speakers").AddColumn("Room").AddColumn("Why");
    foreach (SessionChoice choice in state.Draft.OrderBy(choice =>
        state.Catalog.Single(item => item.Id == choice.SessionId).Start))
    {
        SessionOption session = state.Catalog.Single(item => item.Id == choice.SessionId);
        table.AddRow($"{session.Start:HH:mm}-{session.End:HH:mm}",
            Markup.Escape($"{session.Title}\n{string.Join(", ", session.Speakers)}"),
            Markup.Escape(session.Room), Markup.Escape(choice.Reason));
    }
    AnsiConsole.Write(table);
    AnsiConsole.WriteLine(state.Review.Feedback);
}
