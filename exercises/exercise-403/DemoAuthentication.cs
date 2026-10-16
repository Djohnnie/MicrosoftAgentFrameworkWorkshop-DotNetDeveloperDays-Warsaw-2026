namespace Exercise403;

public record DemoUser(string Id, string Name);

public static class DemoAuthentication
{
    // Public workshop credentials, not a production identity store.
    public static DemoUser? Authenticate(string? name, string? password) =>
        (name?.ToLowerInvariant(), password) switch
        {
            ("alice", "alice-snacks") => new("alice-001", "Alice"),
            ("bob", "bob-snacks") => new("bob-002", "Bob"),
            _ => null
        };
}
