# Repository context

This is a .NET DeveloperDays Warsaw 2026 workshop, not a production application.
The implemented exercises are independent .NET 10 console applications in
`exercises\exercises.slnx`. Labs live in `labs\labs.slnx` (separate solution,
same numbered part folders) under `labs\lab-NNN` with `starter` and `solution`
subfolders. Part 1 deliberately progresses through small,
participant-friendly examples rather than a shared application framework.

The root `README.md` is the slide-by-slide workshop guide. Exercise READMEs
explain setup and the concept demonstrated by their code. `LAB.md` describes
the broader DevDays Buddy conference-assistant scenario for tools, orchestration,
and reliability; it is not a description of the current Part 1 implementations.

## Build and run

Run commands from the repository root in PowerShell:

```powershell
# Build all exercises.
dotnet build .\exercises\exercises.slnx

# Build all labs (starter and solution projects).
dotnet build .\labs\labs.slnx

# Build or run only the exercise being changed.
dotnet build .\exercises\exercise-106\ChatbotAgent.csproj
dotnet run --project .\exercises\exercise-106\ChatbotAgent.csproj

# Check patch whitespace.
git diff --check

# Generate selected SVG slides; OnlySlides accepts integer slide numbers.
.\_tools\build-slides.ps1 -OnlySlides @(12,20,21,22,23,24,25)

# Regenerate all SVG slides.
.\_tools\build-slides.ps1

# Export the complete PowerPoint using installed Microsoft Edge.
.\_tools\svg_to_pptx.ps1
```

Runtime checks require a configured Foundry deployment, or a running Ollama
server for exercise 105. Exercise 001's Spectre.Console input requires an
interactive terminal; the simpler Part 1 loops also accept piped input.

## Exercise architecture and teaching boundaries

- **001:** Token Visualizer uses the OpenAI Responses SDK directly, local
  o200k_base tokenization, and API-reported usage. `FoundryEndpoint` handles
  endpoint validation/resolution; `TokenVisualizerUi` handles the richer
  Spectre.Console interface. Local full-history token counts are estimates;
  API usage is authoritative.
- **101-103:** Responses clients are adapted to `IChatClient`. Exercise 101
  sends only the current input. Exercise 102 keeps `List<ChatMessage>` outside
  the loop and retains `response.Messages`. Exercise 103 replaces the first
  system message each turn, lowering the persona age from 10 by 2 after each
  successful reply and clamping it at zero.
- **104:** Independent structured-output requests use
  `GetResponseAsync<Employee>(..., useJsonSchemaResponseFormat: true)` and
  `response.Result`. The record defines family name, first name, `DateOnly`
  birth date, `decimal` annual gross salary in EUR, and function title.
- **105:** `OllamaApiClient` implements `IChatClient` for `qwen2.5:7b` at
  `http://localhost:11434`, retaining exercise 102's history loop. It needs
  no Foundry configuration.
- **106:** An `AIAgent` wraps `IChatClient` with fixed 10-year-old persona
  instructions. One `AgentSession` is reused for every `RunAsync`.
  `InMemoryChatHistoryProvider` stores messages in the session state bag;
  `StoredOutputEnabled = false` disables server-side Responses storage.
  `DebugHistory` reads the actual session with `TryGetInMemoryChatHistory`.
  History is local, but inference still sends it to Foundry.
- **Lab 100:** DevDays Buddy builds on 106. `agenda.json` (conference info plus
  every Tuesday/Wednesday slot with day, date, times, room, type, level,
  description, and speakers with name/title/description, scraped from the
  Sessionize agenda on developerdays.eu) is an `EmbeddedResource` with
  `LogicalName="agenda.json"`; the raw JSON is interpolated into the agent
  instructions. Spectre.Console 0.57.2 adds a banner, status spinner, answer
  panels, and an `agenda` table; input uses `Console.ReadLine`, so piped input
  works. The starter has the packages, the same `agenda.json`, and TODOs only.
  Keep both `agenda.json` copies identical; no tools in Part 1 labs.

Keep Part 1 code short enough for participants to type. Preserve each
exercise's teaching boundary: do not add history to 101, agents to 101-105,
or tools/workflows to 106. The richer validation and error handling in 001
are intentional, not a template to copy into every introductory exercise.

## Configuration and SDK conventions

Cloud exercises read `FOUNDRY_ENDPOINT`, `FOUNDRY_API_KEY`, and
`FOUNDRY_MODEL_DEPLOYMENT`. The latter is a deployment name, not necessarily
a model catalog identifier. For API-key inference, project/resource endpoints
are mapped to the resource's `/openai/v1`; a Foundry project URL does not turn
these clients into `AIProjectClient` or enable project-level agent APIs.

Local `Properties\launchSettings.json` profiles are optional and explicitly
ignored per exercise in `.gitignore`. They may contain real API keys: do not
print their contents, embed their values in documentation, or commit them.
When adding a cloud exercise or lab, add its profile path to `.gitignore` before
copying local configuration.

Exercises 001, 101-104, 106, and the lab 100 solution use OpenAI 2.14.0;
101-104 use Microsoft.Extensions.AI/OpenAI 10.11.0; 106 and the lab 100
solution use Microsoft.Agents.AI 1.24.0 with the OpenAI adapter 10.11.0 (the
lab 100 starter still references 106's older 1.0.0/10.4.0/2.9.1 versions).
In 2.14.0, `ResponsesClient` takes `ResponsesClientOptions` (not
`OpenAIClientOptions`) and no model: pass the deployment to
`AsIChatClient(model)`, or set `CreateResponseOptions.Model` when using the
SDK directly (001). Exercise 105 uses OllamaSharp 5.5.0 and its transitive
AI dependencies. Do not change these versions without checking SDK
signatures and runtime compatibility. Responses exercises suppress `OPENAI001`.

Console labels are `[USER]:` and `[ASSISTANT]:`; exercise 103 includes the
current age in its assistant label. Part 1 skips blank input and exits on
EOF or case-insensitive `quit`. Only 001 implements `clear`.

## Keeping exercises and presentation synchronized

A new exercise or lab includes a project, a README, a solution-folder entry
(`exercises.slnx` for exercises, `labs.slnx` for labs), a
slide, and a link to its README directly below that slide image in the root
README. Keep code snippets, package descriptions, and history claims aligned
with the implementation.

`_tools\build-slides.ps1` is the editable slide source; `_slides\slide-NN.svg`
and the root PowerPoint are generated deliverables. Change the generator,
regenerate affected SVGs, then export the deck. The PowerPoint contains
rasterized images, not editable text/shapes. Export failures preserve the
previous deck.

Reuse `ExerciseBody` for exercise slides: exactly three numbered action
cards, hands-on banner, number badge, project link/run strip, and takeaway.
The red header passed to `SaveSlide` is `EXERCISE {number}`. Keep card
details to at most three short lines. Use the generator's `Text`/`Lines`
helpers to XML-escape content.

Slides use a 3840 x 2160 canvas with a 1920 x 1080 coordinate system,
Raleway 700 headings, Open Sans body text, 100-unit horizontal margins,
and a footer at y=985. Fonts and graphics are embedded from `_resources`.
See `_tools\README.md` for layout and export details.

Current exercise slides are 001 at 12 and 101-106 at 20-25, and lab 100 is at
26 (`ExerciseBody -badge 'LAB'`, header `LAB 100`); section dividers
and closing slides follow them. Adding slides requires updating generator
numbering, the shifted SVG outputs, root README headings/image references,
and the deck, as well as slide-count references in tool documentation.
