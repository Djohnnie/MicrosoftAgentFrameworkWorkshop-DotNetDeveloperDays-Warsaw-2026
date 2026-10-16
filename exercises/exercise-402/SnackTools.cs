using System.ComponentModel;
using Microsoft.Extensions.AI;

namespace Exercise402;

#pragma warning disable MEAI001

public static class SnackTools
{
    [AIFunctionName("get_secret_snack")]
    [Description("Get the signed-in user's secret snack. Supply the userId provided by the application.")]
    public static string GetSecretSnack(string userId)
    {
        Console.WriteLine($"[TOOL]: Trusting model-supplied userId '{userId}' without an ownership check!");
        return userId switch
        {
            "alice-001" => "Alice's secret snack: stroopwafels in the keyboard drawer.",
            "bob-002" => "Bob's secret snack: gummy bears behind the rubber duck.",
            _ => throw new ArgumentException("Unknown snack owner.", nameof(userId))
        };
    }
}
