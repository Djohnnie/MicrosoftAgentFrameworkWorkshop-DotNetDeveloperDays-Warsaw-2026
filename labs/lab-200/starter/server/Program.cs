// Lab 200 - MCP server (starter)
//
// TODO 1: Register AgendaRepository as a singleton. It should load and parse the
//         embedded agenda.json resource once when the server starts.
// TODO 2: Register an MCP server with HTTP transport and ConferenceTools.
// TODO 3: Build the app, map the MCP endpoint at "/mcp", and listen on port 5286.

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => "DevDays Buddy MCP server starter");
app.Run("http://localhost:5286");
