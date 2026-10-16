using System.Security.Claims;
using Exercise404.Server;

var builder = WebApplication.CreateBuilder(args);
builder.WebHost.UseUrls(builder.Configuration["urls"] ?? "http://localhost:5404");
builder.Services.AddAuthentication(DemoAuthentication.Scheme)
    .AddBearerToken(DemoAuthentication.Scheme, options =>
    {
        options.BearerTokenExpiration = TimeSpan.FromMinutes(5);
    });
builder.Services.AddAuthorization();
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<UserContext>();
builder.Services.AddMcpServer()
    .WithHttpTransport(options => options.Stateless = true)
    .WithTools<SnackTools>();

var app = builder.Build();
app.UseAuthentication();
app.UseAuthorization();

app.MapPost("/auth", (SignInRequest request) =>
{
    var user = DemoAuthentication.Authenticate(request.Name, request.Password);
    if (user is null)
        return Results.Unauthorized();

    var identity = new ClaimsIdentity(
        [new Claim(ClaimTypes.NameIdentifier, user.Id), new Claim(ClaimTypes.Name, user.Name)],
        DemoAuthentication.Scheme);
    return Results.SignIn(new ClaimsPrincipal(identity), authenticationScheme: DemoAuthentication.Scheme);
});

app.MapMcp("/mcp").RequireAuthorization();
// HTTP and public demo passwords are for loopback workshop use only.
app.Run();
