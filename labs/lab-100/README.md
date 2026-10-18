# Lab 100 - DevDays Buddy: Conference Agenda Agent

> **Part:** Part 1, From LLM calls to agents  
> **Focus:** Ground an agent with hard-coded context from an embedded JSON document  
> **Builds on:** [Exercise 107 - Chatbot Agent](../../exercises/exercise-107/README.md)

## What you'll build

**DevDays Buddy** is a console agent that answers questions about the .NET DeveloperDays 2026 Warsaw conference: what is on, when and where it starts, who is speaking, and what a session or speaker is about.

You combine everything from Part 1:

- the Foundry-backed `IChatClient` from exercises 101-105;
- the `AIAgent`, instructions, `InMemoryChatHistoryProvider`, and reusable `AgentSession` from exercise 107;
- the complete conference agenda from an `agenda.json` file that is compiled into the app as an **embedded resource** and pasted into the agent instructions as context;
- a richer terminal UI built with [Spectre.Console](https://spectreconsole.net/).

There are no tools yet. The model receives the whole agenda with every request; Part 2 replaces this with tools that look up only what is needed.

## Folders

| Folder | Contents |
| --- | --- |
| [`starter`](starter) | An empty console app with the packages, embedded `agenda.json`, and TODO steps. Start here. |
| [`solution`](solution) | One possible solution. Compare after you finish or when you are stuck. |

Both projects are in [`labs\labs.slnx`](../labs.slnx), separate from the exercises solution.

Both projects target **.NET 10** and add `Spectre.Console` 0.57.2. The starter keeps exercise 107's package versions; the solution uses newer Agent Framework and OpenAI packages:

```xml
<PackageReference Include="Microsoft.Agents.AI" Version="1.24.0" />
<PackageReference Include="OpenAI" Version="2.14.0" />
<PackageReference Include="Microsoft.Extensions.AI.OpenAI" Version="10.11.0" />
<PackageReference Include="Spectre.Console" Version="0.57.2" />
```

From OpenAI 2.14.0, `ResponsesClient` takes `ResponsesClientOptions` instead of `OpenAIClientOptions`; the endpoint and API-key setup are otherwise unchanged:

```csharp
ResponsesClient client = new(
    credential: new ApiKeyCredential(key),
    options: new ResponsesClientOptions
    {
        Endpoint = new UriBuilder(endpoint) { Path = "/openai/v1" }.Uri
    });
```

## The agenda document

`agenda.json` contains the general conference information (description, dates, format, venue, rooms, and session levels) and an `agenda` array with every slot of the Tuesday and Wednesday programme. Each session includes:

| Field | Example |
| --- | --- |
| `day`, `date` | `Tuesday`, `2026-10-20` |
| `start`, `end` | `10:30`, `11:30` (Warsaw time) |
| `room` | `Room A` |
| `type` | `keynote`, `session`, or `break` |
| `title`, `level`, `description` | Session title, level, and abstract |
| `speakers[]` | `name`, `title`, and `description` of each speaker |

Breaks, lunch, registration, and the party are included as `break` items so the agent can also answer "When is lunch?". The data comes from the [conference agenda](https://developerdays.eu/warsaw/conference/) and the [conference home page](https://developerdays.eu/warsaw/) and is hard-coded on purpose: the app works without scraping the website. The official website remains the source of truth for last-minute changes.

The project file embeds it with a fixed resource name:

```xml
<ItemGroup>
  <EmbeddedResource Include="agenda.json" LogicalName="agenda.json" />
</ItemGroup>
```

## Your task

Open [`starter\Program.cs`](starter/Program.cs) and follow the TODOs. Copy code from your exercise 107 solution where it helps.

### 1. Read the embedded agenda

```csharp
static string ReadEmbeddedResource(string name)
{
    using var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(name)
        ?? throw new InvalidOperationException($"Embedded resource '{name}' not found.");
    using var reader = new StreamReader(stream);
    return reader.ReadToEnd();
}
```

The file travels inside the assembly, so there is no file path to get wrong when the app runs from another directory.

### 2. Put the agenda in the agent instructions

```csharp
var agendaJson = ReadEmbeddedResource("agenda.json");

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
```

This is the simplest form of grounding: the relevant knowledge is placed directly in the context window. It works because the agenda is small enough, about 75 KB of JSON or roughly 20,000 tokens, but **every request sends the full agenda again**, plus the growing conversation history. That costs tokens and latency, which is exactly the problem tools and retrieval solve later.

### 3. Chat with one session

Create one `AgentSession` before the loop and pass it to `RunAsync` on every question, exactly like exercise 107, so follow-up questions such as "And what is the speaker's background?" work.

### 4. Spice it up with Spectre.Console

The solution uses:

- `FigletText` and `Rule` for a conference banner;
- a `Panel` with the conference description, venue, and session count read from the same JSON;
- `AnsiConsole.Status()` with a spinner while the agent is thinking;
- a `Panel` for every answer, with `Markup.Escape` so model output containing `[` or `]` cannot break Spectre markup;
- an `agenda` command that renders a `Table` per day without calling the model.

The JSON is deserialized into small records for the UI with `JsonSerializerOptions.Web`, while the agent receives the raw JSON text.

## Run it

Use the **.NET 10 SDK** and the [Foundry environment-variable setup from exercise 001](../../exercises/exercise-001/README.md#1-set-your-microsoft-foundry-credentials). An optional, Git-ignored `Properties\launchSettings.json` can supply the variables; never commit your API key.

```powershell
dotnet run --project .\labs\lab-100\starter\DevDaysBuddy.Starter.csproj
dotnet run --project .\labs\lab-100\solution\DevDaysBuddy.csproj
```

Type a question and press **Enter**. Type `agenda` to show the schedule, `/debug` to inspect the local conversation history in a colored Spectre.Console table, and `/quit` to exit. The original `quit` command still works. Commands are case-insensitive and are handled locally, without calling the model. The history view distinguishes message roles, function calls (call ID, name, and arguments), and function results (call ID and result); Lab 100 itself does not expose tools.

## Try it

1. "Which sessions are about AI or LLMs?"
2. "What is on in Room C on Wednesday afternoon?"
3. "Who is Richard Campbell?" then "When are his talks?"
4. "I like performance and C#. Plan my Wednesday without overlaps."
5. "When is lunch on Tuesday, and when does the party start?"
6. "Is there a session about Blazor WebAssembly testing?" The agent should say when something is not in the agenda.
7. Type `/debug` to inspect the messages, then `/quit` to exit.

Answers can still be wrong: the model may misread a time or invent a detail. Ask for the session title and time, then compare with the `agenda` table.

## Going further

- Count the input tokens of a request with the token visualizer from exercise 001 and compare with exercise 107.
- Think about what would break with an agenda ten times larger. Part 2 answers this with tools.
