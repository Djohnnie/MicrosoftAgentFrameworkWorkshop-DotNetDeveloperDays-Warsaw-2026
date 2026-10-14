# Exercise 106 - Chatbot Agent

> **Part:** Part 1, From LLM calls to agents  
> **Focus:** Create an agent with instructions and a conversation session  
> **History:** Retained by reusing the same session while the application is running

## What you'll build

The final exercise of Part 1 moves from direct `IChatClient` calls to a Microsoft Agent Framework `AIAgent`. It uses the same Foundry endpoint, API key, and model as exercises 101-104, gives the agent a cheerful 10-year-old persona, and keeps conversation context across questions.

Unlike exercise 103, the age stays at 10. The focus here is the agent concept, not changing the instructions on every turn. There are no tools or workflows yet.

## Run it

From this directory:

```powershell
dotnet run
```

Use the **.NET 10 SDK** and the [Foundry environment-variable setup from exercise 001](../exercise-001/README.md#1-set-your-microsoft-foundry-credentials). An optional, Git-ignored local `Properties\launchSettings.json` profile can supply these values; it is not included in a fresh clone. Otherwise, set the variables in the same PowerShell session before running. Never commit your API key.

Type a message and press **Enter**. Type `quit` to exit.

## Create an agent

Keep the existing `ResponsesClient` and its `IChatClient` adapter, then wrap it in an agent:

```csharp
AIAgent agent = chatClient.AsAIAgent(new ChatClientAgentOptions
{
    Name = "ChildAgent",
    ChatHistoryProvider = new InMemoryChatHistoryProvider(),
    ChatOptions = new ChatOptions
    {
        Instructions = """
            Play the role of a curious, cheerful 10-year-old.
            Use simple words, short answers, and playful examples.
            If you do not know something, say so instead of making it up.
            """,
        RawRepresentationFactory = _ => new CreateResponseOptions
        {
            StoredOutputEnabled = false
        }
    }
});
```

The program uses the `ChatClientAgentOptions` overload to also select `InMemoryChatHistoryProvider` and set `ChatOptions.Instructions`. `RawRepresentationFactory` creates Responses API options with `StoredOutputEnabled = false`, disabling stored responses and server-side response chaining for this demo.

`Microsoft.Agents.AI` supplies the agent abstraction. The underlying `IChatClient` still communicates with the same model; `AsAIAgent` does not train a new model or deploy a hosted agent. The name identifies the agent, and the instructions guide its behavior, much like the system prompt in exercise 103. Instructions do not guarantee accurate answers.

This exercise pins the stable Agent Framework 1.0.0 release and uses the compatible Microsoft.Extensions.AI.OpenAI 10.4.0 adapter with OpenAI 2.9.1. Agent Framework brings in Microsoft.Extensions.AI 10.4.0 transitively. This SDK version passes the model to `AsIChatClient(model)` instead of the `ResponsesClient` constructor; the endpoint and API-key authentication stay unchanged. `OPENAI001` is still suppressed for the experimental Responses API.

## Let the session retain conversation context

Create one session **before** the loop:

```csharp
AgentSession session = await agent.CreateSessionAsync();
```

Reuse it for each question:

```csharp
var response = await agent.RunAsync(input, session);
Console.WriteLine($"[ASSISTANT]: {response.Text}");
DebugHistory(session);
```

Unlike exercise 102, application code no longer appends messages to a `List<ChatMessage>`. The agent manages conversation state through the session, including earlier user messages and assistant replies. Creating a new session for every question would lose that context.

The session is not permanent model memory. This exercise explicitly uses `InMemoryChatHistoryProvider`, which stores messages inside `AgentSession.StateBag` in the application's memory. Stored Responses API output is disabled, so the conversation is sent again with each request rather than continued through a server-side response ID. This does not make inference local: messages are still sent to Foundry for each model call. This exercise does not save or restore the session, so restarting the app starts a new conversation. Longer conversations still consume context and tokens.

## Inspect the history in memory

After every reply, `DebugHistory(session)` reads the actual session state using `session.TryGetInMemoryChatHistory(out var messages)`. It prints the message count, roles, and full text in order, without making another model call or maintaining a separate debug copy.

After the first question you can see the user message and assistant reply. After the second question you can see both turns still present. The persona instructions are configured separately in `ChatOptions.Instructions`, not as a user/assistant turn in the history.

```text
--- DEBUG: AgentSession local in-memory history ---
Stored messages: 4
  1. [user]: My name is Alex.
  2. [assistant]: Hi Alex!
  3. [user]: What is my name?
  4. [assistant]: Your name is Alex!
--- END HISTORY ---
```

Replies and message counts can vary with the model's output. Set a breakpoint inside `DebugHistory` to inspect `session.StateBag` and `messages` in the debugger. The method only reads the history; the agent still stores it automatically. This teaching-only output exposes the entire conversation, so avoid entering sensitive information and remove it before using the app in production.

The program stays intentionally simple: no persistence, history trimming, tools, or request error recovery. Missing configuration and request failures propagate as exceptions.

## Try it

1. Say: "My name is Alex, and I am learning C#."
2. Ask: "What is my name, and what am I learning?"
3. Ask: "Explain how a computer remembers things." Notice the simple language and playful examples.
4. Compare the manual history in exercise 102 and system prompt in exercise 103 with the agent's session and instructions.
5. Restart the app and ask about your name again.

See Microsoft Learn's [Your First Agent](https://learn.microsoft.com/en-us/agent-framework/get-started/your-first-agent?pivots=programming-language-csharp) and [Conversations & Memory](https://learn.microsoft.com/en-us/agent-framework/concepts/agents/conversations/?pivots=programming-language-csharp). We keep API-key authentication through the existing `IChatClient` instead of switching to the guide's `AIProjectClient` and Microsoft Entra authentication.
