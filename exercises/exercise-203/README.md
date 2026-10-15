# Exercise 203 - Dependency Injection for Agent Tools

> **Part:** Part 2, Giving agents capabilities: tools and MCP
> **Focus:** Resolve a tool dependency from the agent's service provider
> **History:** Kept in memory in a reusable `AgentSession`

## What you'll build

This builds on [exercise 201](../exercise-201/README.md)'s Foundry-backed `AIAgent` and date/time tools. Instead of reading the system clock directly, each tool accepts an `IServiceProvider` and resolves the registered `TimeProvider` dependency when the tool runs.

The app registers `TimeProvider.System` in a .NET dependency-injection container and passes that container to `AsAIAgent`. The agent's function-invocation layer supplies the provider to the tool. `IServiceProvider` is invocation context, not a model argument, so it does not appear in the tool's JSON schema.

## Run it

From this directory:

```powershell
dotnet run
```

Use the **.NET 10 SDK** and the [Foundry environment-variable setup from exercise 001](../exercise-001/README.md#1-set-your-microsoft-foundry-credentials). An optional, Git-ignored local `Properties\launchSettings.json` profile can supply `FOUNDRY_ENDPOINT`, `FOUNDRY_API_KEY`, and `FOUNDRY_MODEL_DEPLOYMENT`; it is not included in a fresh clone. Otherwise, set the variables in the same PowerShell session before running.

Ask for the current date or time, then type `quit` to exit.

## What changed from exercise 201?

Register the dependency the tool needs and build a service provider:

```csharp
using ServiceProvider services = new ServiceCollection()
    .AddSingleton<TimeProvider>(TimeProvider.System)
    .BuildServiceProvider();
```

The tool receives `IServiceProvider` and resolves `TimeProvider` from it:

```csharp
public static string GetCurrentTime(IServiceProvider services)
{
    TimeProvider timeProvider = services.GetRequiredService<TimeProvider>();
    DateTimeOffset localNow = timeProvider.GetLocalNow();
    return localNow.ToString("HH:mm:ss zzz");
}
```

Create the tool as before, but do not add `.UseFunctionInvocation()` to the chat-client pipeline. Pass the provider into `AsAIAgent`; the agent then creates the function-invocation layer with that provider:

```csharp
AIAgent agent = chatClient.AsAIAgent(
    new ChatClientAgentOptions
    {
        ChatHistoryProvider = new InMemoryChatHistoryProvider(),
        ChatOptions = new ChatOptions
        {
            Tools = [getCurrentTime, getCurrentDate],
            RawRepresentationFactory = _ => new CreateResponseOptions
            {
                StoredOutputEnabled = false
            }
        }
    },
    services: services);
```

The provider lets the function-invocation layer supply registered services to `AIFunction` methods that request an `IServiceProvider`. With `.UseFunctionInvocation()` already installed on the client, the agent would not create that layer, so the `AsAIAgent` provider would not be the one used for tool invocation.

`StoredOutputEnabled = false` keeps conversation history in the local `AgentSession`; it prevents the Responses API from returning a server-side conversation ID that would conflict with `InMemoryChatHistoryProvider`.

After every reply, `DebugHistory` inspects and prints the actual content stored in the in-memory session: function calls show their `CallId` and `Name`, and function results show their `CallId` and `Result`.

## Try it

1. Ask: "What time is it where this app is running?"
2. Ask: "What is today's date?"
3. Replace `TimeProvider.System` with a fixed or custom `TimeProvider` and observe how the tool's result changes without editing the tool method.
4. Compare this with exercise 201, where the tool reads the system clock directly.
