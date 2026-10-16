using System.Globalization;
using System.Text.Json;
using ModelContextProtocol.Client;
using ModelContextProtocol.Protocol;

public static class ConferenceAgendaClient
{
    public static async Task<SessionOption[]> LoadAsync(
        McpClient client, DateOnly date, CancellationToken cancellationToken)
    {
        // Unlike Lab 200's chat agent, application code selects this tool and its date argument.
        CallToolResult result = await client.CallToolAsync("get_sessions_for_date",
            new Dictionary<string, object?> { ["date"] = date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture) },
            cancellationToken: cancellationToken);
        if (result.IsError == true)
            throw new InvalidOperationException("The MCP agenda lookup failed: "
                + string.Join("\n", result.Content.OfType<TextContentBlock>().Select(item => item.Text)));

        // This lab's server puts one JSON array in an MCP text block; [] is a valid no-sessions result.
        // An MCP error or malformed payload is not equivalent to an empty agenda.
        string json = result.Content.OfType<TextContentBlock>().Single().Text;
        return JsonSerializer.Deserialize<SessionOption[]>(json, JsonSerializerOptions.Web)
            ?? throw new InvalidOperationException("The MCP server returned an empty response instead of a session array.");
    }
}
