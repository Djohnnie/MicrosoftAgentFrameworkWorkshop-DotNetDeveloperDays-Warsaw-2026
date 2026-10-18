# Exercise 103 - Chatbot with Token Usage

> **Part:** Part 1, From LLM calls to agents\
> **Focus:** Display API-reported input and output tokens after each request\
> **History:** Kept in memory while the application is running

## What you'll build

This is [exercise 102](../exercise-102/README.md)'s chatbot with history, with two extra console lines after each reply. They display the input and output token counts returned by the API through `response.Usage`, not estimates from a local tokenizer.

The `ResponsesClient` setup, `IChatClient` adapter, `List<ChatMessage>` history, and conversation loop are unchanged. The packages remain OpenAI 2.14.0 and Microsoft.Extensions.AI / Microsoft.Extensions.AI.OpenAI 10.11.0, with `OPENAI001` suppressed. There is no Agent Framework agent yet.

## Run it

From this directory:

```powershell
dotnet run
```

Or, from the repository root:

```powershell
dotnet run --project .\exercises\exercise-103\ChatbotWithTokenUsage.csproj
```

Use the **.NET 10 SDK** and the [Foundry environment-variable setup from exercise 001](../exercise-001/README.md#1-set-your-microsoft-foundry-credentials): `FOUNDRY_ENDPOINT`, `FOUNDRY_API_KEY`, and `FOUNDRY_MODEL_DEPLOYMENT`. An optional, Git-ignored `Properties\launchSettings.json` profile can supply the same values as exercise 102; it is not included in a fresh clone. Otherwise, set the variables in the same PowerShell session before running.

Type a message and press **Enter**. Blank input is skipped. Type `quit` (case-insensitive) or send EOF to exit.

## What changed from exercise 102?

Keep the request and history handling, then print the API usage after the answer:

```csharp
var response = await chatClient.GetResponseAsync(history);
history.AddRange(response.Messages);

Console.WriteLine($"[ASSISTANT]: {response.Text}");
Console.WriteLine($"[USAGE]: Input tokens: {response.Usage?.InputTokenCount?.ToString() ?? "not reported"}");
Console.WriteLine($"[USAGE]: Output tokens: {response.Usage?.OutputTokenCount?.ToString() ?? "not reported"}");
```

These counts belong to **the request that just completed**, not a cumulative session total. Input tokens include the conversation history sent with that request, not just the latest prompt. Output tokens can include hidden reasoning tokens on reasoning-capable models; the API-reported total is more authoritative than counting the visible reply. Cached input is still part of the reported input count.

If the API does not report a count, the console explicitly displays `not reported` rather than inventing a zero or a local estimate. Token counts are not monetary cost; input, cached input, and output may have different prices.

As in exercise 102, restarting discards history. There is no history trimming, persistence, reset command, or request error recovery. Missing configuration and request failures propagate as exceptions.

## Try it

1. Say: "My name is Alex, and I am learning C#." Read the two usage lines after the reply.
2. Ask: "What is my name, and what am I learning?" Notice that the request includes the earlier conversation.
3. Ask for a short answer, then a longer explanation. Compare output token counts; reasoning can affect them too.
4. Restart the app and compare the first request with a longer conversation. Counts depend on the deployment and actual API response.

Next: [Exercise 104 - Chatbot Personas](../exercise-104/README.md) adds a changing system instruction to exercise 102's history loop.
