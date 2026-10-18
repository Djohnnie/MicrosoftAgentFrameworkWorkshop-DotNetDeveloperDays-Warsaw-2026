# Exercise 405 - Call a Microsoft Foundry Agent

> **Part:** Part 4, Making agents reliable and production-ready  
> **Focus:** Invoke the existing `developerdays` agent through its Foundry endpoint  
> **History:** A new server-side conversation for each run

## What you'll build

A small .NET 10 console application sends `Hi developerdays` to the agent named
`developerdays` in your Microsoft Foundry project and prints its reply.
The agent's model, instructions, and tools are configured in Foundry, not in
this application. The exercise does not create or modify the agent.

Unlike the earlier exercises, this uses `AIProjectClient` and the agent-scoped
`ProjectResponsesClient`, not a direct model deployment or a local `AIAgent`.

## Authentication: an important difference

**Foundry agent endpoints do not support API-key authentication.** The
`FOUNDRY_API_KEY` used by the direct model examples cannot authenticate this
call. `AIProjectClient` in Azure.AI.Projects 2.1.0-beta.4 accepts a token provider,
not `ApiKeyCredential`. This exercise therefore uses `DefaultAzureCredential`,
as in the reference snippet; it does not read or send an API key.

Microsoft documents the supported authentication schemes in
[Configure and share your agent](https://learn.microsoft.com/azure/foundry/agents/how-to/configure-agent#understand-the-agent-object-model).
For local development, sign in with the Azure CLI and use an identity with
the **Foundry Agent Consumer** role (or a higher role such as **Foundry User**)
on the project or agent scope. A role granting access only to a model deployment
does not necessarily grant access to the agent.

This authenticates the console application's caller to Foundry. It does not
implement per-user sign-in or replace the tool authorization boundaries taught
in exercises 401-404.

## Run it

Use the **.NET 10 SDK** and Azure CLI. In Foundry, ensure the agent is named
`developerdays` and has an active version available at its agent endpoint.

From the repository root in PowerShell:

```powershell
az login
$env:FOUNDRY_ENDPOINT = "https://<resource-name>.services.ai.azure.com/api/projects/<project-name>"
dotnet run --project .\exercises\exercise-405\FoundryAgent.csproj
```

Use the **project endpoint** from Foundry, including `/api/projects/<project-name>`.
The resource root, `/openai/v1`, and the complete agent Responses URL are not
the project endpoint. Unlike the model examples, do not rewrite its path to
`/openai/v1`. The SDK derives the agent endpoint from the project URL and name.

`FOUNDRY_MODEL_DEPLOYMENT` is not needed: the existing Foundry agent selects its
model. An optional `Properties\launchSettings.json` can supply
`FOUNDRY_ENDPOINT`; these local profiles are already Git-ignored. Do not put
credentials or access tokens in source code or commit local profiles.

The program prints one user message and one assistant response, then exits.
There is no interactive loop. Authentication, permission, configuration, and
service errors surface as exceptions rather than fabricated answers.

## Follow the agent-scoped conversation

```csharp
ProjectResponsesClient agentClient =
    projectClient.ProjectOpenAIClient.GetProjectResponsesClientForAgentEndpoint(agentName);

ProjectConversationsClient conversationClient = new(
    agentClient.Pipeline,
    new OpenAIClientOptions { Endpoint = agentClient.Endpoint });
ProjectConversation conversation = await conversationClient.CreateProjectConversationAsync();

ProjectResponsesClient responseClient =
    projectClient.ProjectOpenAIClient.GetProjectResponsesClientForAgentEndpoint(
        agentName, defaultConversationId: conversation.Id);
```

The conversation client reuses the agent client's pipeline and endpoint so
both conversation creation and inference use the same authentication and agent
scope. The response client binds subsequent requests to the conversation ID.
To experiment with follow-ups, call `CreateResponseAsync` again on that same
`responseClient`.

This is **server-side state**, not exercise 106's local in-memory history.
Each program run creates a separate conversation; exiting does not delete it.
Use non-sensitive workshop prompts and manage retained conversations according
to your Foundry project's policies.

The project references Azure.AI.Projects 2.1.0-beta.4, Azure.Identity 1.21.0,
and OpenAI 2.14.0. Azure.AI.Projects brings in Azure.AI.Extensions.OpenAI
transitively. The agent endpoint API is a preview feature; use the pinned
packages and a Foundry project that supports it.

## Try it

1. Run the greeting and compare the response with the agent's Foundry playground.
2. Change `userMessage` to a conference question supported by the agent.
3. Send a follow-up through the same response client and compare it with a
   fresh run, which creates a different conversation.
