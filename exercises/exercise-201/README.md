# Exercise 201 - Chatbot Agent with Tools

> **Part:** Part 2, Giving agents capabilities: tools and MCP  
> **Focus:** Let the model call C# functions to get the current local time or date  
> **History:** Kept in memory while the application is running

## What you'll build

This builds on [exercise 107](../exercise-107/README.md): it uses the same Foundry Responses client and wraps its `IChatClient` in an `AIAgent`, then adds two tools. `get_current_time` returns the computer's local time and UTC offset; `get_current_date` returns its local date with the weekday, formatted as `ddd yyyy-MM-dd` (for example, `Thu 2026-10-15`).

The model decides whether to call either tool. `UseFunctionInvocation()` executes the selected C# function and returns its result to the model, which can then answer the user. An `InMemoryChatHistoryProvider` stores the conversation in a single `AgentSession` reused for each `RunAsync` call. The tools read the machine running this app, not a timezone or date supplied by the user.

It uses Microsoft.Agents.AI 1.24.0, OpenAI 2.14.0, and Microsoft.Extensions.AI / Microsoft.Extensions.AI.OpenAI 10.11.0, matching the SDK versions used in exercise 107.

## Run it

From this directory:

```powershell
dotnet run
```

Use the **.NET 10 SDK** and the [Foundry environment-variable setup from exercise 001](../exercise-001/README.md#1-set-your-microsoft-foundry-credentials). An optional, Git-ignored local `Properties\launchSettings.json` profile can supply `FOUNDRY_ENDPOINT`, `FOUNDRY_API_KEY`, and `FOUNDRY_MODEL_DEPLOYMENT`; it is not included in a fresh clone. Otherwise, set the variables in the same PowerShell session before running.

Ask for the current date or time, then type `quit` to exit.

## What changed from exercise 107?

Keep the tool implementations and their metadata in a separate `DateTimeTools` class. Add `[AIFunctionName]` for the name exposed to the model and `[Description]` from `System.ComponentModel` for the description. The date tool formats its value with the weekday followed by the ISO date:

```csharp
[AIFunctionName("get_current_time")]
[Description("Get the current local time, including the UTC offset.")]
public static string GetCurrentTime() =>
    DateTimeOffset.Now.ToString("HH:mm:ss zzz");

[AIFunctionName("get_current_date")]
[Description("Get the current local date with its weekday, formatted as ddd yyyy-MM-dd.")]
public static string GetCurrentDate() =>
    DateTime.Now.ToString("ddd yyyy-MM-dd");
```

`Program.cs` sets up the chat client, registers the methods, and makes them available to the agent through its `ChatOptions`. `AIFunctionFactory.Create` reads the metadata from their attributes:

```csharp
var getCurrentTime = AIFunctionFactory.Create(DateTimeTools.GetCurrentTime);
var getCurrentDate = AIFunctionFactory.Create(DateTimeTools.GetCurrentDate);
```

Make both functions available through `ChatOptions.Tools`.

`AIFunctionName` is experimental in Microsoft.Extensions.AI 10.11.0, so `DateTimeTools.cs` suppresses `MEAI001` for this attribute.

`UseFunctionInvocation()` enables the chat client to run a function when the model requests it. The `ChatClientAgentOptions` supplies the tools, and the agent session retains the conversation:

```csharp
AIAgent agent = chatClient.AsAIAgent(new ChatClientAgentOptions
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
});
AgentSession session = await agent.CreateSessionAsync();

var response = await agent.RunAsync(input, session);
```

The agent handles the conversation history and tool-call flow; the application does not need a separate history list or a separate conversation loop for each tool. `StoredOutputEnabled = false` keeps history in the local `AgentSession` rather than using Foundry's server-side conversation state, which cannot be combined with an `InMemoryChatHistoryProvider`. After each reply, `DebugHistory` prints the session's actual content: function calls are labeled with their `CallId` and `Name`, and function results with their `CallId` and `Result`.

## Try it

1. Ask: "What time is it where this app is running?"
2. Ask: "What is today's date?"
3. Ask for both the date and time, then follow up with "What time zone is that?"
4. Compare the answer with the clock and calendar on the computer running the app.

The model chooses when to call the tools, so phrasing matters. The functions provide current values; they do not guarantee that the model will call a tool unless the request makes the need clear.
