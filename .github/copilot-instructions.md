# Repository context

This is a .NET DeveloperDays Warsaw 2026 workshop, not a production application.
The implemented exercises are independent .NET 10 examples in
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
dotnet build .\exercises\exercise-107\ChatbotAgent.csproj
dotnet run --project .\exercises\exercise-107\ChatbotAgent.csproj

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
server for exercise 106. Exercise 001's Spectre.Console input requires an
interactive terminal; the simpler Part 1 loops also accept piped input.

## Exercise architecture and teaching boundaries

- **001:** Token Visualizer uses the OpenAI Responses SDK directly, local
  o200k_base tokenization, and API-reported usage. `FoundryEndpoint` handles
  endpoint validation/resolution; `TokenVisualizerUi` handles the richer
  Spectre.Console interface. Local full-history token counts are estimates;
  API usage is authoritative.
- **101-104:** Responses clients are adapted to `IChatClient`. Exercise 101
  sends only the current input. Exercise 102 keeps `List<ChatMessage>` outside
  the loop and retains `response.Messages`. Exercise 103 copies 102 and prints
  `response.Usage.InputTokenCount` and `OutputTokenCount` after each reply,
  displaying `not reported` when a count is absent. Counts are per request,
  not cumulative or local estimates. Exercise 104 replaces the first system
  message each turn, lowering the persona age from 10 by 2 after each successful
  reply and clamping it at zero.
- **105:** Independent structured-output requests use
  `GetResponseAsync<Employee>(..., useJsonSchemaResponseFormat: true)` and
  `response.Result`. The record defines family name, first name, `DateOnly`
  birth date, `decimal` annual gross salary in EUR, and function title.
- **106:** `OllamaApiClient` implements `IChatClient` for `qwen2.5:7b` at
  `http://localhost:11434`, retaining exercise 102's history loop. It needs
  no Foundry configuration.
- **107:** An `AIAgent` wraps `IChatClient` with fixed 10-year-old persona
  instructions. One `AgentSession` is reused for every `RunAsync`.
  `InMemoryChatHistoryProvider` stores messages in the session state bag;
  `StoredOutputEnabled = false` disables server-side Responses storage.
  `DebugHistory` reads the actual session with `TryGetInMemoryChatHistory`.
  History is local, but inference still sends it to Foundry.
- **108:** An image-capable Foundry-backed `AIAgent` translates a JPEG using
  `TextContent` plus `UriContent`, then `TextContent` plus `DataContent` loaded
  from the bundled `quote.jpg`. The file is copied to the output directory.
  Each request uses a fresh session for an independent comparison; local
  history and disabled Responses storage match 107. No tools or workflows.
- **109:** Direct OpenAI `AudioClient` calls, not an `AIAgent`, transcribe the
  bundled original French `welcome-fr.wav` and translate it into English.
  Reopen the file for each request. OpenAI 2.14.0 uses `/openai/v1` with
  `OpenAIClientOptions`; `FOUNDRY_MODEL_DEPLOYMENT` must name a Whisper
  deployment supporting both audio operations. No chat history or tools.
- **Lab 100:** DevDays Buddy builds on 107. `agenda.json` (conference info plus
  every Tuesday/Wednesday slot with day, date, times, room, type, level,
  description, and speakers with name/title/description, scraped from the
  Sessionize agenda on developerdays.eu) is an `EmbeddedResource` with
  `LogicalName="agenda.json"`; the raw JSON is interpolated into the agent
  instructions. Spectre.Console 0.57.2 adds a banner, status spinner, answer
  panels, and an `agenda` table; input uses `Console.ReadLine`, so piped input
  works. The starter has the packages, the same `agenda.json`, and TODOs only.
  Keep both `agenda.json` copies identical; no tools in Part 1 labs.
- **Lab 200:** DevDays Buddy moves the agenda into an ASP.NET Core MCP server.
  Keep the starter and solution server `agenda.json` files identical and
  embedded as `agenda.json`; the client must not contain or send the full
  agenda. The server exposes six focused conference, date, speaker, and
  session tools; the console client discovers them over Streamable HTTP and
  passes them to a Foundry-backed `AIAgent`.
- **Lab 300:** Builds on Lab 200 with three independent `AIAgent` instances inside
  typed Agent Framework workflow executors: Session Picker, Schedule Builder,
  and Plan Reviewer. Its completed MCP server runs on port 5287; the same six
  tools remain, but `get_sessions_for_date` returns structured JSON with stable
  IDs and canonical dates/times. Keep starter and solution server agendas
  identical to Lab 200. The workflow fetches one day through MCP in application
  code; agents receive data, not tools or the full agenda. C# validates the
  schedule; conditional edges allow at most two revisions. No shared chat
  history: each invocation creates a fresh session. Deterministic checks live in
  `labs\lab-300\checks`; `--mcp` additionally checks a running Lab 300 server.
- **301-302:** Independent Terrible Startup Pitch examples share identical
  Founder/Investor prompts and isolated fresh sessions. 301 manually calls the
  Founder and forwards its exact response text to the Investor; it has no
  workflow dependency. 302 wraps each agent in `Executor<string, string>`,
  connects them with `AddEdge`, and exposes only the Investor as workflow output.
  FUND/PASS is plain text, not a branch or revision trigger. No tools or third
  agent. Both use Agent Framework 1.24.0/OpenAI adapter 10.11.0/OpenAI 2.14.0;
  302 also uses Microsoft.Agents.AI.Workflows 1.24.0.
