# Exercise 303 - Terrible Startup Pitch: Human Input Pauses

> **Part:** Part 3, Orchestrating agents and workflows  
> **Focus:** Pause a running workflow for human input, then resume the same run  
> **History:** Fresh, separate sessions for every agent invocation; no cross-pitch memory

## What you'll build

Extend [exercise 302](../exercise-302/README.md)'s Founder-to-Investor workflow
with a human-input step:

```text
User theme -> Founder -> RequestPort<string, string> -> Investor -> final review
                                  |
                            RequestInfoEvent
                                  |
                         Human accepts or edits
                                  |
                      SendResponseAsync resumes run
```

The Founder and Investor have the same prompts as exercises 301 and 302.
The difference is a **real workflow pause** between them. The Investor cannot
run until the console submits a response to the pending request. This is not
an instruction telling a model to ask permission, and the human is not a third
agent.

## Run it

From the repository root:

```powershell
dotnet run --project .\exercises\exercise-303\StartupPitchHumanInput.csproj
```

Use the **.NET 10 SDK** and the
[Foundry configuration from exercise 001](../exercise-001/README.md#1-set-your-microsoft-foundry-credentials):
`FOUNDRY_ENDPOINT`, `FOUNDRY_API_KEY`, and `FOUNDRY_MODEL_DEPLOYMENT`.
There is no committed launch profile or credential. Environment variables work
without a profile; never commit real keys.

Enter a theme, such as `a keyboard with only a deploy key`. Once the Founder
finishes, the console prints the pitch and announces that the workflow is paused.
At this prompt:

| Input | What happens |
| --- | --- |
| Enter, or whitespace only | Accept the exact original pitch. |
| A nonblank line | Replace the entire pitch with that line; this is not an edit instruction to the Founder. |
| Case-insensitive `quit`, or EOF | Exit and dispose the pending run without invoking the Investor. |

After submitting input, the Investor reviews the accepted or replacement pitch.
Enter another theme to start a new workflow with fresh agent sessions. At the
theme prompt, blank input is skipped and `quit` or EOF exits.

## 1. Insert a typed request port

Keep the small `PitchAgentExecutor` adapter from 302. Each invocation creates a
fresh session, calls its agent, and returns a nonempty string along its outgoing
edge. In `Program.cs`, replace the direct Founder-to-Investor edge:

```csharp
var founderStep = new PitchAgentExecutor(founder, "Founder");
var humanInput = RequestPort.Create<string, string>("HumanInput");
var investorStep = new PitchAgentExecutor(investor, "Investor");

Workflow workflow = new WorkflowBuilder(founderStep)
    .AddEdge(founderStep, humanInput)
    .AddEdge(humanInput, investorStep)
    .WithOutputFrom(investorStep)
    .Build();
```

The port's first type is its **request payload**: the Founder's pitch. Its second
type is its **external response**: the pitch the human wants the Investor to
receive. Both happen to be strings. There is deliberately no direct edge that
would let the Investor bypass the human-input step.

Reaching the port emits a `RequestInfoEvent`. This branch waits for a matching
external response rather than passing the original pitch straight through.
Other independent branches in a larger workflow could still progress; this
example has only one sequential path.

## 2. Handle the request outside the workflow

The host consumes events from the same `StreamingRun` as in 302:

```csharp
if (evt is RequestInfoEvent request)
{
    if (!request.Request.TryGetDataAs<string>(out var pitch) || string.IsNullOrWhiteSpace(pitch))
        throw new InvalidOperationException("Expected a nonempty pitch in the human-input request.");

    // Display the pitch and collect the human's response in the console host.
}
```

`Console.ReadLine` belongs to the host event loop, not to an executor or an
agent tool. Inspecting a pending request does not resume the workflow. A UI,
web application, or another external system could handle the same request
instead; the framework does not authenticate the respondent for you.

## 3. Reply to that request and continue

After handling `quit` and EOF, the console chooses the original or replacement
pitch and submits it:

```csharp
string reviewedPitch = string.IsNullOrWhiteSpace(replacement) ? pitch : replacement;
await run.SendResponseAsync(request.Request.CreateResponse(reviewedPitch));
```

`CreateResponse` correlates the answer with the pending request. `SendResponseAsync`
delivers it into the **existing run**; do not call `RunStreamingAsync` again.
The port's outgoing edge sends the response string to the Investor. Its
`WorkflowOutputEvent` contains the final review, printed once.

There are two model invocations per completed round, just as in 302. Human input
does not rerun the Founder or add a model call. Stopping at the pause invokes
only the Founder. Unexpected request data, empty agent responses, workflow
errors, and a missing final review fail explicitly.

## Try it

1. Enter a theme and wait at the human-input prompt. Put a breakpoint in
   `PitchAgentExecutor.HandleAsync` and confirm the Investor has not run.
2. Press Enter. Inspect the Investor's `message`: it is the original pitch.
3. Start a new round and replace the pitch with
   `BreakDuck rents rubber ducks that remind developers to take breaks.`
   Confirm the Investor receives that exact line, not the original theme or pitch.
4. Enter `quit` while paused. No Investor review should appear.
5. Enter two themes in one process. Each round has its own run, pending request,
   and fresh agent sessions.

Piped input also works. This example accepts the original pitch:

```powershell
@("a keyboard with only a deploy key", "", "quit") |
    dotnet run --project .\exercises\exercise-303\StartupPitchHumanInput.csproj
```

## Boundaries

This is **in-process pause/resume**, not durable execution. The console process
and run stay alive while waiting. Closing the process loses the pending request;
there is no checkpoint store, restart recovery, timeout, or cross-process
response endpoint.

Accepting a fictional pitch is not authorization for a real-world action.
This exercise demonstrates general workflow input, not approval-required tool
execution; [exercise 206](../exercise-206/README.md) demonstrates that separate
agent-tool pattern. A real approval UI must authenticate and authorize the respondent,
bind the decision to the exact proposed action, and record it appropriately.
No tools, side effects, automatic approval, or revision loop are added here.

The project uses Microsoft.Agents.AI and Microsoft.Agents.AI.Workflows **1.24.0**,
OpenAI **2.14.0**, and Microsoft.Extensions.AI.OpenAI **10.11.0**. Agents retain
local in-memory history and disable server-side Responses storage, as in 302;
inference still sends messages to Foundry.

Continue with [exercise 304](../exercise-304/README.md) for three concurrent
investor reviews, or [Lab 300](../../labs/lab-300/README.md) for typed state,
deterministic schedule checks, and bounded conditional revision edges.

Microsoft Learn:
[human-in-the-loop workflows](https://learn.microsoft.com/agent-framework/workflows/human-in-the-loop?pivots=programming-language-csharp).
