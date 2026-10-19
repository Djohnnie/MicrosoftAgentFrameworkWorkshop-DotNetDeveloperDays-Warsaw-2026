# Exercise 406 - Real RAG with an In-Memory Vector Store

> **Part:** Part 4, Making agents reliable and production-ready  
> **Focus:** Chunk documents, embed and store them, retrieve by vector similarity, then generate a grounded answer  
> **Storage:** An in-process vector collection; no database server, Docker, or disk persistence

## What you'll build

A question-answering agent over three small text documents describing a
**fictional DevDays Buddy Lab Hub**. These are original demo policies, not the
real DeveloperDays agenda or venue rules.

```text
Startup:
documents/*.txt -> paragraph chunks -> Foundry embeddings -> in-memory vector collection

Each question:
question -> Foundry embedding -> cosine vector search -> top 3 excerpts
                                                       |
question + those excerpts ----------------------------> AIAgent -> answer with chunk citations
```

This is real **retrieval-augmented generation**: document and query embeddings
are produced by an embedding model, and the vector store performs similarity
search. It is not keyword matching, hand-picked context, or sending the whole
handbook to the answering model.

The in-memory provider is
**`CommunityToolkit.VectorData.InMemory`**, implementing the
`Microsoft.Extensions.VectorData` abstractions. It stores actual vectors and
records in RAM and performs exact vector comparisons. It is suitable for this
small demonstration, not a durable, indexed production database.

## Run it

