# Exercise 404 - Authenticate Across an MCP Boundary

> **Part:** Part 4, Making agents reliable and production-ready  
> **Focus:** Authenticate an MCP client and derive server-side user context from a validated token  
> **Projects:** `server\SnackMcpServer.csproj` and `client\SnackAgentWithAuthenticatedMcp.csproj`

The [Secret Snack Stash from 403](../exercise-403/README.md) now lives in a
separate ASP.NET Core MCP server. The console's `/auth` command posts demo
credentials to the server's `/auth` endpoint. The server checks them and uses
ASP.NET Core `AddBearerToken` / `Results.SignIn` to issue a real, protected,
opaque access token with a **five-minute lifetime**.

The client adds it to the HTTP `Authorization: Bearer ...` header on its MCP
transport. The token is never a tool argument, prompt, or console output.
`/mcp` requires authorization: missing, malformed, tampered, and expired tokens
are rejected by the authentication middleware.

The tool still has no arguments. A request-scoped `UserContext` reads the
validated principal's `NameIdentifier` claim through `IHttpContextAccessor`.
Constructor injection supplies it to the MCP tool, which opens only the
authenticated owner's stash. The server uses **stateless Streamable HTTP**,
so each request has its own context rather than retaining one user's principal
in a long-lived shared MCP session.

## Run it

Use the **.NET 10 SDK**. Open two PowerShell terminals at the repository root.
The server needs no Foundry configuration:

```powershell
dotnet run --project .\exercises\exercise-404\server\SnackMcpServer.csproj
```

It binds to `http://localhost:5404` by default. Keep it running.
In the second terminal, configure the tool-calling Foundry deployment using
the [401 setup](../exercise-401/README.md#run-it), then run:

```powershell
dotnet run --project .\exercises\exercise-404\client\SnackAgentWithAuthenticatedMcp.csproj
```

Type `/auth` and answer the separate console prompts with `Alice` /
`alice-snacks` or `Bob` / `bob-snacks`. The client discovers the authenticated
server's tool and prints its schema. Ask: "What is my secret snack?"

`/auth` always discards the previous connection and conversation before a new
sign-in attempt. Failed sign-in leaves you signed out. `/logout` discards the
token-bearing MCP connection and conversation locally. `quit` or EOF exits;
blank input is skipped. Stop the server with Ctrl+C.
Optional local launch profiles are Git-ignored.

If port 5404 is busy, use matching server and client settings:

```powershell
# Server terminal
dotnet run --project .\exercises\exercise-404\server\SnackMcpServer.csproj -- --urls http://localhost:5405

# Client terminal
$env:SNACK_SERVER_URL = "http://localhost:5405"
dotnet run --project .\exercises\exercise-404\client\SnackAgentWithAuthenticatedMcp.csproj
```

## Try the boundary

1. Without a bearer token, this request must report HTTP 401:

   ```powershell
   curl.exe -i -X POST http://localhost:5404/mcp -H "Content-Type: application/json" -d '{}'
   ```

   Stateless MCP uses POST; an unauthenticated GET reports 405, not 401.

2. Sign in as Alice and ask to open Bob's stash. The server can only return
   Alice's snack, regardless of model-supplied names or IDs.
3. Use `/auth` to sign in as Bob and ask again. A fresh conversation and
   connection now use Bob's validated identity.
4. Wait more than five minutes and ask for a new lookup. The server rejects
   the expired token; use `/auth` again. Tokens are not refreshed automatically.

The [automated boundary checks](../../tests/AuthenticationExercises/README.md)
exercise real MCP discovery/calls, invalid tokens, concurrent Alice/Bob clients,
forged identity arguments, and the console sign-in lifecycle without Foundry.

## What this is, and is not

The token protection and validation are real ASP.NET Core authentication, but
the credential store and login flow are **public workshop demos**. Password
input is visible; never use real credentials. HTTP is acceptable only for this
loopback exercise. Do not bind it to a public interface or deploy these accounts.
Treat bearer tokens as secrets: possession grants access.

ASP.NET Core protects these opaque tokens using Data Protection, not a JWT
signing key embedded in source. This is not an OAuth/OIDC authorization server
and does not implement MCP's OAuth discovery, browser/PKCE flow, consent,
refresh, or revocation. A real deployment should use HTTPS, an identity provider,
MCP-compatible OAuth authorization, correctly scoped/audience-bound access
tokens, and appropriate resource policies. Local `/logout` does not revoke
an already-issued token; a copied token remains valid until expiry.

User context is server-side and request-scoped, never a mutable singleton.
Foundry credentials stay in the client, and MCP access tokens go only to the
MCP server. Selected snack results and local conversation history are still
sent to Foundry for inference; Responses storage is disabled.

Read [ASP.NET Core bearer tokens](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/identity-api-authorization)
and [MCP authorization](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization).
