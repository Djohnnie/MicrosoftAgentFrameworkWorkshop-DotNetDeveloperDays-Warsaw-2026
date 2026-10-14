# Exercise 102 - Chatbot with History

> **Part:** Part 1, From LLM calls to agents  
> **Focus:** Include earlier user messages and assistant replies in each request  
> **History:** Kept in memory while the application is running

## What you'll build

This is the same `IChatClient` chatbot as [exercise 101](../exercise-101/README.md), with one difference: it keeps the conversation history. A follow-up can now refer to earlier messages because the app sends them along with the new question. The underlying client still uses the Responses API.

The client setup, `OpenAI` SDK version 2.8.0, `Microsoft.Extensions.AI` / `Microsoft.Extensions.AI.OpenAI` version 10.3.0, and `OPENAI001` warning suppression are unchanged. There is no agent yet.

## Run it

From this directory:

```powershell
dotnet run
```

Use the **.NET 10 SDK** and the [Foundry environment-variable setup from exercise 001](../exercise-001/README.md#1-set-your-microsoft-foundry-credentials). An optional, Git-ignored local `Properties\launchSettings.json` profile can supply the same values as exercise 101; it is not included in a fresh clone. Otherwise, set the variables in the same PowerShell session before running.

Type a message and press **Enter**. Type `quit` to exit.

## What changed from exercise 101?

Create a list of `ChatMessage` objects **before** the loop so it survives between turns:

```csharp
List<ChatMessage> history = [];
```

Inside the loop, add the user message, send the accumulated history, and then append the assistant's reply:

```csharp
history.Add(new ChatMessage(ChatRole.User, input));

var response = await chatClient.GetResponseAsync(history);
history.AddRange(response.Messages);

Console.WriteLine($"[ASSISTANT]: {response.Text}");
```

The first request contains one user message. The second contains the first user message, its assistant reply, and the new user message. Both sides of the conversation matter: a follow-up might refer to something in the assistant's previous answer. `AddRange(response.Messages)` retains the returned messages rather than reconstructing them from text.

This is application-managed history, not permanent model memory. The full history is sent again on each request; no previous response ID is used. Restarting the app discards it. As the conversation grows, input token usage grows too, and long conversations can eventually exceed the model's context limit.

The code stays intentionally simple: no history trimming, persistence, reset command, or request error recovery. Missing configuration and request failures propagate as exceptions.

## Try it

1. Say: "My name is Alex, and I am learning C#."
2. Ask: "What is my name, and what am I learning?"
3. Ask for an explanation, then follow up with "Can you explain that more simply?"
4. Compare with exercise 101, then restart this app and notice that the earlier conversation is gone.

Next: [Exercise 103 - Chatbot Personas](../exercise-103/README.md) adds a system prompt to guide the chatbot's tone and style.
