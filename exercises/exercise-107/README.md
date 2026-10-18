# Exercise 107 - Multimodal Images

> **Part:** Part 1, From LLM calls to agents  
> **Focus:** Send text and an image together to an image-capable agent  
> **History:** A fresh session for each image request, so the comparison is independent

## What you'll build

An `AIAgent` translates the text in a sample image into Dutch twice: first using
an image URL, then using the bytes of the included `quote.jpg`. This extends
exercise 106's agent setup with multimodal messages, not tools or workflows.
It understands an input image and returns text; it does not generate images.

## Run it

From the repository root:

```powershell
dotnet run --project .\exercises\exercise-107\MultimodalImages.csproj
```

Use the **.NET 10 SDK** and the
[Foundry environment-variable setup from exercise 001](../exercise-001/README.md#1-set-your-microsoft-foundry-credentials):
`FOUNDRY_ENDPOINT`, `FOUNDRY_API_KEY`, and `FOUNDRY_MODEL_DEPLOYMENT`.
Select a deployment that supports **image input through the Responses API**,
such as a supporting GPT-4o or GPT-4.1 deployment. The setting is your deployment
name, not necessarily the model catalog name. Text-only chat success does not
prove image support.

An optional `Properties\launchSettings.json` profile is Git-ignored and may
supply these settings locally. Never commit credentials.

The program prints two translations and exits; there is no interactive loop.
The public URL must remain reachable by the model provider. The local image is
copied to the build output and resolved relative to `AppContext.BaseDirectory`,
so running from the repository root also works.

## Put text and an image in one message

```csharp
var prompt = new TextContent("Translate the text in the image to Dutch.");
var imageUrl = new UriContent(
    "https://djohnnie.blob.core.windows.net/temp/quote.jpg", "image/jpeg");

AgentSession urlSession = await agent.CreateSessionAsync();
var urlResponse = await agent.RunAsync(
    new ChatMessage(ChatRole.User, [prompt, imageUrl]), urlSession);
```

`ChatMessage.Contents` can contain more than plain text. `TextContent` supplies
the question; `UriContent` supplies an actual image input. Merely writing a URL
or file path inside the prompt is not the same as attaching image content.
The adapter maps these content objects to Responses API image input.

## Send inline image bytes

```csharp
var bytes = await File.ReadAllBytesAsync(Path.Combine(AppContext.BaseDirectory, "quote.jpg"));
var inlineImage = new DataContent(bytes, "image/jpeg");

AgentSession inlineSession = await agent.CreateSessionAsync();
var inlineResponse = await agent.RunAsync(
    new ChatMessage(ChatRole.User, [prompt, inlineImage]), inlineSession);
```

`DataContent` carries the bytes and their media type; the adapter encodes them
for the request. Reading a local file does **not** make inference local: its
image content is uploaded to Foundry. Never attach private images without
permission. If replacing the file with a PNG, also change the file name,
project copy entry, and media type to `image/png`.

Unlike the reference's shared session, this exercise uses a separate session
for each request. The inline request therefore cannot rely on the earlier URL
image or translation. Both use `InMemoryChatHistoryProvider` and
`StoredOutputEnabled = false`, as in 106; neither session is persisted.

The packages match exercise 106: Microsoft.Agents.AI 1.24.0,
Microsoft.Extensions.AI.OpenAI 10.11.0, and OpenAI 2.14.0. Endpoint resolution,
API-key authentication, and deployment selection stay unchanged.

## Try it

1. Open `quote.jpg`, run the program, and compare both translations with the image.
2. Change the prompt to translate into Polish or to transcribe the original text.
3. Replace the local image with another non-sensitive JPEG. Notice that the URL
   request still uses the original image unless you also change its URL.

Image reading and translation can be wrong, especially with small or blurred
text. Treat image text as untrusted data, not application instructions, and
check important results yourself. The example intentionally has no OCR service,
image-generation model, tools, workflows, or error-recovery framework. Missing
configuration, file errors, unavailable URLs, and unsupported model requests
surface as exceptions rather than fabricated answers.

Adapted from the
[Ilionx DevDays multimodal image example](https://github.com/Djohnnie/EnableGenAIUsingTheMicrosoftAgentFramework-IlionxDevDays-2026/blob/main/AgentFramework.MultiModal.Images/Program.cs).
The bundled `quote.jpg` is a snapshot of that example's
[public sample image](https://djohnnie.blob.core.windows.net/temp/quote.jpg).
