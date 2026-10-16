using System.ComponentModel;
using Microsoft.Extensions.AI;

namespace Exercise401;

#pragma warning disable MEAI001

public static class SnackTools
{
    [AIFunctionName("get_secret_snack")]
    [Description("Get the current user's secret snack. Supply their name: Alice or Bob.")]
    public static string GetSecretSnack(string userName)
    {
        Console.WriteLine($"[TOOL]: Trusting model-supplied name '{userName}' without authentication!");
        return userName.ToLowerInvariant() switch
        {
            "alice" => "Alice's secret snack: stroopwafels in the keyboard drawer.",
            "bob" => "Bob's secret snack: gummy bears behind the rubber duck.",
            _ => throw new ArgumentException("Unknown snack owner. Use Alice or Bob.", nameof(userName))
        };
    }
}