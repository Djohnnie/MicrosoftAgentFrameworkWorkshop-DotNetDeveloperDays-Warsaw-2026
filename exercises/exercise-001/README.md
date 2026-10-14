# Exercise 001 — Token Visualizer

> **Section:** Introduction to GenAI, Exercise 001\
> **Skill focus:** Understanding how LLMs tokenise text; exploring Microsoft Foundry's Responses API  
> **Difficulty:** ⭐⭐

[🏠 Workshop Home](../../README.md) | [📊 Exercise Slide](../../README.md#slide-12---exercise-001-tokenization-demo)

---

## 🎯 Overview

Before you can use AI coding tools effectively, it helps to understand what is actually happening inside a large language model when it reads your code or prompt. This exercise gives you a live, interactive view of one of the most fundamental concepts in LLMs: **tokenisation**.

You will run a console application that calls Microsoft Foundry's OpenAI-compatible Responses API and the `Microsoft.ML.Tokenizers` library to show you, in real time:

- How any text you type is split into tokens
- How many tokens the text consumes
- How the token count relates to cost and context-window limits

---

## 📚 Background: What Is a Token?

LLMs do not read text character-by-character or word-by-word. They read **tokens** — chunks of text produced by a tokeniser. A tokeniser's vocabulary and splitting rules balance vocabulary size against coverage, and the model is trained to use that tokeniser.

Some rough rules of thumb for GPT-family models:

| Text | Approximate tokens |
|------|--------------------|
| 1 average English word | ~1.3 tokens |
| `"Hello, world!"` | 4 tokens |
| A typical line of C# code | 5–15 tokens |
| 1,000 words of English prose | ~1,300 tokens |

Key implications for developers:

- **Context window limits** are measured in tokens, not words or characters. GPT-4o has a 128,000-token context window.
- **Cost** on pay-per-use APIs is billed per token (input + output).
- **Token prediction is not fact checking** — predicting the next token can produce plausible but incorrect text.
- Code tokens differ from English tokens: identifiers may split into several tokens, and punctuation or whitespace may be grouped with nearby text. Compare actual counts rather than assuming one token per identifier or operator.

GPT-4 uses **cl100k_base** (~100,000 tokens). GPT-4o, GPT-4o-mini, and GPT-4.1 use **o200k_base** (~200,000 tokens), which this application uses for local counts. If you deploy a model with a different tokenizer, update the tokenizer in `Program.cs` too.

The full-history local count includes approximate chat framing overhead. Responses API framing can differ, so API-reported usage is authoritative.

---

## 🗂️ Project Structure

```
exercise-001/
├── Program.cs              ← Foundry client, chat history, and token-counting flow
├── FoundryEndpoint.cs      ← Resolves project/resource URLs to the API-key model endpoint
├── TokenVisualizerUi.cs    ← Console rendering, input, spinner, and comparison table
└── TokenVisualizer.csproj  ← Project file (.NET 10, console app)
```

### Key Dependencies

| Package | Purpose |
|---------|---------|
| `OpenAI` | OpenAI SDK 2.8.0; the same direct Responses API client as exercise 101 |
| `Microsoft.ML.Tokenizers` | Local, offline o200k_base tokenisation for GPT-4o and GPT-4.1 |
| `Spectre.Console` | Rich terminal UI: colours, tables, panels |

---

## ✅ Your Task

This exercise is exploratory rather than implementation-focused. The application is already complete. Your job is to:

1. **Configure** the application by supplying your Foundry endpoint, API key, and deployment name via environment variables.
2. **Run** the application and interact with it.
3. **Experiment** — paste in different kinds of text and observe the token counts:
   - Plain English sentences
   - C# code snippets
   - SQL queries
   - Long variable names vs. short ones
   - A prompt you might actually send to Copilot Chat
4. **Reflect** — use what you observe to answer the questions in the [Discussion Prompts](#-discussion-prompts) section below.

---

## 🚀 Getting Started

### 1. Set Your Microsoft Foundry Credentials

Install the **.NET 10 SDK** to run this and the other console exercises.

The application reads its configuration from environment variables:

```powershell
# Windows (PowerShell)
$env:FOUNDRY_ENDPOINT         = "https://foundry-djohnnie.services.ai.azure.com/api/projects/proj-default"
$env:FOUNDRY_API_KEY          = "<your-api-key>"
$env:FOUNDRY_MODEL_DEPLOYMENT = "gpt-4.1-mini-511638"
```

Replace the example endpoint and deployment with your own Foundry values. `FOUNDRY_MODEL_DEPLOYMENT` must be the **deployment name** shown in Foundry, not a model catalog identifier unless they are identical. Keep the API key out of source control.

The application accepts a Foundry project endpoint (`https://<resource>.services.ai.azure.com/api/projects/<project>`), a resource endpoint (`https://<resource>.services.ai.azure.com`), or an explicit OpenAI v1 endpoint (`https://<resource>.services.ai.azure.com/openai/v1`). For API-key model access, it resolves project and resource URLs to the same resource's `/openai/v1` endpoint; the SDK adds `/responses`. A project URL does not add project-level agent or tool access—those APIs require the Foundry SDK and Microsoft Entra authentication.

You can also set these variables in a local `Properties\launchSettings.json` profile. Do not commit a profile containing a real API key.

Like exercise 101, `Program.cs` constructs `ResponsesClient` with the deployment name, `ApiKeyCredential`, and `OpenAIClientOptions.Endpoint`. This demo uses the SDK directly: it creates `ResponseItem` messages, places them in `CreateResponseOptions.InputItems`, and reads the reply with `response.GetOutputText()`. Exercise 101 instead adapts the client to `IChatClient` and reads `response.Text`. Both exercises pin `OpenAI` to 2.8.0 to match this SDK API and suppress its experimental `OPENAI001` diagnostic.

Unlike exercise 101's independent requests, this demo sends the system instruction and full conversation history on each call. `CreateResponseAsync` keeps the spinner responsive, and `response.Usage` supplies the API token counts directly. The richer UI, endpoint validation, and request error handling are retained.

### 2. Run the Application

```powershell
cd exercises\exercise-001
dotnet run
```

You will see a rich terminal UI powered by Spectre.Console. Type any text at the prompt and press **Enter** to see the token breakdown.

Conversation history is retained across turns. Enter `clear` to reset it (keeping the system instruction), or `quit` to exit. Request failures are displayed and the failed message is removed from history so you can retry.

---

## 💡 Discussion Prompts

Use the visualiser to investigate these questions during the GenAI introduction:

1. Type the same sentence in English and then in another language (e.g. French or German). Does the token count differ? Why?
2. Type a long camelCase identifier like `GetUserAccountTransactionHistoryAsync`. How many tokens is it?
3. Type a typical Copilot Chat prompt (e.g. *"Write a C# method that reads a JSON file and returns a list of User objects"*). How many tokens does your prompt consume?
4. How many prompts like that could fit in a 128,000-token context window?
5. Type a block of minified JavaScript. Compare the token count with the same code formatted nicely. What does this imply for how you share code with Copilot?

---

## 🔗 Further Reading

- [OpenAI Tokeniser (browser tool)](https://platform.openai.com/tokenizer)
- [Azure OpenAI pricing](https://azure.microsoft.com/pricing/details/cognitive-services/openai-service/)
- [Microsoft.ML.Tokenizers on NuGet](https://www.nuget.org/packages/Microsoft.ML.Tokenizers)

---

← Back to [Workshop Home](../../README.md) | Next: [Exercise 101 — Simple Chatbot](../exercise-101/README.md)
