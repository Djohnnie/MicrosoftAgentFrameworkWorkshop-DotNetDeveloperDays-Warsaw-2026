using System.ClientModel;
using System.Text.Json;
using Microsoft.Agents.AI;
using Microsoft.Extensions.AI;
using ModelContextProtocol.Client;
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

await using McpClient mcpClient = await McpClient.CreateAsync(
    new HttpClientTransport(new HttpClientTransportOptions
    {
        Endpoint = new Uri("http://localhost:5286/mcp"),
        TransportMode = HttpTransportMode.StreamableHttp
    }));
IList<McpClientTool> tools = await mcpClient.ListToolsAsync();

ResponsesClient responsesClient = new(
    credential: new ApiKeyCredential(key),
    options: new ResponsesClientOptions
    {
        Endpoint = new UriBuilder(endpoint) { Path = "/openai/v1" }.Uri
    });

using IChatClient chatClient = responsesClient.AsIChatClient(model);

AIAgent agent = chatClient.AsAIAgent(new ChatClientAgentOptions
{
    Name = "DevDaysBuddy",
    ChatHistoryProvider = new InMemoryChatHistoryProvider(),
    ChatOptions = new ChatOptions
    {
        Instructions = """
            You are DevDays Buddy, a helpful assistant for .NET DeveloperDays 2026 Warsaw.
            Use the available MCP tools to answer questions about the conference, speakers, and sessions.
            Do not invent conference facts. If a tool reports ambiguity, ask the user to clarify.
            Conference times are local Warsaw time. Keep answers concise and in plain text.
            """,
        Tools = [.. tools],
        RawRepresentationFactory = _ => new CreateResponseOptions
        {
            StoredOutputEnabled = false
        }
    }
});
AgentSession session = await agent.CreateSessionAsync();

ShowWelcome(tools);

while (true)
{
    AnsiConsole.Markup("[bold yellow][[USER]]:[/] ");
    string? input = Console.ReadLine();
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

    AgentResponse response = await AnsiConsole.Status()
        .Spinner(Spinner.Known.Dots)
        .StartAsync("Looking up the conference information...", _ => agent.RunAsync(input, session));

    AnsiConsole.Write(new Panel(Markup.Escape(response.Text))
        .Header("[bold deepskyblue1][[ASSISTANT]][/]")
        .Border(BoxBorder.Rounded)
        .BorderColor(Color.DeepSkyBlue1));
    AnsiConsole.WriteLine();
}

static void ShowWelcome(IList<McpClientTool> tools)
{
    AnsiConsole.Write(new FigletText("DevDays Buddy").Centered().Color(Color.OrangeRed1));
    AnsiConsole.Write(new Rule("[bold].NET DeveloperDays Warsaw 2026[/]").RuleStyle("orangered1"));

    var toolTable = new Table()
        .Border(TableBorder.Rounded)
        .AddColumn("[bold]MCP tool[/]")
        .AddColumn("[bold]What it can do[/]");

    foreach (McpClientTool tool in tools)
        toolTable.AddRow(Markup.Escape(tool.Name), Markup.Escape(tool.Description ?? string.Empty));

    AnsiConsole.Write(toolTable);
    AnsiConsole.MarkupLine("\n[grey]Ask about the conference, its dates, speakers, or sessions.[/]");
    AnsiConsole.MarkupLine("[grey]Commands: [bold]/debug[/] to show conversation history / [bold]/quit[/] to exit.[/]");
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
