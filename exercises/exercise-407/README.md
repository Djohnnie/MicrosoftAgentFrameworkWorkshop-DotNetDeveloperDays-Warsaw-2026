# Exercise 407 - Save and Restore a Local Agent Session

> **Part:** Part 4, Making agents reliable and production-ready  
> **Focus:** Serialize session state to JSON and deserialize it into a replacement session  
> **Storage:** Local chat history, explicitly saved to a local file

## What you'll build

A small chatbot based on exercise 107's local-history design, with four console
commands. The agent definition stays in C#; the conversation lives in an
`AgentSession`. Saving that session lets you restore the conversation even
after stopping and restarting the process.

This uses Agent Framework's **built-in session serialization**, not a custom
DTO containing only the visible answer strings:

```csharp
JsonElement snapshot = await agent.SerializeSessionAsync(session);
await File.WriteAllTextAsync(sessionPath + ".tmp", snapshot.GetRawText());
File.Move(sessionPath + ".tmp", sessionPath, overwrite: true);

using JsonDocument snapshotFile =
    JsonDocument.Parse(await File.ReadAllTextAsync(sessionPath));
session = await agent.DeserializeSessionAsync(snapshotFile.RootElement);
```

Serialize through the agent that owns the session. Recreate a compatible agent
with the same history-provider configuration before restoring it. The snapshot
contains session/provider state, including local messages; it does **not**
serialize the agent definition, model client, API key, or running C# code.
It is not a workflow checkpoint or an exact replay of previous model execution.

## Run it

Use the **.NET 10 SDK** and the
[Foundry setup from exercise 001](../exercise-001/README.md#1-set-your-microsoft-foundry-credentials):
`FOUNDRY_ENDPOINT`, `FOUNDRY_API_KEY`, and `FOUNDRY_MODEL_DEPLOYMENT`.

```powershell
dotnet run --project .\exercises\exercise-407\SessionPersistence.csproj
```

The endpoint is mapped to the resource's `/openai/v1`. No hosted Prompt Agent,
Entra application credentials, embedding deployment, or database is needed.

| Command | Effect |
| --- | --- |
| `/save` | Save the current session, replacing the previous snapshot. |
| `/load` | Restore the snapshot and replace the current in-memory session. |
| `/new` | Start an empty session without modifying the saved file. |
| `/history` | Print the messages from the actual current session. |
| `quit` or EOF | Exit without automatically saving. |

Commands are case-insensitive; blank input is skipped. Commands are handled by
the console, not sent to the model. Loading before saving reports that no file
exists. JSON parsing, SDK deserialization, model, and file-access errors
propagate rather than silently starting a new conversation.

The app prints the snapshot's absolute path at startup. It is `session.json`
beside the built executable, normally under
`exercises\exercise-407\bin\Debug\net10.0`, which Git already ignores.
The temporary write is moved into place only after it completes.
Build configuration/output changes select a different snapshot location;
cleaning the output directory can delete the snapshot.

## Try it

1. Enter **"My name is Ada. My robot project is called Blue Comet."**
2. Enter `/history`, then `/save`. Inspect the JSON locally if you want to
   compare its provider state with the printed messages.
3. Enter `/new`, then `/history`: the new session is empty.
4. Enter `/load`, then ask **"What is my name and what is my robot called?"**
   The restored history should provide both facts.
5. Exit, run the project again, and enter `/history`. Startup is deliberately
   fresh: loading is explicit, not automatic.
6. Enter `/load` and ask the same question. The conversation survives the
   process restart because the snapshot is on disk.
7. Add a new fact without saving, then `/load` again. The unsaved fact is gone:
   loading replaces state; it does not merge two conversations.

The restored messages are deterministic state; whether a model correctly uses
them is model behavior. `/history` lets you verify restoration without relying
on the wording of an answer.

## Local history is not offline inference

`InMemoryChatHistoryProvider` keeps history in the session's state bag, and
`StoredOutputEnabled = false` disables server-side Responses storage. Both
serialization commands operate locally without a model call. A normal chat
turn still sends the restored history to Foundry for inference.

The file is **plaintext conversation data**. Use fictional workshop facts only;
do not share snapshots or commit them. Production persistence needs protected
storage, user/conversation isolation, retention rules, and compatibility/version
planning. Only restore trusted snapshots: changed roles or message content can
influence the agent. Serializing a session is not authentication or authorization.

Continue with [exercise 408](../exercise-408/README.md) to reduce growing
history instead of only persisting it.

Packages: Agent Framework **1.24.0**, OpenAI adapter **10.11.0**, OpenAI **2.14.0**.
Microsoft Learn:
[sessions and restoration](https://learn.microsoft.com/agent-framework/concepts/agents/conversations/session?pivots=programming-language-csharp)
and [conversation storage](https://learn.microsoft.com/agent-framework/concepts/agents/conversations/storage?pivots=programming-language-csharp).
The installed 1.24.0 SDK uses `SerializeSessionAsync`; documentation for other
versions may show `SerializeSession`.
