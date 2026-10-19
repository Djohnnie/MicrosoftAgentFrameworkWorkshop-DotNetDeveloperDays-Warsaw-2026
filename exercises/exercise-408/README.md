# Exercise 408 - Compact Local History with Summaries

> **Part:** Part 4, Making agents reliable and production-ready  
> **Focus:** Automatically summarize older conversation messages with built-in compaction  
> **Storage:** Compacted local history in the session; no file persistence

## What you'll build

A chatbot that replaces older conversation content with a model-generated
summary while keeping the newest exchange intact. The console prints the actual
stored messages after each reply, so you can see history grow and then shrink.

Agent Framework **1.24.0** includes the experimental
`Microsoft.Agents.AI.Compaction` APIs. No handwritten summarizer, extra agent,
or compaction-specific package is required:

```csharp
SummarizationCompactionStrategy summarization = new(
    chatClient,
    trigger: CompactionTriggers.TurnsExceed(3),
    minimumPreservedGroups: 2,
    target: index => index.IncludedNonSystemGroupCount <= 2);

ChatHistoryProvider = new InMemoryChatHistoryProvider(new InMemoryChatHistoryProviderOptions
{
    ChatReducer = summarization.AsChatReducer(),
    ReducerTriggerEvent =
        InMemoryChatHistoryProviderOptions.ChatReducerTriggerEvent.AfterMessageAdded
});
```

`AsChatReducer()` adapts the strategy to the built-in history provider's reducer
hook. This **changes stored local history**, rather than merely showing the
model a shorter copy while retaining the full original transcript.
`#pragma warning disable MAAI001` explicitly opts into the experimental APIs;
their signatures may change in future SDK releases.

## Run it

Use the **.NET 10 SDK** and the
[Foundry setup from exercise 001](../exercise-001/README.md#1-set-your-microsoft-foundry-credentials):
`FOUNDRY_ENDPOINT`, `FOUNDRY_API_KEY`, and `FOUNDRY_MODEL_DEPLOYMENT`.

```powershell
dotnet run --project .\exercises\exercise-408\HistoryCompaction.csproj
```

Both answers and summaries use the same chat deployment. No embedding
deployment, vector database, hosted Prompt Agent, or saved session is needed.
Blank input is skipped; EOF or case-insensitive `quit` exits.
`/history` inspects the current state without a model call.

## When compaction runs

After a successful turn adds request and response messages to history, the
provider invokes its reducer. The strategy runs only when the stored history
contains **more than three user turns**. In this text-only example, the fourth
completed exchange triggers the first summary.

The two newest non-system **message groups** are protected. Here those are
the latest user message and assistant reply, not two complete turns. The older
groups become one assistant summary message. On subsequent turns that summary
participates in the next compaction, preserving an evolving account rather than
an ever-growing set of separate summaries.

The **trigger** decides when to begin; the **target** decides how much to reduce.
The explicit target leaves only two non-system groups before inserting the
summary. Without it, the default target merely reduces history back to three
user turns, not to the newest exchange. The preservation floor protects the
latest two groups regardless of the target.

Compaction groups related messages atomically, including tool calls and their
results, and preserves system messages. This exercise has **no tools** so you
can focus on the summary and retained text. Agent instructions remain configured
separately in `ChatOptions.Instructions`.

The deliberately low threshold makes compaction visible quickly; it is not a
recommended production context budget. There is no promise that a summary is
shorter in tokens than the original, especially for short messages.
`/history` reports **message count and text-character count**, not token counts.

## Try it

Enter each line as a separate turn:

1. **"My name is Ada. My robot project is called Blue Comet."**
2. **"The robot must work offline. Remember that requirement."**
3. **"Our budget is 80 EUR. Reply briefly."**
4. **"We must finish by Friday. Reply briefly."**
5. **"List my name, project, requirement, budget, and deadline."**

After turn three, expect six stored messages. After turn four, inspect the
summary plus the latest user/assistant pair, normally three stored messages.
The fifth question is answered using that compacted context, not the original
first three exchanges. Compare its answer with the facts you entered.

Continue with several short turns and inspect the next compaction. Try adding
a precise identifier or correcting an earlier fact, then check whether the
summary preserves it correctly. Summarization is **lossy**: plausible-sounding
output is not proof that every detail survived.

Restart the app: history is empty. Unlike
[exercise 407](../exercise-407/README.md), this exercise deliberately does not
save or restore sessions. In an application that combines the two techniques,
serializing after compaction saves the reduced state, not an untouched archive.

## What is built in, and what stays local?

The SDK supplies the compaction trigger, message grouping, summarization
strategy, and reducer integration. The **model** produces the summary; the
application chooses the trigger, preservation policy, and client.

History storage and replacement happen locally. Both ordinary replies and
summaries still send conversation data to Foundry. The client-level
`ConfigureOptions` disables Responses storage for **both** call types; setting
that option only on the answering agent would not cover the strategy's direct
chat-client calls. No server-side conversation is continued.

Compaction adds latency and a billable model request on triggering turns.
Because reduction runs after messages are added, it cannot rescue a request
that has already exceeded the model's context window. Real applications should
compact before their limit, account for the next input and output budget, and
measure token use. A turn-count threshold is not a hard token limit.

Use a trusted summarization service and validate important facts independently.
The summary becomes persistent conversation context for the rest of this
session, so injected or mistaken content can affect later answers. Do not use
summaries to preserve passwords, permissions, or authoritative business state.

The SDK treats summarization as **best effort**: if its model call fails, it
retains the original groups instead of failing the completed chat turn.
The shared client's `UseLogging` pipeline reports model errors to the console
at Warning/Error level without enabling prompt/response trace logging.
A small response guard rejects empty text before the strategy can replace
history with its built-in "summary unavailable" placeholder. That failure is
also logged and leaves the original history intact. Inspect `/history` after
an error; do not assume compaction succeeded or that a token limit is enforced.
Ordinary answering failures still terminate explicitly.

Sliding-window and truncation strategies are also built in, but **discard**
older content rather than summarizing it. Summarization trades an extra model
call and possible information loss for a condensed account.

Packages: Agent Framework **1.24.0**, OpenAI adapter **10.11.0**, OpenAI **2.14.0**,
and console logging **10.0.12** for visible model-call failures.
Microsoft Learn:
[conversation compaction](https://learn.microsoft.com/agent-framework/concepts/agents/conversations/compaction?pivots=programming-language-csharp).
Check the installed SDK's signatures when comparing with newer documentation.
