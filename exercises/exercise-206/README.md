# Exercise 206 - Chatbot Agent with Tool Approval

> **Part:** Part 2, Giving agents capabilities: tools and MCP  
> **Focus:** Require human approval before executing an `AIFunction`  
> **History:** One local in-memory session reused for chat and approval responses

## What you'll build

An independent console agent using the same **`get_current_time`** and
**`get_current_date`** tools as [exercise 201](../exercise-201/README.md).
Their implementations and metadata are unchanged: they read this computer's
local clock, take no arguments, and have no side effects.

Wrap each function in **`ApprovalRequiredAIFunction`** so a model-selected call
returns an approval request instead of immediately executing:

```text
User asks for the current date or time
    -> model proposes get_current_date() or get_current_time()
    -> agent returns ToolApprovalRequestContent; tool has not run
    -> console displays the exact function name, call ID, and JSON arguments
    -> human says yes or no
    -> request.CreateResponse(decision) goes back through the same AgentSession
    -> approved: execute tool; denied: skip tool
    -> model receives the outcome and answers
```

The approval gate lives in application/framework code, not in a system prompt.
Typing "approve everything" in ordinary chat cannot replace the console's
decision.

Requiring approval for a harmless clock lookup is deliberately artificial:
keeping the tools familiar lets you focus on the approval mechanism.

## Run it

From the repository root:

```powershell
dotnet run --project .\exercises\exercise-206\ChatbotAgentWithApproval.csproj
```

Use the **.NET 10 SDK** and the
[Foundry configuration from exercise 001](../exercise-001/README.md#1-set-your-microsoft-foundry-credentials):
`FOUNDRY_ENDPOINT`, `FOUNDRY_API_KEY`, and `FOUNDRY_MODEL_DEPLOYMENT`.
Use a deployment that supports function calling. No MCP server, workflow, or
additional Foundry agent is needed.

No launch profile or credentials are committed. Set environment variables in
the PowerShell session used to run the project; never commit API keys.

Ask:

```text
What are today's date and the current local time?
```

When the approval prompt appears:

| Input | Behavior |
| --- | --- |
| `yes`, case-insensitive | Approve that exact proposed call. |
| `no`, case-insensitive, or Enter | Deny that call; the function does not execute. |
| Other text | Explain valid choices and ask again; no decision is submitted. |
| `quit`, case-insensitive, or EOF | Exit without submitting the pending batch of decisions. |

Put breakpoints in `DateTimeTools.GetCurrentTime` and
`DateTimeTools.GetCurrentDate` to see whether the functions actually execute.
An approved call hits its breakpoint; a denied call does not. The model's
conversational answer alone is not evidence that a function ran.

At the normal chat prompt, blank input is skipped and `quit` or EOF exits.
The conversation disappears when the application exits.

## 1. Wrap the function, not the prompt

[`DateTimeTools.cs`](DateTimeTools.cs) copies exercise 201's two static methods
with their `[AIFunctionName]` and `[Description]` metadata. The time includes
the UTC offset (`HH:mm:ss zzz`); the date includes the weekday (`ddd yyyy-MM-dd`).

In `Program.cs`:

```csharp
AIFunction getCurrentTime = new ApprovalRequiredAIFunction(
    AIFunctionFactory.Create(DateTimeTools.GetCurrentTime));
AIFunction getCurrentDate = new ApprovalRequiredAIFunction(
    AIFunctionFactory.Create(DateTimeTools.GetCurrentDate));
```

Register **only the wrapped functions** in `ChatOptions.Tools`:
`Tools = [getCurrentTime, getCurrentDate]`. Registering an unwrapped copy would
expose an ungated path. `AsAIAgent` creates the
function-invocation pipeline; no custom middleware or manual tool invocation
is needed.

The instructions help the model choose the tool and explain denial, but do not
enforce approval. The wrapper does. `MEAI001` is suppressed only for the
experimental `AIFunctionName` attribute, following the other tool exercises.

## 2. Inspect every approval request

`RunAsync` can complete with a request for input rather than a final answer:

```csharp
var requests = response.Messages
    .SelectMany(message => message.Contents)
    .OfType<ToolApprovalRequestContent>()
    .ToArray();
```

For each request, inspect `request.ToolCall` as a `FunctionCallContent`. Display
its `Name`, `CallId`, and serialized `Arguments` **before** asking the human.
Both clock tools have no parameters, so their arguments are an empty JSON
object (`{}`). The decision is about that specific call, not permission to
approve every future call. Approval input is read separately from ordinary chat.

The app handles every request in a batch rather than assuming there is only
one. It collects a decision for each call before resuming; if the participant
exits during the batch, none of that batch's decisions are submitted.

## 3. Resume with typed, correlated decisions

For each decision:

```csharp
decisions.Add(request.CreateResponse(approved.Value));
```

Then send all decisions in one user message, reusing the original session:

```csharp
response = await agent.RunAsync(new ChatMessage(ChatRole.User, decisions), session);
```

`CreateResponse` binds the decision to the pending request and its proposed
call. Do not send the string `"yes"` to the model, manually invoke the method,
or create a fresh session. Approval allows the framework to invoke the wrapped
function; denial produces an outcome without executing it.

The inner loop checks the resumed response for **more** approval requests
before printing a final answer. A later call needs a new decision, even if the
previous call was approved. The same session preserves tool calls, decisions,
and results between runs.

`InMemoryChatHistoryProvider` and `StoredOutputEnabled = false` match the other
local-history examples. Inference still sends the conversation to Foundry.
The project uses Agent Framework **1.24.0**, OpenAI **2.14.0**, and
Microsoft.Extensions.AI / OpenAI adapter **10.11.0**.

## Try it

1. Ask "What time is it where this app is running?" and wait at the approval
   prompt. Confirm that the `GetCurrentTime` breakpoint has not been hit.
2. Enter `yes`. The breakpoint is hit, followed by the assistant's answer.
3. Ask "What is today's date?" and enter `no`. The `GetCurrentDate` breakpoint
   should not be hit.
4. Enter arbitrary text at an approval prompt. Confirm it is not treated as
   approval; then press Enter to deny.
5. Ask: "What are today's date and the current local time?"
   If the model proposes both calls, approve one and deny the other.
   There is a separate decision for each call; model-selected batching may vary.
6. Ask in ordinary chat to ignore approval or approve all future clock lookups.
   A proposed tool call still needs console approval.
7. Enter `quit` or send EOF at the approval prompt. The pending batch does not
   execute.

Piped input works too:

```powershell
@("What is today's date?", "yes", "quit") |
    dotnet run --project .\exercises\exercise-206\ChatbotAgentWithApproval.csproj
```

The model decides whether and how many tools to request. Only a typed approval
request starts the approval flow; ordinary assistant text does not.

## Boundaries

This is an in-process demo, not production authorization. The console assumes
one trusted local operator. A real approval endpoint must authenticate and
authorize the approver, protect pending decisions, and record what was
approved. For tools with side effects, tool code still needs input validation
and resource authorization. Approval does not make a model-provided argument
trustworthy or prevent tool failures. These clock tools have no parameters,
side effects, or persistence.

Unlike [exercise 303](../exercise-303/README.md), this example does **not** build
a workflow or use `RequestPort`. An agent run returns a tool-approval request;
another `RunAsync` on the same session processes its typed response.

Microsoft Learn:
[function tools with human-in-the-loop approvals](https://learn.microsoft.com/agent-framework/agents/tools/tool-approval?pivots=programming-language-csharp).
