using Microsoft.ML.Tokenizers;
using OpenAI.Responses;
using Spectre.Console;

#pragma warning disable OPENAI001

internal static class TokenVisualizerUi
{
    public static void ShowBanner()
    {
        AnsiConsole.Write(new FigletText("Token Visualizer").Centered().Color(Color.Cyan1));
        AnsiConsole.Write(new Rule("[bold deepskyblue1]OpenAI SDK / Microsoft Foundry / o200k_base tokenizer[/]")
            .RuleStyle("grey23").Centered());
        AnsiConsole.WriteLine();
    }

    public static void ShowMissingConfiguration()
    {
        ShowError("Missing configuration. Please set the following environment variables:");
        AnsiConsole.MarkupLine("  [yellow]FOUNDRY_ENDPOINT[/]          -- Foundry project, resource, or OpenAI v1 endpoint");
        AnsiConsole.MarkupLine("  [yellow]FOUNDRY_API_KEY[/]           -- Foundry API key");
        AnsiConsole.MarkupLine("  [yellow]FOUNDRY_MODEL_DEPLOYMENT[/]  -- Deployment name");
    }

    public static void ShowError(string message) =>
        AnsiConsole.MarkupLine($"[bold red]{Markup.Escape(message)}[/]");

    public static void ShowChatInstructions()
    {
        AnsiConsole.MarkupLine("[grey]Chat mode active -- conversation history is maintained across turns.[/]");
        AnsiConsole.MarkupLine("[grey]Commands: [bold]quit[/] to exit / [bold]clear[/] to reset history.[/]");
        AnsiConsole.WriteLine();
    }

    public static string ReadInput()
    {
        var input = AnsiConsole.Ask<string>("[bold yellow][[USER]]:[/]");
        AnsiConsole.WriteLine();
        return input;
    }

    public static void ShowHistoryCleared()
    {
        AnsiConsole.MarkupLine("[grey]Conversation history cleared.[/]");
        AnsiConsole.WriteLine();
    }

    public static void ShowInputTokens(IReadOnlyList<EncodedToken> tokens)
    {
        ShowRule("[USER]: Token Stream", "yellow");
        VisualizeTokens(tokens);
    }

    public static async Task<ResponseResult> WaitForResponseAsync(Func<Task<ResponseResult>> getResponse) =>
        await AnsiConsole.Status()
            .Spinner(Spinner.Known.Dots2)
            .SpinnerStyle(Style.Parse("cyan"))
            .StartAsync("[cyan]Waiting for AI response...[/]", _ => getResponse());

    public static void ShowResponse(string text, IReadOnlyList<EncodedToken> tokens)
    {
        ShowRule("[ASSISTANT]:", "green");
        AnsiConsole.Write(new Panel(new Markup(Markup.Escape(text)))
            .BorderStyle(Style.Parse("green")).Expand());
        AnsiConsole.WriteLine();
        ShowRule("[ASSISTANT]: Token Stream", "green");
        VisualizeTokens(tokens);
    }

    public static void ShowComparison(int messageOnly, int localInput, int localOutput, ResponseTokenUsage? usage)
    {
        ShowRule("Token Count Comparison", "deepskyblue1");
        var table = new Table()
            .Border(TableBorder.Rounded)
            .BorderStyle(Style.Parse("deepskyblue1"))
            .Expand()
            .AddColumn(new TableColumn("[bold]Metric[/]"))
            .AddColumn(new TableColumn("[bold orange1]Local (message)[/]").Centered())
            .AddColumn(new TableColumn("[bold yellow]Local (full history)[/]").Centered())
            .AddColumn(new TableColumn("[bold cyan]Foundry Responses API[/]").Centered())
            .AddColumn(new TableColumn("[bold]Delta[/]").Centered());

        AddUsageRow(table, "Input tokens", messageOnly, localInput, usage?.InputTokenCount);
        AddUsageRow(table, "Output tokens", localOutput, localOutput, usage?.OutputTokenCount);
        AddUsageRow(table, "Total tokens", messageOnly + localOutput, localInput + localOutput, usage?.TotalTokenCount);
        AnsiConsole.Write(table);
        AnsiConsole.MarkupLine("[grey italic]  Local history estimate = content + ~3 tokens per message + 3 reply-primer tokens.[/]");
        AnsiConsole.MarkupLine("[grey italic]  Responses API framing can differ; API usage is authoritative.[/]");
        AnsiConsole.Write(new Rule().RuleStyle("grey23"));
        AnsiConsole.WriteLine();
    }

    public static void ShowGoodbye() => AnsiConsole.MarkupLine("[bold green]Goodbye![/]");

    private static void ShowRule(string title, string color)
    {
        AnsiConsole.Write(new Rule($"[bold {color}] {Markup.Escape(title)} [/]").RuleStyle(color).Centered());
        AnsiConsole.WriteLine();
    }

    private static void VisualizeTokens(IReadOnlyList<EncodedToken> tokens)
    {
        var line = new Paragraph();
        for (var i = 0; i < tokens.Count; i++)
        {
            var color = Color.FromConsoleColor((ConsoleColor)(1 + i % 14));
            line.Append(tokens[i].Value, new Style(color, Color.Grey11));
        }
        AnsiConsole.Write(line);
        AnsiConsole.WriteLine();
        AnsiConsole.WriteLine();
    }

    private static void AddUsageRow(Table table, string metric, int messageCount, int historyCount, long? apiCount)
    {
        table.AddRow(
            metric,
            $"[orange1]{messageCount}[/]",
            $"[yellow]{historyCount}[/]",
            apiCount.HasValue ? $"[cyan]{apiCount}[/]" : "[grey]n/a[/]",
            apiCount.HasValue ? FormatDelta(historyCount, apiCount.Value) : "[grey]n/a[/]");
    }

    private static string FormatDelta(long local, long api)
    {
        var delta = api - local;
        return delta switch
        {
            0 => "[bold green]= 0[/]",
            > 0 => $"[bold orange1]+ {delta}[/]",
            _ => $"[bold red]{delta}[/]"
        };
    }
}
