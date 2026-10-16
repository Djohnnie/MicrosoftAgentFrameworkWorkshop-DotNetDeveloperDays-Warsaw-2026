# Exercise 301 - Terrible Startup Pitch: Manual Orchestration

> **Part:** Part 3, Orchestrating agents and workflows  
> **Focus:** Pass one agent's output to another agent in ordinary C#  
> **History:** Fresh, separate sessions for every pitch and review; no cross-pitch memory

## What you'll build

Two agents enter a fictional startup pitch competition:

- The **Founder** turns your theme into a ridiculous startup pitch, including a
  product name, problem, customers, and business model.
- The **Investor** reads that pitch, identifies one strength and two practical
  objections, and finishes with **FUND** or **PASS**.

```text
User theme -> Founder agent -> pitch.Text -> Investor agent -> review.Text
                 application code controls the handoff
```

This exercise deliberately uses **no workflows**, tools, MCP server, structured
output schema, or coordinating third agent. It demonstrates that orchestration
can start with two sequential `RunAsync` calls.

## Run it

From the repository root:

```powershell
dotnet run --project .\exercises\exercise-301\StartupPitchManual.csproj
```

Use the **.NET 10 SDK** and the
[Foundry environment-variable setup from exercise 001](../exercise-001/README.md#1-set-your-microsoft-foundry-credentials).
Set `FOUNDRY_ENDPOINT`, `FOUNDRY_API_KEY`, and `FOUNDRY_MODEL_DEPLOYMENT`.
The last value is the deployment name, not necessarily the model catalog name.
An optional Git-ignored `Properties\launchSettings.json` profile named
`StartupPitchManual` can provide these locally. A fresh clone does not include
credentials; never commit the profile or API key.

Enter a theme and press **Enter**. Blank input is skipped; EOF or
case-insensitive `quit` exits. The console prints separate Founder and Investor
answers under `[ASSISTANT]:` labels.

## Create two agents, not two models

`ResponsesClient` uses API-key inference at the resource's `/openai/v1`
endpoint. `AsIChatClient(model)` supplies the deployment and adapts the provider
client to `IChatClient`.

`CreateAgent` is a local helper that calls
`chatClient.AsAIAgent(new ChatClientAgentOptions { ... })`. It is called twice,
with different names and instructions. Both agents share the same `IChatClient`
and can use the same Foundry deployment; their roles do not require separately
deployed models.

Each agent has an `InMemoryChatHistoryProvider`.
`CreateResponseOptions.StoredOutputEnabled = false` disables server-side
Responses storage. History is local, but inference still sends the relevant
messages to Foundry.

## The complete handoff

The important sequence in `Program.cs` is:

```csharp
AgentSession founderSession = await founder.CreateSessionAsync();
AgentResponse pitch = await founder.RunAsync(input, founderSession);

AgentSession investorSession = await investor.CreateSessionAsync();
AgentResponse review = await investor.RunAsync(pitch.Text, investorSession);
```

The program also rejects empty responses and prints each result. The Investor
receives **the actual `pitch.Text`**, not the original theme, an invented summary,
or the Founder's session. The Founder finishes before the Investor starts.

Fresh sessions are created **inside** the input loop. This keeps each competition
round independent and prevents either agent from inheriting another agent's
conversation. Reusing an agent object is not the same as reusing its session.

The Investor receives only the pitch plus its own instructions. It does not see
the original theme independently or receive the Founder's system instructions.
Both results are plain text: the word limit, requested format, and FUND/PASS
ending are prompt instructions, not programmatically enforced constraints.

## Where is the orchestration?

It is in your C# code: await the Founder, extract the text, call the Investor,
and display the review. There is no workflow builder, edge, event stream, retry,
or revision loop. **PASS is a final verdict**, not a routing command.

Missing configuration, empty model output, and request failures propagate
explicitly as exceptions. This short teaching example does not add recovery,
persistence, or a full application framework.

The project pins Microsoft.Agents.AI **1.24.0**, OpenAI **2.14.0**, and
Microsoft.Extensions.AI.OpenAI **10.11.0**. It has **no**
`Microsoft.Agents.AI.Workflows` package reference.

## Try it

1. Enter: "A subscription service for developers who forget to take breaks."
2. Enter: "Cloud-hosted rubber ducks for debugging meetings."
3. Enter: "A premium keyboard with only one key: deploy."
4. Notice whether the Investor critiques the Founder's actual product rather
   than writing a new pitch.
5. Compare with [exercise 302](../exercise-302/README.md), which uses the same
   agent instructions and changes only how the handoff is orchestrated.

The companies, financial claims, and funding verdicts are fictional comedy,
not business or investment advice. Outputs can differ between runs even when
the prompts and deployment are the same.

Microsoft Learn: [running agents](https://learn.microsoft.com/agent-framework/concepts/agents/running-agents?pivots=programming-language-csharp)
and [sessions and memory](https://learn.microsoft.com/agent-framework/get-started/memory?pivots=programming-language-csharp).
