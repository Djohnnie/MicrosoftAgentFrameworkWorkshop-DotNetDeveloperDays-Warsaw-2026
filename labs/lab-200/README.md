# Lab 200 - DevDays Buddy: MCP Conference Tools

> **Part:** Part 2, Giving agents capabilities: tools and MCP  
> **Focus:** Move the agenda from agent context into a separate MCP server  
> **Builds on:** [Lab 100 - DevDays Buddy](../lab-100/README.md) and [Exercise 205 - Host Date and Time Tools with MCP](../../exercises/exercise-205/README.md)

## What you'll build

Extend DevDays Buddy from Lab 100 with a separate ASP.NET Core MCP server and a console agent client. The server embeds `agenda.json` and exposes focused tools to retrieve conference details, dates, speakers, and sessions. The console client discovers those tools, provides them to a Foundry-backed `AIAgent`, and uses a reusable `AgentSession` and Spectre.Console interface.

Unlike Lab 100, the client does **not** load the agenda or place the full JSON in the agent's instructions. The server reads the embedded file once at startup. When the model selects a tool, the server returns only the requested information. The client still sends conversation history and tool results to the model, but not the complete agenda on every request.

The speaker and session lookups use deterministic text matching and return clarification messages for ambiguous results. As an optional extension, you can add a second LLM-backed agent on the server to interpret misspelled or vague names and titles. That adds a separate Foundry configuration and inference call on the server.

## Projects

| Folder | Projects | Purpose |
| --- | --- | --- |
| [`starter`](starter) | `server` and `client` | Embedded agenda, package references, and TODOs for both sides of MCP. |
| [`solution`](solution) | `server` and `client` | One possible implementation of the MCP tools and agent client. |

All four projects are included in [`labs\labs.slnx`](../labs.slnx), separate from the exercises solution. The server and client target **.NET 10**. The server uses `ModelContextProtocol.AspNetCore` 1.4.1; the client uses Microsoft.Agents.AI 1.24.0, OpenAI 2.14.0, Microsoft.Extensions.AI.OpenAI 10.11.0, ModelContextProtocol 1.4.1, and Spectre.Console 0.57.2.

## MCP tool contract

Build each tool in the server and annotate it with the MCP C# SDK's `[McpServerTool]` and `[Description]` attributes:

| Tool | Purpose |
| --- | --- |
| `get_conference_info` | Return the conference name, description, format, venue, and time zone. |
| `get_conference_dates` | Return the workshop date and conference dates. |
| `get_speakers` | List distinct speakers in the agenda. |
| `get_speaker_details` | Find a speaker by first name, last name, or full name; include their profile and sessions. |
| `get_sessions_for_date` | List sessions for a date (`yyyy-MM-dd`) or weekday. Breaks are excluded. |
| `get_session_details` | Return details by a partial title, or by a date and exact start time. |

If a name matches multiple speakers or a title matches multiple sessions, return the candidates and ask the agent to clarify. Do not silently pick one. If a lookup finds nothing, return a concise message explaining how to refine it. Conference dates are in the agenda's local Warsaw time.

The MCP server loads `agenda.json` as an embedded resource, deserializes it once, and uses an agenda repository for lookups. Register the repository with ASP.NET Core dependency injection, then register the annotated tool class with `AddMcpServer().WithHttpTransport().WithTools<ConferenceTools>()`. Map the MCP endpoint at `/mcp`.

The console client connects to `http://localhost:5286/mcp` using Streamable HTTP and calls `ListToolsAsync`. Give the discovered tools to the agent through `ChatOptions.Tools`. Use short agent instructions that direct it to the tools; **do not read or embed `agenda.json` in the client**.

## Your task

Work in [`starter`](starter) and follow these steps. Compare with [`solution`](solution) after trying each part.

### 1. Build the MCP server

1. Read `agenda.json` from the executing assembly's manifest resources. Use the fixed logical resource name `agenda.json` and `JsonSerializerOptions.Web`.
2. Define models for the conference, its dates and venue, agenda items, and speakers. Account for break entries, which do not have speaker data.
3. Add an `AgendaRepository` that loads and validates the embedded document once and provides queries for speakers and non-break sessions.
4. Create the six tools in the MCP tool contract. Make name and title matching case-insensitive and support partial first/last names and session titles.
5. Return helpful no-match and ambiguous-match results. Include session date, time, room, level, description, and speakers in session details.
6. Register the repository and tool class with DI; map the Streamable HTTP server at `http://localhost:5286/mcp`.

### 2. Build the console agent

1. Read `FOUNDRY_ENDPOINT`, `FOUNDRY_API_KEY`, and `FOUNDRY_MODEL_DEPLOYMENT` from the environment, following the [Foundry setup in Exercise 001](../../exercises/exercise-001/README.md#1-set-your-microsoft-foundry-credentials).
2. Connect to the local MCP endpoint and list the available tools.
3. Build a Foundry Responses client and an `AIAgent`. Pass the discovered MCP tools to `ChatOptions.Tools`; keep agent instructions short and do not add the agenda JSON.
4. Use `InMemoryChatHistoryProvider` with one `AgentSession`. Set `CreateResponseOptions.StoredOutputEnabled = false` so server-side Responses history does not conflict with the local session.
5. Add a console loop with `/quit` handling and a Spectre.Console banner, tool list, status spinner, and answer panel. Handle `/debug` locally to print the actual session history in a colored table, distinguishing message roles, function calls (call ID, name, and arguments), and function results (call ID and result). Keep the MCP client alive for the entire conversation.

## Run it

Use the **.NET 10 SDK** and two PowerShell terminals at the repository root. Set the Foundry environment variables in the client terminal. The MCP server itself does not need Foundry credentials.

In the first terminal, start the server:

```powershell
dotnet run --project .\labs\lab-200\solution\server\DevDaysBuddy.McpServer.csproj
```

It listens at `http://localhost:5286/mcp`. Keep it running.

In the second terminal, start the console client:

```powershell
dotnet run --project .\labs\lab-200\solution\client\DevDaysBuddy.McpClient.csproj
```

The starter projects are scaffolds and will not provide working MCP tools until you complete their TODOs. A fresh clone has no local Foundry credentials; use the environment variables or a local ignored launch profile.

## Try it

1. Ask: "What is the conference name and where is it held?"
2. Ask: "Which speakers are there?"
3. Ask: "Tell me about Richard Campbell." If that name is ambiguous in the agenda, clarify using the candidates returned by the tool.
4. Ask: "What sessions are on Wednesday, October 21?"
5. Ask: "Tell me about the session that starts at 10:30 on Tuesday."
6. Ask for a session by a distinctive phrase from its title, then try a vague title that matches more than one session.
7. Type `/debug` to inspect the conversation history and MCP tool calls and results. This command does not call the model.
8. Type `/quit` to exit, then stop the server with Ctrl+C. Commands are case-insensitive; the original `quit` command still works.

## Going further

- Add `get_sessions_by_speaker` or `get_sessions_in_room` as focused tools.
- Return structured tool output instead of formatted text and let the agent present it.
- Add deterministic edit-distance matching for misspellings, or build a separate LLM-backed matching agent on the server. Compare accuracy, latency, cost, and ambiguity handling.
- Compare the amount of agenda data sent to the model with Lab 100. Here, only selected tool results are added to the conversation.

The agenda is a workshop snapshot, not a live feed. Check the [official conference agenda](https://developerdays.eu/warsaw/conference/) for changes.
