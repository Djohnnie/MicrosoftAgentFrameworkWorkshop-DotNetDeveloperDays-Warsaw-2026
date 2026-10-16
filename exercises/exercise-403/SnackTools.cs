using System.ComponentModel;
using Microsoft.Extensions.AI;
using Microsoft.Extensions.DependencyInjection;

namespace Exercise403;

#pragma warning disable MEAI001

public static class SnackTools
{
    [AIFunctionName("get_secret_snack")]
    [Description("Get the authenticated user's secret snack. The application determines the owner.")]
    public static string GetSecretSnack(IServiceProvider services)
    {
        var userContext = services.GetRequiredService<UserContext>();
        var user = userContext.User
            ?? throw new UnauthorizedAccessException("Sign in using /auth before opening a snack stash.");
        Console.WriteLine($"[TOOL]: Reading the DI user context for {user.Name}, not a model argument.");
        return user.Id switch
        {
            "alice-001" => "Alice's secret snack: stroopwafels in the keyboard drawer.",
            "bob-002" => "Bob's secret snack: gummy bears behind the rubber duck.",
            _ => throw new UnauthorizedAccessException("This user does not have a snack stash.")
        };
    }
}
