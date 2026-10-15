# Exercise 205 - Host Date and Time Tools with MCP

> **Part:** Part 2, Giving agents capabilities: tools and MCP  
> **Focus:** Host tools in an ASP.NET Core MCP server and call them from a separate console agent  
> **Projects:** `server\DateTimeMcpServer.csproj` and `client\ChatbotAgentWithMcpServer.csproj`

## What you'll build

This builds on [exercise 201](../exercise-201/README.md)'s current-date and current-time tools and [exercise 204](../exercise-204/README.md)'s MCP client. Instead of creating `AIFunction` tools in the same process as the agent, expose the date and time methods from an ASP.NET Core MCP server. A separate console project connects to the server, discovers its tools, and gives them to a Foundry-backed `AIAgent`.

The server uses the MCP C# SDK's ASP.NET Core integration: it registers the annotated `DateTimeTools` class, enables HTTP transport, and maps the MCP endpoint at `/mcp`. `DateTimeTools` receives `TimeProvider` through constructor injection; the server registers `TimeProvider.System` in ASP.NET Core's service container. The client uses Streamable HTTP at `http://localhost:5285/mcp`. The server must stay running while the client is in use.

## Run it

Use the **.NET 10 SDK**. Open two PowerShell terminals at the repository root.

In the first terminal, start the MCP server:

```powershell
dotnet run --project .\exercises\exercise-205\server\DateTimeMcpServer.csproj
```

Keep it running. It listens at `http://localhost:5285`.

In the second terminal, configure the Foundry environment variables as described in the [exercise 001 setup](../exercise-001/README.md#1-set-your-microsoft-foundry-credentials), then start the console client:

```powershell
dotnet run --project .\exercises\exercise-205\client\ChatbotAgentWithMcpServer.csproj
```

The console client prints the MCP tools discovered from the server. Ask for the current date or time, then type `quit` to exit. Stop the server with Ctrl+C. An optional, Git-ignored client `Properties\launchSettings.json` profile can supply Foundry variables; it is not included in a fresh clone.

## What changed from exercise 204?

Exercise 204 connected to a public, already-running Microsoft Learn MCP server. Here, the workshop provides both sides:

- **Server:** `DateTimeTools` exposes `get_current_time` and `get_current_date` as MCP tools. ASP.NET Core's service container injects its registered `TimeProvider` into the tool class. `AddMcpServer().WithHttpTransport().WithTools<DateTimeTools>()` registers the tools, and `MapMcp("/mcp")` publishes the endpoint.
- **Client:** `HttpClientTransport` connects to the local endpoint, and `McpClient.ListToolsAsync()` discovers its tools. The discovered tools are passed to the agent just like exercise 204.

The tools use `TimeProvider.GetLocalNow()` to return the local time with its UTC offset and the local date in `ddd yyyy-MM-dd` format. This keeps the clock dependency explicit and replaceable for testing. They read the clock of the machine running the server. The server itself does not need Foundry credentials; only the console client needs them for model inference.

The MCP HTTP transport follows the separate server/client pattern in the [reference repository's `AgentFramework.McpSseServer` and `AgentFramework.McpSseClient`](https://github.com/Djohnnie/EnableGenAIUsingTheMicrosoftAgentFramework-IlionxDevDays-2026). This exercise uses the current Streamable HTTP transport on an explicit `/mcp` route.

## Try it

1. Start the ASP.NET server and confirm it reports listening on port 5285.
2. Start the client and inspect the tool names and descriptions it discovers.
3. Ask: "What time is it where the MCP server is running?"
4. Ask: "What is today's date there?"
5. Inspect `DebugHistory` for the tool call and result, then type `quit`.

Learn more in [Microsoft Learn: Using MCP tools with agents](https://learn.microsoft.com/en-us/agent-framework/agents/tools/local-mcp-tools) and the [.NET MCP server quickstart](https://learn.microsoft.com/en-us/dotnet/ai/quickstarts/build-mcp-server).
