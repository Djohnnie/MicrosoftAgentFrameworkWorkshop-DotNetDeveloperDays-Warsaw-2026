# Exercise 204 - Microsoft Learn MCP Agent

> **Part:** Part 2, Giving agents capabilities: tools and MCP
> **Focus:** Discover remote tools through MCP and use them in an agent conversation
> **History:** Kept in memory in a reusable `AgentSession`

## What you'll build

This builds on [exercise 203](../exercise-203/README.md)'s Foundry-backed `AIAgent`. Instead of registering local date/time tools, it connects an `McpClient` to the public Microsoft Learn MCP endpoint at `https://learn.microsoft.com/api/mcp`, retrieves the available tools with `ListToolsAsync`, and makes those tools available to the agent.

At startup, the app prints each tool's name and description in plain text so you can see what the server offers. Then ask the agent questions about Microsoft technologies or documentation; it can select and invoke the Learn tools to look up information. The server is public and requires no API key or authentication. Use is subject to the [Microsoft Learn Terms of Use](https://learn.microsoft.com/en-us/legal/termsofuse).

The MCP connection stays open for the agent's conversation and is disposed when the app exits. `DebugHistory` prints tool calls with their IDs and names and tool results with their IDs and results. Tool-list and debug-history entries are normalized to one line and clipped to 180 characters, or to the available console width when running interactively, so large, multiline MCP responses do not flood the console.

## Run it

Use the **.NET 10 SDK**. From this directory:

```powershell
dotnet run
```

Set `FOUNDRY_ENDPOINT`, `FOUNDRY_API_KEY`, and `FOUNDRY_MODEL_DEPLOYMENT` as described in the [Foundry environment-variable setup from exercise 001](../exercise-001/README.md#1-set-your-microsoft-foundry-credentials). An optional, Git-ignored `Properties\launchSettings.json` profile can supply these values; it is not included in a fresh clone. The Microsoft Learn MCP server itself does not require credentials. Network access is needed to connect to the server.

## What changed from exercise 203?

Connect to the remote MCP server using Streamable HTTP, then discover its tools:

```csharp
var transport = new HttpClientTransport(new HttpClientTransportOptions
{
    Endpoint = new Uri("https://learn.microsoft.com/api/mcp"),
    TransportMode = HttpTransportMode.StreamableHttp
});
await using McpClient mcpClient = await McpClient.CreateAsync(transport);
IList<McpClientTool> mcpTools = await mcpClient.ListToolsAsync();
```

Print `Name` and `Description` from each tool so the user can see the available capabilities. Pass the same tool list to the agent:

```csharp
ChatOptions = new ChatOptions
{
    Tools = [.. mcpTools],
    RawRepresentationFactory = _ => new CreateResponseOptions
    {
        StoredOutputEnabled = false
    }
}
```

The MCP C# SDK's `McpClientTool` implements the `AIFunction` abstraction, so the client-discovered tools can be passed directly as agent tools. The agent's function-invocation layer routes selected calls through the live MCP client. As in exercise 203, the chat client is not pre-wrapped with `.UseFunctionInvocation()` so the agent can create that layer. Responses storage is disabled to keep history in the local session.

## Try it

1. Look at the tool names and descriptions printed at startup.
2. Ask: "What is the latest .NET version, and where does Microsoft document it?"
3. Ask a follow-up question using information from the first answer.
4. Watch `DebugHistory` to see the function call and result.
5. Type `quit` to exit.

Learn more in [Microsoft Learn: Using MCP tools with agents](https://learn.microsoft.com/en-us/agent-framework/agents/tools/local-mcp-tools) and the [.NET MCP client quickstart](https://learn.microsoft.com/en-us/dotnet/ai/quickstarts/build-mcp-client).
