# Exercise 109 - Multimodal Audio

> **Part:** Part 1, From LLM calls to agents\
> **Focus:** Transcribe speech and translate spoken audio into English\
> **History:** Two independent audio requests; no conversation session

## What you'll build

Use the OpenAI audio SDK with a Foundry-hosted Whisper deployment to process
the same French recording twice. `TranscribeAudioAsync` returns text in the
spoken language; `TranslateAudioAsync` returns English text.

Like the reference, this is a direct audio-client example, **not an `AIAgent`**.
It introduces another model capability that an application can use. It does
not attach audio to a chat message, create an agent tool, generate speech, or
implement a realtime voice conversation.

## Run it

From the repository root:

```powershell
dotnet run --project .\exercises\exercise-109\MultimodalAudio.csproj
```

Use the **.NET 10 SDK** and the
[Foundry environment-variable setup from exercise 001](../exercise-001/README.md#1-set-your-microsoft-foundry-credentials):

| Variable | Value |
| --- | --- |
| `FOUNDRY_ENDPOINT` | Your Foundry resource or project endpoint |
| `FOUNDRY_API_KEY` | Your resource API key |
| `FOUNDRY_MODEL_DEPLOYMENT` | The name of your deployed **Whisper** model |

This exercise needs an audio deployment, not the chat or image deployment from
107-108. `whisper` is an example deployment name; use your actual deployment
name. Whisper supports both operations. Other transcription models are not
necessarily compatible with the translation endpoint. Deployment and regional
availability must be checked in Foundry.

An optional local `Properties\launchSettings.json` profile can supply these
variables and is Git-ignored. Set the deployment to your Whisper deployment
before running. Never commit credentials.

The program prints the transcription and translation, then exits. It uses
OpenAI 2.14.0, as in the other cloud exercises, and maps the endpoint to the
resource's `/openai/v1`. It does not use the Responses API, so it needs neither
`ResponsesClientOptions` nor the `OPENAI001` suppression.

## Transcribe the original language

```csharp
using (var audio = File.OpenRead(path))
{
    var response = await client.TranscribeAudioAsync(audio, Path.GetFileName(path));
    Console.WriteLine($"[ASSISTANT]: Transcription (original language): {response.Value.Text}");
}
```

The SDK uploads the audio as a file in a multipart request. Passing the file
name preserves its audio extension. Transcription produces text in the spoken
language; it is not translation.

## Translate into English

```csharp
using (var audio = File.OpenRead(path))
{
    var response = await client.TranslateAudioAsync(audio, Path.GetFileName(path));
    Console.WriteLine($"[ASSISTANT]: Translation (English): {response.Value.Text}");
}
```

Open a **new stream** so this independent request starts at the beginning of
the recording rather than at the end of the stream consumed by transcription.
The translation endpoint takes audio directly, not the previous transcript,
and translates into **English**, not an arbitrary target language.

Both operations return text. Neither produces an audio response or maintains
conversation history. A local recording is still uploaded to Foundry for
inference; obtain permission before sending private recordings.

## The bundled recording

`welcome-fr.wav` is an original short workshop greeting synthesized with the
Windows Microsoft Hortense French voice:

> Bonjour et bienvenue dans notre atelier. Nous allons construire des applications avec des agents et des outils.

An approximate English translation is:

> Hello and welcome to our workshop. We are going to build applications with agents and tools.

The project copies the WAV to its output directory and reads it through
`AppContext.BaseDirectory`, so the command works from the repository root.
No microphone, audio playback, or installed speech-synthesis voice is needed
to run the exercise.

## Try it

1. Listen to the bundled recording and compare both results with the text above.
2. Replace it with a short, non-sensitive recording in another supported language.
3. Compare accents, background noise, and punctuation. Check names and important
   details yourself rather than treating a fluent transcript as authoritative.

If changing the file name or format, update `Program.cs` and the project's
copy entry together. Whisper accepts formats including WAV and MP3; keep files
below its 25 MB upload limit. This intentionally small example does not split
long recordings or recover from failed requests. Missing configuration, file
errors, unsupported deployments, and service failures propagate as exceptions.

Adapted from the
[Ilionx DevDays multimodal audio example](https://github.com/Djohnnie/EnableGenAIUsingTheMicrosoftAgentFramework-IlionxDevDays-2026/blob/main/AgentFramework.MultiModal.Audio/Program.cs),
using the workshop's current SDK and Foundry configuration and an original WAV
instead of the reference MP3.

See Microsoft Learn's
[Whisper speech-to-text quickstart](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/whisper-quickstart).
