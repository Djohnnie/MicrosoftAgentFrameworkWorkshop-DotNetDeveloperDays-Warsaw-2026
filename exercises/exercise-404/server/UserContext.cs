using System.Security.Claims;

namespace Exercise404.Server;

public sealed class UserContext(IHttpContextAccessor accessor)
{
    public string UserId
    {
        get
        {
            var principal = accessor.HttpContext?.User;
            if (principal?.Identity?.IsAuthenticated != true)
                throw new UnauthorizedAccessException("A validated bearer token is required.");
            return principal.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? throw new UnauthorizedAccessException("The token has no user identity.");
        }
    }
}
