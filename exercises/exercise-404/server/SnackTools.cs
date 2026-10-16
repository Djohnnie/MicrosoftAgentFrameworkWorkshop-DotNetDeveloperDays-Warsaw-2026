using System.ComponentModel;
using ModelContextProtocol.Server;

namespace Exercise404.Server;

[McpServerToolType]
public sealed class SnackTools(UserContext userContext)
{
    [McpServerTool(Name = "get_secret_snack")]
    [Description("Get the authenticated user's secret snack. The server determines the owner from the bearer token.")]
    public string GetSecretSnack() => userContext.UserId switch
    {
        "alice-001" => "Alice's secret snack: stroopwafels in the keyboard drawer.",
        "bob-002" => "Bob's secret snack: gummy bears behind the rubber duck.",
        _ => throw new UnauthorizedAccessException("This user does not have a snack stash.")
    };
}
