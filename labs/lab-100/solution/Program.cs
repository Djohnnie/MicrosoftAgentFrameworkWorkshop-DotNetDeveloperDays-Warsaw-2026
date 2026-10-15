using System.ClientModel;
using System.Reflection;
using System.Text.Json;
using Microsoft.Agents.AI;
using Microsoft.Extensions.AI;
using OpenAI;
using OpenAI.Responses;
using Spectre.Console;

#pragma warning disable OPENAI001

var endpoint = Environment.GetEnvironmentVariable("FOUNDRY_ENDPOINT")
    ?? throw new InvalidOperationException("Set FOUNDRY_ENDPOINT");
var key = Environment.GetEnvironmentVariable("FOUNDRY_API_KEY")
    ?? throw new InvalidOperationException("Set FOUNDRY_API_KEY");
var model = Environment.GetEnvironmentVariable("FOUNDRY_MODEL_DEPLOYMENT")
    ?? throw new InvalidOperationException("Set FOUNDRY_MODEL_DEPLOYMENT");

// 1. Read the agenda that is compiled into the assembly.
var agendaJson = ReadEmbeddedResource("agenda.json");
var agenda = JsonSerializer.Deserialize<AgendaDocument>(agendaJson, JsonSerializerOptions.Web)
    ?? throw new InvalidOperationException("agenda.json is empty.");

// 2. Create the agent and give it the complete agenda as context.
ResponsesClient client = new(
    credential: new ApiKeyCredential(key),
    options: new ResponsesClientOptions
    {
        Endpoint = new UriBuilder(endpoint) { Path = "/openai/v1" }.Uri
    });

using IChatClient chatClient = client.AsIChatClient(model);

AIAgent agent = chatClient.AsAIAgent(new ChatClientAgentOptions
{
    Name = "DevDaysBuddy",
    ChatHistoryProvider = new InMemoryChatHistoryProvider(),
    ChatOptions = new ChatOptions
    {
        Instructions = $"""
            You are DevDays Buddy, a friendly assistant for attendees of .NET DeveloperDays 2026 Warsaw.
            Answer questions about the conference using only the CONFERENCE AGENDA JSON below.
            All times are local Warsaw time. When you mention a session, include its day, time, room, and speakers.
            If the answer is not in the agenda, say that you do not know instead of making it up.
            Keep answers short and use plain text without Markdown formatting.

            CONFERENCE AGENDA JSON:
            {agendaJson}
            """,
        RawRepresentationFactory = _ => new CreateResponseOptions
        {
            StoredOutputEnabled = false
        }
    }
});

AgentSession session = await agent.CreateSessionAsync();

// 3. Spice up the console with Spectre.Console.
ShowWelcome(agenda);

while (true)
{
    AnsiConsole.Markup("[bold yellow][[USER]]:[/] ");
    var input = Console.ReadLine();
    if (input is null
        || input.Equals("quit", StringComparison.OrdinalIgnoreCase)
        || input.Equals("/quit", StringComparison.OrdinalIgnoreCase))
        break;

    if (string.IsNullOrWhiteSpace(input))
        continue;

    if (input.Equals("/debug", StringComparison.OrdinalIgnoreCase))
    {
        DebugHistory(session);
        continue;
    }

    if (input.Equals("agenda", StringComparison.OrdinalIgnoreCase))
    {
        ShowAgenda(agenda);
        continue;
    }

    var response = await AnsiConsole.Status()
        .Spinner(Spinner.Known.Dots)
        .StartAsync("Checking the agenda...", _ => agent.RunAsync(input, session));

    AnsiConsole.Write(new Panel(Markup.Escape(response.Text))
        .Header("[bold deepskyblue1][[ASSISTANT]][/]")
        .Border(BoxBorder.Rounded)
        .BorderColor(Color.DeepSkyBlue1));
    AnsiConsole.WriteLine();
}

static string ReadEmbeddedResource(string name)
{
    using var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(name)
        ?? throw new InvalidOperationException($"Embedded resource '{name}' not found.");
    using var reader = new StreamReader(stream);
    return reader.ReadToEnd();
}

