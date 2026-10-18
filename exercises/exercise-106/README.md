# Exercise 106 - Local Ollama Chatbot

> **Part:** Part 1, From LLM calls to agents\
> **Focus:** Swap the model provider without changing the chat loop\
> **History:** Kept in memory while the application is running

## What you'll build

This is [exercise 102](../exercise-102/README.md)'s chatbot with history, using a local **Ollama** model instead of Microsoft Foundry. The model is **`qwen2.5:7b`**, and Ollama runs at **`http://localhost:11434`**.

`OllamaApiClient` implements `IChatClient`, so the `ChatMessage` history, `GetResponseAsync`, and `response.Messages` work exactly as before. No Agent Framework agent is involved.

## Set up Ollama

1. Install [Ollama](https://ollama.com/download) on your machine.
2. Ensure Ollama is running. The desktop application normally starts the server; if it is not running, run `ollama serve` in a separate terminal. Do not start a second server if one is already listening on port 11434.
3. Download the model:

```powershell
ollama pull qwen2.5:7b
```

The download requires internet access and several gigabytes of disk space. Running a 7B model also requires sufficient memory; response speed depends on your hardware.

You can check the server and installed models with:

```powershell
Invoke-RestMethod http://localhost:11434/api/tags
```

## Run it

Use the **.NET 10 SDK**, as in the earlier exercises.

From this directory:

```powershell
dotnet run
```

Type a message and press **Enter**. Type `quit` to exit.

No Foundry credentials, environment variables, or `launchSettings.json` are needed. The local URL and model name are hard-coded to keep the exercise simple. Once the model is downloaded, inference takes place on your machine.

## What changed from exercise 102?

Replace the Foundry configuration and Responses client adapter with:

```csharp
using IChatClient chatClient = new OllamaApiClient(
    new Uri("http://localhost:11434"), "qwen2.5:7b");
```

`OllamaSharp` 5.5.0 is the only package reference; it includes the Microsoft.Extensions.AI dependencies. There is no OpenAI SDK dependency or `OPENAI001` warning to suppress.

The conversation code stays the same:

```csharp
history.Add(new ChatMessage(ChatRole.User, input));

var response = await chatClient.GetResponseAsync(history);
history.AddRange(response.Messages);

Console.WriteLine($"[ASSISTANT]: {response.Text}");
```

History is application-managed and sent on every request. Restarting the app discards it. The local model has a finite context window too; this exercise does not trim or persist history. Connection errors, a missing model, and inference failures propagate as exceptions rather than falling back to a cloud model.

## Try it

1. Say "My name is Alex, and I am learning C#."
2. Ask "What is my name, and what am I learning?"
3. Compare the answers and response speed with exercise 102.
4. Notice that changing the provider did not require changing the conversation loop.

Read [Microsoft Learn: Chat with a local AI model](https://learn.microsoft.com/en-us/dotnet/ai/quickstarts/chat-local-model).
