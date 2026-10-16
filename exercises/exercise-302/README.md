# Exercise 302 - Terrible Startup Pitch: Agent Framework Workflow

> **Part:** Part 3, Orchestrating agents and workflows  
> **Focus:** Replace exercise 301's manual handoff with a two-stage workflow  
> **History:** Fresh, separate sessions for every agent invocation; no cross-pitch memory

## What you'll build

The same **Founder** and **Investor** from
[exercise 301](../exercise-301/README.md), using identical instructions and
plain-text inputs and outputs:

```text
User theme -> Founder executor -- string edge --> Investor executor -> final review
                  |                                  |
             Founder agent                      Investor agent
```

The Founder pitches a ridiculous startup. The Investor gives one strength,
two practical objections, and a **FUND** or **PASS** verdict. The difference is
that **Microsoft Agent Framework Workflows** delivers the pitch to the Investor;
the console no longer forwards `pitch.Text` in a second direct agent call.

There are still only two agents. There is no third orchestrator agent, MCP
server, structured-output schema, conditional branch, or revision loop.

## Run it

From the repository root:

```powershell
dotnet run --project .\exercises\exercise-302\StartupPitchWorkflow.csproj
```

Use the **.NET 10 SDK** and the
[Foundry configuration from exercise 001](../exercise-001/README.md#1-set-your-microsoft-foundry-credentials):
`FOUNDRY_ENDPOINT`, `FOUNDRY_API_KEY`, and `FOUNDRY_MODEL_DEPLOYMENT`.
An optional Git-ignored `Properties\launchSettings.json` profile named
`StartupPitchWorkflow` can provide these locally. A fresh clone has no
credentials; never commit them.

Enter a theme and press **Enter**. Blank input is skipped; EOF or
case-insensitive `quit` exits. The output has the same Founder and Investor
labels as exercise 301.

## 1. Keep the two agents unchanged

`Program.cs` uses the same Foundry Responses setup, two instruction strings,
`CreateAgent` helper, and shared `IChatClient` as 301. Agents use local
`InMemoryChatHistoryProvider` storage and disable server-side Responses storage
with `StoredOutputEnabled = false`.

Both agents can use the same deployment. Only their instructions and roles
differ; workflows do not train models or deploy hosted agents.

## 2. Wrap each agent in a typed executor

[`PitchAgentExecutor.cs`](PitchAgentExecutor.cs) is one small reusable adapter:

```csharp
public sealed class PitchAgentExecutor(AIAgent agent, string id) : Executor<string, string>(id)
{
    public override async ValueTask<string> HandleAsync(
        string message, IWorkflowContext context, CancellationToken cancellationToken = default)
    {
        AgentSession session = await agent.CreateSessionAsync(cancellationToken: cancellationToken);
        AgentResponse response = await agent.RunAsync(message, session, cancellationToken: cancellationToken);
        if (string.IsNullOrWhiteSpace(response.Text))
            throw new InvalidOperationException($"{agent.Name} returned an empty response.");
        return response.Text;
    }
}
```

`Executor<string, string>` declares that the stage receives a string and returns
a string. The constructor's `id` identifies it in the graph and events.
`HandleAsync` is invoked by the workflow runtime, not by the console loop.

Each invocation creates a fresh `AgentSession`, exactly like 301.
`RunAsync` waits for the complete agent response. The returned `response.Text`
is automatically sent along connected edges by the generic executor's default
behavior. An explicit `context.SendMessageAsync` call is not necessary here.

`IWorkflowContext` supplies workflow operations for more advanced handlers;
this adapter only needs its typed return value. One adapter class wraps two
different agent objects, creating two distinct executor instances.

## 3. Describe the handoff as a graph

For each nonblank theme, `Program.cs` builds:

```csharp
var founderStep = new PitchAgentExecutor(founder, "Founder");
var investorStep = new PitchAgentExecutor(investor, "Investor");

Workflow workflow = new WorkflowBuilder(founderStep)
    .AddEdge(founderStep, investorStep)
    .WithOutputFrom(investorStep)
    .Build();
```

| API | What happens here |
| --- | --- |
| `new WorkflowBuilder(founderStep)` | Selects the Founder as the entry stage. |
| `AddEdge(founderStep, investorStep)` | Routes the Founder's returned string to the Investor. No original-theme concatenation or shared transcript is added. |
| `WithOutputFrom(investorStep)` | Registers the Investor's returned string as the workflow's final output. The Founder remains observable through completion events. |
| `Build()` | Constructs and validates the graph; it does not execute either agent. |

This is a sequential graph. The Investor waits for the Founder and receives
the **exact pitch text**. The runtime controls delivery, while agent invocation
stays inside the executor. The Investor does not receive the Founder's system
instructions or independently receive the original theme.

## 4. Run it and observe workflow events

```csharp
await using StreamingRun run = await InProcessExecution.RunStreamingAsync(workflow, input);
await foreach (WorkflowEvent evt in run.WatchStreamAsync())
{
    // Inspect progress, output, and failure events.
}
```

`InProcessExecution.RunStreamingAsync` starts the graph **in the console
process** with the user's theme as its initial string message. The `await using`
scope disposes the run. Inference still happens remotely through Foundry.

The real event loop handles:

| Event | Console behavior |
| --- | --- |
| `ExecutorCompletedEvent` with `ExecutorId == "Founder"` | Prints the Founder's pitch from the event's string `Data`. |
| `WorkflowOutputEvent` | Prints the Investor's review from `Data`, once. |
| `WorkflowErrorEvent` | Throws an explicit failure using the underlying `Exception`. |

The code also requires a final review event instead of treating an ended stream
as successful completion. It does not print the Investor's completion event as
well as its output event, which would display the same review twice.

This is **workflow-event streaming**, not model-token streaming. Both agents
still use non-streaming `RunAsync` inside their executors.

## Compare 301 and 302

| Concern | 301: manual | 302: workflow |
| --- | --- | --- |
| Agents and instructions | Founder and Investor | Identical Founder and Investor |
| Handoff | `investor.RunAsync(pitch.Text, investorSession)` | Typed return value routed by `AddEdge` |
| Execution order | Two sequential awaited calls | Graph entry and directed edge |
| Progress/results | Print each `AgentResponse.Text` | Observe completion and final output events |
| History | Fresh sessions per round | Fresh sessions per executor invocation |
| Model invocations per completed round | Two | Two |
| FUND/PASS handling | Printed as text | Printed as text, not parsed as a routing condition |

For this tiny example, ordinary C# is already sufficient. The workflow adds
explicit structure and events, not a promise of better answers or lower cost.
Lab 300 builds on these APIs with typed records, deterministic checks and
conditional revision edges.

The project pins Microsoft.Agents.AI and Microsoft.Agents.AI.Workflows
**1.24.0**, OpenAI **2.14.0**, and Microsoft.Extensions.AI.OpenAI **10.11.0**.
Missing configuration, empty responses, and inference/workflow errors fail
explicitly; no automatic recovery, persistence, tools, or extra review turns
are added.

## Try it

1. Use the same themes as 301: break-reminder subscriptions, cloud rubber ducks,
   or a keyboard with only a deploy key.
2. Put breakpoints in both `HandleAsync` invocations. Follow the theme into the
   Founder and its returned pitch into the Investor.
3. Inspect `ExecutorCompletedEvent.ExecutorId` and `WorkflowOutputEvent.Data`.
4. Enter a second theme. Confirm it starts a new workflow and fresh sessions.
5. Continue with [Lab 300](../../labs/lab-300/README.md) for richer state and
   conditional routing.

This remains a fictional comedy competition. Prompted word limits and
FUND/PASS formatting are not enforced by C#; outputs vary between runs.

Microsoft Learn:
[first workflow](https://learn.microsoft.com/agent-framework/get-started/workflows?pivots=programming-language-csharp),
[executors](https://learn.microsoft.com/agent-framework/concepts/workflows/executors?pivots=programming-language-csharp),
[workflow construction and execution](https://learn.microsoft.com/agent-framework/concepts/workflows/builder-and-execution?pivots=programming-language-csharp),
and [edges](https://learn.microsoft.com/agent-framework/concepts/workflows/edges?pivots=programming-language-csharp).
