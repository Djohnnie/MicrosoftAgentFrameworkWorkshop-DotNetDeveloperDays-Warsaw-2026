# Exercise 103 - Chatbot Personas

> **Part:** Part 1, From LLM calls to agents  
> **Focus:** Change the chatbot's age persona with a system prompt on each turn  
> **History:** Kept in memory, including the system message

## What you'll build

Start with [exercise 102](../exercise-102/README.md)'s chatbot with history and give it a changing persona. The first reply is from a curious, cheerful 10-year-old; subsequent replies use ages **8, 6, 4, 2, 0**, then stay at **0**. A **system message** guides the model's behavior for the current age.

The `IChatClient` setup, `OpenAI` SDK version 2.14.0, `Microsoft.Extensions.AI` / `Microsoft.Extensions.AI.OpenAI` version 10.11.0, `OPENAI001` warning suppression, and conversation loop stay the same. The adapter still calls the Responses API. There is no Agent Framework agent yet.

## Run it

From this directory:

```powershell
dotnet run
```

Use the **.NET 10 SDK** and the [Foundry environment-variable setup from exercise 001](../exercise-001/README.md#1-set-your-microsoft-foundry-credentials). An optional, Git-ignored local `Properties\launchSettings.json` profile can supply the same values as exercise 102; it is not included in a fresh clone. Otherwise, set the variables in the same PowerShell session before running.

Type a message and press **Enter**. Type `quit` to exit.

## What changed from exercise 102?

Define the persona in a hard-coded template and add it as the first `ChatMessage` in the history, before the conversation loop. `{0}` is replaced with the current age:

```csharp
var age = 10;
const string systemPrompt = """
    Play the role of a curious, cheerful child aged {0}.
    Match your vocabulary and understanding to your current age, even if earlier replies sounded older.
    At age 0, role-play a baby using only short babbling sounds.
    If you do not know something, say so instead of making it up.
    """;

List<ChatMessage> history =
[
    new(ChatRole.System, string.Format(systemPrompt, age))
];
```

Before adding each user message, replace the first item with the current persona:

```csharp
history[0] = new ChatMessage(ChatRole.System, string.Format(systemPrompt, age));
```

After printing the reply, decrease the age without going below zero:

```csharp
age = Math.Max(0, age - 2);
```

A **system message** sets instructions for the conversation. A **user message** supplies the current question, and an **assistant message** records the model's reply. `GetResponseAsync(history)` sends these messages, and `history.AddRange(response.Messages)` retains the returned messages. Replacing the system message avoids accumulating conflicting age instructions. The user and assistant history remains intact. Blank input and `quit` do not advance the age; each successful reply does. At zero, the persona babbles rather than answering normally.

The persona changes the intended tone and style, not the model itself. The chatbot is role-playing, not actually a child. Instructions guide the model but do not guarantee that every answer follows them or is factually correct.

As in exercise 102, history exists only while the app runs. Restarting clears the conversation and resets the age to 10. Full history is sent on every request, so input token usage grows with the conversation. Configuration and request failures propagate as exceptions to keep the code simple.

## Try it

1. Ask "What is a black hole?" and compare the response with exercise 102.
2. Repeat the question and observe the age labels: 10, 8, 6, 4, 2, 0, 0.
3. Try follow-ups to observe the changing persona and retained history together.
4. Restart the app to return to age 10. Compare vocabulary, tone, and detail without changing the model deployment.
