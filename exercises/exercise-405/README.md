# Exercise 405 - Chat with a Microsoft Foundry Prompt Agent

> **Part:** Part 4, Making agents reliable and production-ready
>
> **Focus:** Authenticate an application and call an existing versioned Foundry agent
>
> **History:** One server-side conversation reused throughout the chat

## What you'll build

A .NET 10 console application keeps the interactive flow of the
[FoundryAgent reference sample](https://github.com/Djohnnie/EnableGenAIUsingTheMicrosoftAgentFramework-IlionxDevDays-2026/blob/main/AgentFramework.FoundryAgent/Program.cs):
authenticate with `ClientSecretCredential`, connect to an existing Foundry
agent, and reuse one session. Instead of the reference's obsolete classic
adapter, it uses `AIProjectClient.AsAIAgent(new AgentReference(name, version))`
from `Microsoft.Agents.AI.Foundry`.
It first asks "What are your capabilities?", prints the conversation ID, and
then accepts questions until EOF or case-insensitive `quit`. Blank input is skipped.
Replies use the workshop's `[USER]:` and `[ASSISTANT]:` labels instead of the
reference repository's shared console UI.

The model, instructions, and hosted tools live in Foundry; this program does
not create or modify the agent. Authentication and service errors surface as
exceptions rather than fabricated answers. The SDK acquires and refreshes
tokens; no explicit token request or token printing is needed.

**This sample uses the newer named/versioned Prompt Agent API**, not the
classic persistent-agent API. `PersistentAgentsClient.GetAIAgentAsync` is
obsolete; replacing it with another classic SDK call would not migrate the
agent. Create or migrate the agent in the new Foundry experience and use its
name (for example `developerdays`) and an existing version, not its old
`asst_...` ID. See Microsoft's
[Foundry Agent Service integration](https://learn.microsoft.com/agent-framework/integrations/by-component/agent-services/foundry).

## Get the tenant ID, client ID, and client secret

These credentials belong to an **app registration**, not to a Foundry API key.

1. In the [Azure portal](https://portal.azure.com), open **Microsoft Entra ID**.
   Switch to the directory containing your Foundry project if necessary.
2. Open **App registrations > New registration**. Enter a name such as
   `devdays-foundry-console`, select **Accounts in this organizational directory
   only**, leave the redirect URI empty, and select **Register**. This is
   application-to-service authentication, so no browser redirect is required.
3. On the registration's **Overview**, copy **Directory (tenant) ID** into
   `TENANT_ID` and **Application (client) ID** into `CLIENT_ID`. Do not use the
   application object ID or subscription ID.
4. Open **Certificates & secrets > Client secrets > New client secret**.
   Choose a description and a short expiry, then select **Add**.
5. Copy the secret's **Value** immediately into secure storage; this is
   `CLIENT_SECRET`, **not the Secret ID**. You cannot retrieve the value again
   after leaving the page. If lost or expired, create a replacement.

Registering the app creates its service principal but does not grant Foundry access.
On the **Foundry project** in the Azure portal, open **Access control (IAM) >
Add role assignment**, select **Foundry User** (formerly **Azure AI User**), then
**User, group, or service principal**. Search for your app registration, select
it, and finish **Review + assign**. Use project scope rather than granting
subscription-wide access. This workshop role includes more than just inference.
Assign the role to the app, not only to your personal account.

Creating registrations and assigning roles require appropriate directory and
Azure RBAC permissions; ask your administrator if these actions are unavailable.
Allow time for a new role assignment to propagate. Graph API permissions do not
replace Foundry's Azure RBAC role assignment.

See Microsoft's [app registration instructions](https://learn.microsoft.com/entra/identity-platform/howto-create-service-principal-portal)
and [Foundry agent access control](https://learn.microsoft.com/azure/foundry/agents/how-to/configure-agent).
For deployed applications, prefer managed identity over a stored client secret.

## Run it

Install the **.NET 10 SDK**. In the new Foundry experience, select an existing
Prompt Agent and copy its **name** and the **version** you want to use.
Copy the full **project endpoint** from the project overview, including
`/api/projects/<project-name>`.
Do not use the resource root, `/openai/v1`, or a named agent's Responses URL.

From the repository root in PowerShell:

```powershell
$env:TENANT_ID = "<directory-tenant-id>"
$env:CLIENT_ID = "<application-client-id>"
$env:FOUNDRY_ENDPOINT = "https://<resource-name>.services.ai.azure.com/api/projects/<project-name>"
$env:FOUNDRY_AGENT_NAME = "developerdays"
$env:FOUNDRY_AGENT_VERSION = "<existing-agent-version>"

# Prompt instead of putting the secret in shell history.
$env:CLIENT_SECRET = Read-Host "Client secret value" -MaskInput
try {
    dotnet run --no-launch-profile --project .\exercises\exercise-405\FoundryAgent.csproj
}
finally {
    Remove-Item Env:\CLIENT_SECRET
}
```

`--no-launch-profile` prevents older local profiles from overriding these values.
Unlike the reference's `FOUNDRY_URI`, this repository keeps `FOUNDRY_ENDPOINT`.
`FOUNDRY_API_KEY` and `FOUNDRY_MODEL_DEPLOYMENT` are not used, and `az login`
is not needed for the client-secret path.
`FOUNDRY_AGENT_ID` is no longer used. The version must already exist in the
same project; it is pinned explicitly rather than silently following updates.

An optional `Properties\launchSettings.json` can supply local settings and is
Git-ignored. Never commit secrets, print tokens, or put credentials in agent
messages. Rotate and remove workshop secrets when finished.

## Use managed identity instead (no client secret)

Managed identity changes **caller authentication**, not the agent definition
or version. It requires your application to run on an Azure host that supports managed
identity; a local console cannot use that host's identity directly.

1. In the Azure portal, open the resource **hosting this application** (for
   example an App Service, Function App, or VM). Under **Identity > System
   assigned**, set **Status** to **On** and save.
2. At the Foundry project's **Access control (IAM)**, assign **Foundry User**
   (formerly **Azure AI User**) to that host's managed identity. In the
   assignment wizard choose **Managed identity** and select the host.
   Enabling only the Foundry resource's own identity does not authenticate
   your console application.
3. In `Program.cs`, remove the `TENANT_ID`, `CLIENT_ID`, and `CLIENT_SECRET`
   reads and replace the credential construction with:

```csharp
var credential = new ManagedIdentityCredential();
var projectClient = new AIProjectClient(new Uri(endpoint), credential);
```

For a **user-assigned** identity, create it under **Managed Identities**, attach
it to the host under **Identity > User assigned**, grant that identity the
project role, and select it explicitly:

```csharp
var credential = new ManagedIdentityCredential(
    ManagedIdentityId.FromUserAssignedClientId("<managed-identity-client-id>"));
```

Its client ID is on the managed identity resource's **Overview**; **there is no
client secret**. Use the identity's principal/object ID for RBAC assignments,
not as the credential's client ID.

For **local development**, sign in with `az login`, grant your own account the
project role, and use `new AzureCliCredential()` instead. This authenticates as
you, not as the managed identity. `DefaultAzureCredential` can also discover
local developer credentials and managed identity in Azure, but an explicit
credential is clearer for deployed applications.

See [managed identity authentication in .NET](https://learn.microsoft.com/dotnet/azure/sdk/authentication/system-assigned-managed-identity).

## Follow the session

```csharp
FoundryAgent agent = projectClient.AsAIAgent(
    new AgentReference(agentName, agentVersion));
ChatClientAgentSession session = await agent.CreateConversationSessionAsync();
var response = await agent.RunAsync("What are your capabilities?", session);

Console.WriteLine($"Conversation: {session.ConversationId}");
```

`CreateConversationSessionAsync` explicitly creates a server-side conversation
visible in the Foundry project. Later `RunAsync` calls reuse that session, so the
agent can refer to earlier questions. This is not exercise 107's local
in-memory history. Each program run starts a fresh session; exiting does not
delete its stored conversation. Use non-sensitive workshop prompts and manage
retained conversations according to your project's policies.

The project pins Azure.Identity 1.21.0 and
Microsoft.Agents.AI.Foundry 1.24.0-preview.261006.1. Its transitive dependencies
supply Agent Framework 1.24.0 and Azure.AI.Projects 3.0.0-beta.3; no shared
console project or classic persistent-agent adapter is required. The Foundry
adapter and Projects SDK are preview packages; keep the compatible versions pinned.

## Try it

1. Compare the initial capabilities answer with the same agent version's playground.
2. Ask a question, then a follow-up referring to the previous answer.
3. Restart and compare the new conversation ID. Try blank input, `quit`, and
   piped input ending in EOF.
