# Exercise 101 - Simple Chatbot

> **Part:** Part 1, From LLM calls to agents  
> **Focus:** Send a message through `IChatClient` and display its response  
> **History:** None; every message is an independent request

## What you'll build

Run a small console chatbot and exchange messages with a Microsoft Foundry model. The app reads the same `FOUNDRY_ENDPOINT`, `FOUNDRY_API_KEY`, and `FOUNDRY_MODEL_DEPLOYMENT` environment variables as exercise 001.

The program adapts the OpenAI SDK's `ResponsesClient` to `IChatClient`, a common chat interface from `Microsoft.Extensions.AI`. It still calls Foundry's OpenAI-compatible Responses API; there is no agent yet. Each request contains only the current user message; earlier messages and responses are **not** carried into later turns. This is intentional: agents and conversation history will be introduced as separate concepts.

## Run it

From this directory:

```powershell
dotnet run
```

Use the **.NET 10 SDK** and the [Foundry environment-variable setup from exercise 001](../exercise-001/README.md#1-set-your-microsoft-foundry-credentials). An optional local `Properties\launchSettings.json` profile can supply the three variables instead. That file is ignored by Git because it may contain an API key and is not included in a fresh clone. Otherwise, set the variables in the same PowerShell session before running the app.

Type a message and press **Enter** to see the response. Type `quit` to exit. Each new message starts a fresh request.

## What happens in the code

1. `FOUNDRY_ENDPOINT`, `FOUNDRY_API_KEY`, and `FOUNDRY_MODEL_DEPLOYMENT` configure a Foundry `ResponsesClient`. A single `UriBuilder` expression replaces the endpoint's path with `/openai/v1`, so the Foundry project URL from exercise 001 works without an endpoint helper.
2. `client.AsIChatClient()` adapts the Responses client to `IChatClient`.
3. `chatClient.GetResponseAsync(input)` sends the current user message to the deployment.
4. `response.Text` supplies the text to print. No history or previous response ID is passed to the next request.

The core uses the common chat interface:

```csharp
using IChatClient chatClient = client.AsIChatClient();

var response = await chatClient.GetResponseAsync(input);
Console.WriteLine($"[ASSISTANT]: {response.Text}");
```

The project uses `OpenAI` **2.8.0** and `Microsoft.Extensions.AI` / `Microsoft.Extensions.AI.OpenAI` **10.3.0**, matching exercise 104. These versions support the model-taking `ResponsesClient` constructor and its adapter. Agent Framework will build on this model call later; see [Microsoft Learn: Your First Agent](https://learn.microsoft.com/en-us/agent-framework/get-started/your-first-agent?pivots=programming-language-csharp).

The code is intentionally short enough to type along. Missing environment variables throw a clear exception, and request errors propagate rather than being caught. The `OPENAI001` pragma suppresses the underlying SDK's experimental Responses API diagnostic.

## Try it

- Ask a question, then ask a follow-up such as “Can you explain that more simply?” Notice that the model has no context for “that”.
- Repeat the first question and compare the answers.
- Consider what data would need to be retained and sent for the model to understand a follow-up.

That retained context is conversation history. This exercise omits it so you can see the stateless baseline before adding history in [exercise 102](../exercise-102/README.md).
