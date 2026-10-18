using Microsoft.Agents.AI.Foundry;

public static class FoundrySessionPicker
{
    public static Task<CandidateSelection> PickAsync(
        FoundryAgent agent, PlanRequest request, CancellationToken cancellationToken)
    {
        // TODO: CreateConversationSessionAsync, then RunAsync with the request and output contract.
        // Use ChatClientAgentRunOptions.ChatOptions.ResponseFormat =
        // ChatResponseFormat.ForJsonSchema<CandidateSelection>() so the hosted result includes sessionId.
        // Explain the exact date|HH:mm|room ID rule in the prompt; do not rely only on portal settings.
        // Deserialize response.Text into CandidateSelection. Surface malformed JSON explicitly.
        // Never reuse a previous plan's conversation or send the agenda file from here.
        throw new NotImplementedException("Connect the Foundry Session Picker.");
    }
}
