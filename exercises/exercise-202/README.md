# Exercise 202 - Local Chatbot with Tools

> **Part:** Part 2, Giving agents capabilities: tools and MCP
> **Focus:** Let a local model call C# functions for the current local time or date
> **History:** Kept in memory while the application is running

## What you'll build

This is [exercise 201](../exercise-201/README.md)'s tool-enabled chatbot using a local **Ollama** model instead of Microsoft Foundry. It uses the same `qwen2.5:7b` model and Ollama server as [exercise 106](../exercise-106/README.md), at `http://localhost:11434`.

The model can call `get_current_time` and `get_current_date`. `UseFunctionInvocation()` executes the selected C# function, and its result is returned to the model so it can answer the user. The tools read the computer running this app, not a timezone or date supplied by the user.

The agent and tool setup match exercise 201. `OllamaApiClient` supplies the `IChatClient`; no Foundry credentials or cloud service are needed. An `InMemoryChatHistoryProvider` retains the conversation in an `AgentSession` reused for each turn.

## Set up Ollama

1. Install [Ollama](https://ollama.com/download) on your machine.
2. Ensure Ollama is running. The desktop application normally starts the server; if it is not running, run `ollama serve` in a separate terminal. Do not start a second server if one is already listening on port 11434.
3. Download the model:

```powershell
ollama pull qwen2.5:7b
```

The download requires internet access and several gigabytes of disk space. Running a 7B model also requires sufficient memory; response speed depends on your hardware.

## Run it

Use the **.NET 10 SDK**. From this directory:

```powershell
dotnet run
```

Ask for the current date or time, then type `quit` to exit. The model chooses when to call the tools, so phrase requests clearly. Inference and function invocation run through Ollama on your machine.

## What changed from exercise 201?

Replace the Foundry client and its configuration with the local client from exercise 106:

```csharp
IChatClient ollamaClient = new OllamaApiClient(
    new Uri("http://localhost:11434"), "qwen2.5:7b");

using IChatClient chatClient = ollamaClient
    .AsBuilder()
    .UseFunctionInvocation()
    .Build();
```

Keep the `DateTimeTools` functions and create an `AIAgent` with the two tools in `ChatClientAgentOptions`. Create one `AgentSession` and pass it to `RunAsync` for each turn:

```csharp
AIAgent agent = chatClient.AsAIAgent(new ChatClientAgentOptions
{
    ChatHistoryProvider = new InMemoryChatHistoryProvider(),
    ChatOptions = new ChatOptions { Tools = [getCurrentTime, getCurrentDate] }
});
AgentSession session = await agent.CreateSessionAsync();

var response = await agent.RunAsync(input, session);
```

`OllamaSharp` 5.5.0 provides the local model client; Microsoft.Agents.AI 1.24.0 supplies the agent API. No OpenAI SDK dependency or `OPENAI001` warning suppression is needed.

The session's history is kept in memory and is discarded when the app exits. `DebugHistory` prints the actual stored content after each reply: function calls show their `CallId` and `Name`, and function results show their `CallId` and `Result`. Connection errors, a missing model, and inference failures propagate as exceptions rather than falling back to a cloud model.

## Try it

1. Ask: "What time is it where this app is running?"
2. Ask: "What is today's date?"
3. Ask for both the date and time, then follow up with "What time zone is that?"
4. Compare the answers with the computer's clock and calendar.
