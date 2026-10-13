internal static class FoundryEndpoint
{
    public static Uri Resolve(string endpoint)
    {
        if (!Uri.TryCreate(endpoint.Trim(), UriKind.Absolute, out var uri) ||
            uri.Scheme != Uri.UriSchemeHttps ||
            uri.UserInfo.Length > 0 || uri.Query.Length > 0 || uri.Fragment.Length > 0)
        {
            throw new ArgumentException("OPENAI_ENDPOINT must be an HTTPS URL without credentials, query parameters, or a fragment.");
        }

        var path = uri.AbsolutePath.TrimEnd('/');
        if (path.Equals("/openai/v1", StringComparison.OrdinalIgnoreCase))
            return new UriBuilder(uri) { Path = "/openai/v1" }.Uri;

        var isProjectEndpoint =
            uri.Host.EndsWith(".services.ai.azure.com", StringComparison.OrdinalIgnoreCase) &&
            path.StartsWith("/api/projects/", StringComparison.OrdinalIgnoreCase) &&
            path["/api/projects/".Length..] is { Length: > 0 } projectName &&
            !projectName.Contains('/');

        // API keys access resource deployments through OpenAI v1, not the project-management route.
        if (path.Length == 0 || isProjectEndpoint)
            return new UriBuilder(uri) { Path = "/openai/v1" }.Uri;

        throw new ArgumentException(
            "OPENAI_ENDPOINT must be a Foundry resource URL, an /openai/v1 URL, or a Foundry /api/projects/<project-name> URL.");
    }
}
