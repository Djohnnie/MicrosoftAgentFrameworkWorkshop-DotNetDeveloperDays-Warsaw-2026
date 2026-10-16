namespace Exercise404.Server;

public record DemoUser(string Id, string Name);
public record SignInRequest(string Name, string Password);

public static class DemoAuthentication
{
    public const string Scheme = "SnackBearer";

    // Public workshop credentials, not a production identity store.
    public static DemoUser? Authenticate(string? name, string? password) =>
        (name?.ToLowerInvariant(), password) switch
        {
            ("alice", "alice-snacks") => new("alice-001", "Alice"),
            ("bob", "bob-snacks") => new("bob-002", "Bob"),
            _ => null
        };
}