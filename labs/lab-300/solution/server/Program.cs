var builder = WebApplication.CreateBuilder(args);

// Load the embedded snapshot once per server process; no Foundry credentials or inference are needed here.
builder.Services.AddSingleton(_ => AgendaRepository.Load());
builder.Services.AddMcpServer()
    .WithHttpTransport()
    .WithTools<ConferenceTools>();

var app = builder.Build();
// The console client reaches the tools over Streamable HTTP, not through a project reference.
app.MapMcp("/mcp");
app.Run("http://localhost:5287");
