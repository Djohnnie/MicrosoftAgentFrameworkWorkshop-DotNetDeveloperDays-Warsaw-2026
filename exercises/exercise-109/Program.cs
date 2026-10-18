using Azure.AI.OpenAI;
using System.ClientModel;

var endpoint = Environment.GetEnvironmentVariable("FOUNDRY_ENDPOINT")
    ?? throw new InvalidOperationException("Set FOUNDRY_ENDPOINT");
var key = Environment.GetEnvironmentVariable("FOUNDRY_API_KEY")
    ?? throw new InvalidOperationException("Set FOUNDRY_API_KEY");
var model = Environment.GetEnvironmentVariable("FOUNDRY_MODEL_DEPLOYMENT")
    ?? throw new InvalidOperationException("Set FOUNDRY_MODEL_DEPLOYMENT");

var openAIClient = new AzureOpenAIClient(new Uri(endpoint), new ApiKeyCredential(key));
var client = openAIClient.GetAudioClient("whisper");

var path = Path.Combine(AppContext.BaseDirectory, "welcome-fr.wav");
Console.WriteLine("[USER]: Transcribe the French audio, then translate it into English.");

using (var audio = File.OpenRead(path))
{
    var response = await client.TranscribeAudioAsync(audio, Path.GetFileName(path));
    Console.WriteLine($"[ASSISTANT]: Transcription (original language): {response.Value.Text}");
}

using (var audio = File.OpenRead(path))
{
    var response = await client.TranslateAudioAsync(audio, Path.GetFileName(path));
    Console.WriteLine($"[ASSISTANT]: Translation (English): {response.Value.Text}");
}