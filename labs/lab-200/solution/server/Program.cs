var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton(_ => AgendaRepository.Load());
builder.Services.AddMcpServer()
    .WithHttpTransport()
    .WithTools<ConferenceTools>();

var app = builder.Build();

app.MapMcp("/mcp");
app.Run("http://localhost:5286");