Use the **.NET 10 SDK** and the
[Foundry setup from exercise 001](../exercise-001/README.md#1-set-your-microsoft-foundry-credentials).
This exercise needs **two deployments on the same Foundry resource**:

| Variable | Purpose |
| --- | --- |
| `FOUNDRY_ENDPOINT` | Resource or project endpoint mapped to the resource's `/openai/v1`. |
| `FOUNDRY_API_KEY` | API-key access to that resource. |
| `FOUNDRY_MODEL_DEPLOYMENT` | Chat deployment used to answer questions. |
| `FOUNDRY_EMBEDDING_DEPLOYMENT` | Embedding deployment producing **1536-dimensional** vectors, such as `text-embedding-3-small` with its default dimensions. |

The embedding setting is a **deployment name**, not necessarily the model's
catalog name. A chat deployment cannot substitute for an embedding deployment.
Unlike exercise 405, this does not require a hosted Prompt Agent or Entra
application credentials.

From the repository root, after configuring the standard variables:

```powershell
$env:FOUNDRY_EMBEDDING_DEPLOYMENT = "your-text-embedding-3-small-deployment"
dotnet run --project .\exercises\exercise-406\InMemoryRag.csproj
```

No credentials or launch profile are committed. The project copies its bundled
`documents` folder to the output directory, so running from the repository
root works.

At startup, the app embeds nine paragraphs and indexes them. Ask a question;
the console prints the retrieved chunk IDs, cosine scores, and text before
the agent's answer. Blank questions are skipped; EOF or case-insensitive `quit`
exits.

## 1. Chunk and embed the source documents

`LoadChunks` reads the three `.txt` files in a stable order. For this deliberately
small corpus, each blank-line-separated paragraph is a chunk. IDs such as
`equipment.txt#p1` identify a source file and paragraph.

This is intentionally transparent chunking, not a production document parser.
Each bundled paragraph is short and self-contained. Larger documents need
token-aware limits, appropriate overlap, and format-specific parsing.

`OpenAIClient.GetEmbeddingClient(...).AsIEmbeddingGenerator()` adapts the
embedding deployment to `IEmbeddingGenerator<string, Embedding<float>>`.
One batched `GenerateAsync` embeds the document paragraphs. The app validates
the count and vector dimensions, then upserts each record into the collection.

[`DocumentChunk.cs`](DocumentChunk.cs) declares:

| Attribute | Field |
| --- | --- |
| `VectorStoreKey` | Stable chunk ID. |
| `VectorStoreData` | Source filename and original paragraph text. |
| `VectorStoreVector(1536, ...)` | Numeric embedding, searched with cosine similarity. |

```csharp
using var vectorStore = new InMemoryVectorStore();
var collection = vectorStore.GetCollection<string, DocumentChunk>("handbook");
await collection.EnsureCollectionExistsAsync();
```

Changing the embedding model or dimensions requires re-embedding the documents
and a compatible collection definition. Do not mix vectors from different
embedding models, even if their lengths happen to match.

## 2. Retrieve before calling the agent

```csharp
ReadOnlyMemory<float> queryVector = await embeddingGenerator.GenerateVectorAsync(input);
await foreach (var result in collection.SearchAsync(queryVector, top: 3))
{
    // Display and collect the retrieved records.
}
```

Each question is embedded with the **same model** used for the documents.
The vector store finds the three most similar chunks. Retrieval happens in
application code on every question, not only if a model chooses to call a tool.

Scores describe vector similarity, **not answer confidence or factual
correctness**. Top-k search can return irrelevant neighbours for an unsupported
question. This example does not pretend that a universal score threshold
solves relevance or answerability.

## 3. Generate from the retrieved evidence

The app serializes only the retrieved IDs, source names, and text into the
answering prompt, alongside the original question. Vectors are not sent to
the answering model.

The agent instructions require answers grounded in those excerpts, citations
such as `[equipment.txt#p1]`, and an explicit admission when the handbook does
not provide the requested information. Retrieved text is reference data, not
permission to override instructions.

Every question uses a **fresh `AgentSession`**, so previous retrieval results
cannot silently become evidence for the next answer. Ask self-contained
questions; this exercise deliberately does not resolve conversational follow-ups.
`InMemoryChatHistoryProvider` and disabled server-side Responses storage match
the other local-history examples.

Grounding and citation instructions are model behavior, not a proof that every
claim is supported. Inspect the printed sources and compare the answer with
them. Retrieval quality, unsupported questions, and citation accuracy belong
in an evaluation set before using a larger corpus.

## Try it

1. Ask **"How can I borrow a laptop, and when must I return it?"** Look for
   `equipment.txt#p1`: the Orbit desk, blue badge, loan sheet, and 17:30 return.
2. Ask **"How can someone who cannot use stairs enter the building?"** The
   semantic match should retrieve the step-free east entrance and lift.
3. Ask **"When and where can I get help debugging?"** Check the clinic's
   14:00-15:00 time and Collaboration Room against `support.txt#p1`.
4. Ask **"What is the Wi-Fi password?"** The handbook does not supply one;
   the agent should say so rather than inventing a password.
5. Compare retrieved chunks between questions. Confirm only the top three
   excerpts, not all nine, appear in each answering request.
6. Edit a source paragraph and restart. The index is rebuilt from the files;
   old vectors do not survive the process.

The index is built before the first prompt, so even exiting immediately after
startup incurs the document-embedding request.

## In memory does not mean offline

The vector store and similarity search run locally, but **document embedding,
query embedding, and answer generation call Foundry**. Document text is sent
to the embedding deployment; retrieved text is sent to the chat deployment.
There is no fake embedding generator or local model in the exercise.

Restarting loses the collection and re-embeds the documents. Production systems
usually persist the index, track document changes, enforce document-level
authorization before exposing results, and evaluate chunking and retrieval.
Switching to a persistent provider also requires checking its filtering,
indexing, scoring, and operational behavior; test it against the real backend.

This contrasts with Lab 100's whole-agenda grounding, Lab 200's deterministic
MCP lookups, and Lab 400's managed File Search. It introduces no MCP server,
workflow, hosted agent definition, or full Semantic Kernel runtime.

Packages: Agent Framework **1.24.0**, OpenAI **2.14.0**, OpenAI adapter
**10.11.0**, and CommunityToolkit.VectorData.InMemory **1.0.1**. The provider
brings the vector-data abstractions transitively.

Microsoft Learn:
[vector databases for .NET AI apps](https://learn.microsoft.com/dotnet/ai/vector-stores/overview)
and [vector search](https://learn.microsoft.com/dotnet/ai/vector-stores/vector-search).