- **Lab 400:** Builds on Lab 300's bounded workflow. A versioned Foundry Prompt
  Agent with File Search over `labs\lab-400\agenda.json` is the Session Picker;
  it receives the request and output contract, with a per-call candidate JSON
  schema, never the local catalog. Schedule Builder and Plan Reviewer are local
  agent definitions using cloud inference. No MCP server. Both projects embed
  the same single agenda snapshot (identical to Lab 300) for canonical ID/time
  checks. Every hosted invocation creates a fresh server-side conversation.
  Uses exercise 405's Entra credentials plus API-key inference for local agents.
  Deterministic checks live in `labs\lab-400\checks`.

Keep Part 1 code short enough for participants to type. Preserve each
exercise's teaching boundary: do not add history to 101, agents to 101-106,
or tools/workflows to 107. The richer validation and error handling in 001
are intentional, not a template to copy into every introductory exercise.

## Configuration and SDK conventions

Cloud exercises read `FOUNDRY_ENDPOINT`, `FOUNDRY_API_KEY`, and
`FOUNDRY_MODEL_DEPLOYMENT`. The latter is a deployment name, not necessarily
a model catalog identifier. For API-key inference, project/resource endpoints
are mapped to the resource's `/openai/v1`; a Foundry project URL does not turn
these clients into `AIProjectClient` or enable project-level agent APIs.

Exercise 405 is the exception: it reads the full project URL from
`FOUNDRY_ENDPOINT` and wraps an existing Prompt Agent with
`AIProjectClient.AsAIAgent(new AgentReference(name, version))`, reading
`FOUNDRY_AGENT_NAME` and `FOUNDRY_AGENT_VERSION`. Do not use classic
`asst_...` IDs or the obsolete persistent-agent adapter.
`ClientSecretCredential` (Azure.Identity 1.21.0) reads `TENANT_ID`, `CLIENT_ID`,
and `CLIENT_SECRET`; no API key or model deployment setting is needed.
Microsoft.Agents.AI.Foundry 1.24.0-preview.261006.1 brings Agent Framework
1.24.0 and Azure.AI.Projects 3.0.0-beta.3 transitively. Reuse one
ChatClientAgentSession from CreateConversationSessionAsync for the capabilities
prompt and interactive chat; history is a server-side conversation, not local storage.
The README documents managed identity and local AzureCliCredential alternatives.

Local `Properties\launchSettings.json` profiles are optional and ignored by
`**/Properties/launchSettings.json` in `.gitignore`. They may contain real API keys: do not
print their contents, embed their values in documentation, or commit them.
When adding a cloud exercise or lab, verify its profile is ignored before
copying local configuration.

Exercises 001, 101-105, 107-109, and the lab 100 solution use OpenAI 2.14.0;
101-105 use Microsoft.Extensions.AI/OpenAI 10.11.0; 107-108 and the lab 100
solution use Microsoft.Agents.AI 1.24.0 with the OpenAI adapter 10.11.0 (the
lab 100 starter still references 107's older 1.0.0/10.4.0/2.9.1 versions).
In 2.14.0, `ResponsesClient` takes `ResponsesClientOptions` (not
`OpenAIClientOptions`) and no model: pass the deployment to
`AsIChatClient(model)`, or set `CreateResponseOptions.Model` when using the
SDK directly (001). Exercise 106 uses OllamaSharp 5.5.0 and its transitive
AI dependencies. Do not change these versions without checking SDK
signatures and runtime compatibility. Responses exercises suppress `OPENAI001`.

Console labels are `[USER]:` and `[ASSISTANT]:`; exercise 104 includes the
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

Current exercise slides are 001 at 14 and 101-109 at 26, 28, 30, 32, 35, 37, 40, 42, 43;
lab 100 is at 45, and exercises 201-205 are at 48, 51, 54, 56, 59.
Lab 200 uses slides 61-63
(`ExerciseBody -badge 'LAB'`, header `LAB 200`); exercises 301-302 use slides
65-66, and lab 300 is at 67 with header `LAB 300`. Section dividers are 64 and 68,
exercises 401-405 use slides 69-73, Lab 400 is at 74, and the closing slide is 75
(75 slides total).
Adding slides requires updating generator
numbering, the shifted SVG outputs, root README headings/image references,
and the deck, as well as slide-count references in tool documentation.

## Part 4 authentication exercises

Exercises 401-404 use the same fictional Secret Snack Stash and tool name
`get_secret_snack`. Keep the programs independent and the use case small.
401 deliberately trusts a model-supplied name; 402 checks public demo credentials
with console `/auth`, creates a fresh agent with userId in its system instructions,
and sends questions unchanged, but still deliberately trusts a model-supplied userId.
403 injects a scoped UserContext into a zero-argument tool. 404 hosts that tool
in a stateless ASP.NET Core MCP server, validates five-minute protected opaque
bearer tokens, and injects request-scoped context derived from validated claims.
Keep credentials and tokens out of agent messages and tool arguments.
Auth attempts and logout reset history; failed reauthentication signs out.
Public demo passwords and loopback HTTP are not production authentication.
404 is not a complete OAuth/OIDC authorization server; do not describe it as one.
No automated authentication-check project is currently included. Follow each
exercise README's manual checks; exercise 404 includes an unauthenticated HTTP
request that needs no Foundry deployment. Build the progression from the root
with `dotnet build .\exercises\exercises.slnx`.
