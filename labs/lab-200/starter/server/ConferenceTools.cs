using ModelContextProtocol.Server;
using System.ComponentModel;

// Lab 200 - MCP tools (starter)
//
// TODO: Implement tools that use AgendaRepository:
// - conference name and description
// - workshop/conference dates
// - distinct speaker list and speaker lookup by first/last/full name
// - sessions for a date
// - session detail by title or by date and start time
//
// Return clear not-found/ambiguous messages. Keep lookups deterministic; try an
// LLM-based fuzzy-matching agent as an optional extension.
[McpServerToolType]
public sealed class ConferenceTools
{
    public ConferenceTools(AgendaRepository agenda)
    {
    }
}