static void ShowWelcome(AgendaDocument agenda)
{
    AnsiConsole.Write(new FigletText("DevDays Buddy").Centered().Color(Color.OrangeRed1));
    AnsiConsole.Write(new Rule($"[bold]{Markup.Escape(agenda.Conference.Name)}[/]").RuleStyle("orangered1"));

    var sessions = agenda.Agenda.Count(item => item.Type != "break");
    var speakers = agenda.Agenda.SelectMany(item => item.Speakers ?? []).Select(s => s.Name).Distinct().Count();

    AnsiConsole.Write(new Panel(new Rows(
            new Markup($"[grey]{Markup.Escape(agenda.Conference.Description)}[/]"),
            new Text(""),
            new Markup($"[bold]Where:[/] {Markup.Escape($"{agenda.Conference.Venue.Name}, {agenda.Conference.Venue.Address}")}"),
            new Markup($"[bold]When:[/] {string.Join(" and ", agenda.Agenda.Select(item => item.Day).Distinct())}, {sessions} sessions by {speakers} speakers")))
        .Border(BoxBorder.Rounded)
        .BorderColor(Color.Grey));

    AnsiConsole.MarkupLine("[grey]Ask anything about the agenda, for example: [italic]Which AI sessions are on Tuesday?[/][/]");
    AnsiConsole.MarkupLine("[grey]Commands: [bold]agenda[/] to show the schedule / [bold]/debug[/] to show conversation history / [bold]/quit[/] to exit.[/]");
    AnsiConsole.WriteLine();
}

static void ShowAgenda(AgendaDocument agenda)
{
    foreach (var day in agenda.Agenda.GroupBy(item => item.Day))
    {
        var table = new Table()
            .Title($"[bold orangered1]{day.Key}[/]")
            .Border(TableBorder.Rounded)
            .AddColumn("[bold]Time[/]")
            .AddColumn("[bold]Room[/]")
            .AddColumn("[bold]Session[/]")
            .AddColumn("[bold]Speakers[/]");

        foreach (var item in day)
        {
            var title = item.Type == "break"
                ? $"[grey]{Markup.Escape(item.Title)}[/]"
                : Markup.Escape(item.Title);
            table.AddRow(
                $"{item.Start}-{item.End}",
                Markup.Escape(item.Room),
                title,
                Markup.Escape(string.Join(", ", item.Speakers?.Select(s => s.Name) ?? [])));
        }

        AnsiConsole.Write(table);
    }

    AnsiConsole.WriteLine();
}

static void DebugHistory(AgentSession session)
{
    AnsiConsole.Write(new Rule("[bold]AgentSession local in-memory history[/]"));

    if (!session.TryGetInMemoryChatHistory(out var messages) || messages.Count == 0)
    {
        AnsiConsole.MarkupLine("[grey]No stored messages yet.[/]");
        AnsiConsole.WriteLine();
        return;
    }

    AnsiConsole.MarkupLine($"[grey]Stored messages: {messages.Count}[/]");

    var table = new Table()
        .Border(TableBorder.Rounded)
        .AddColumn("[bold]#[/]")
        .AddColumn("[bold]Role / content[/]")
        .AddColumn("[bold]Details[/]");

    for (var i = 0; i < messages.Count; i++)
    {
        var message = messages[i];
        foreach (var content in message.Contents)
        {
            string color;
            string kind;
            string details;

            switch (content)
            {
                case FunctionCallContent call:
                    color = "mediumpurple1";
                    kind = "FunctionCallContent";
                    details = $"CallId: {call.CallId}\nName: {call.Name}\nArguments: {JsonSerializer.Serialize(call.Arguments)}";
                    break;
                case FunctionResultContent result:
                    color = "green";
                    kind = "FunctionResultContent";
                    details = $"CallId: {result.CallId}\nResult: {JsonSerializer.Serialize(result.Result)}";
                    break;
                default:
                    color = message.Role == ChatRole.User ? "yellow"
                        : message.Role == ChatRole.Assistant ? "deepskyblue1"
                        : "grey";
                    kind = content.GetType().Name;
                    details = content.ToString() ?? string.Empty;
                    break;
            }

            table.AddRow(
                (i + 1).ToString(),
                $"[{color}]{Markup.Escape($"{message.Role}\n{kind}")}[/]",
                $"[{color}]{Markup.Escape(details)}[/]");
        }
    }

    AnsiConsole.Write(table);
    AnsiConsole.WriteLine();
}

record AgendaDocument(ConferenceInfo Conference, List<AgendaItem> Agenda);
record ConferenceInfo(string Name, string Description, Venue Venue);
record Venue(string Name, string Address);
record AgendaItem(string Day, string Start, string End, string Room, string Type, string Title, List<Speaker>? Speakers);
record Speaker(string Name);