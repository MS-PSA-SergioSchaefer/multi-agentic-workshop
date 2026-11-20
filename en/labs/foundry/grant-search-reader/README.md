# Fix Foundry knowledge-base access with Azure CLI

Use this guide when a Foundry agent, such as `AndersAgent`, fails while calling
an Azure AI Search knowledge base through an MCP connection that uses
`ProjectManagedIdentity` authentication.

One possible symptom is HTTP 400 with:

> tool_user_error: A user error occurred while executing a tool call.

This error alone does **not** establish the cause. This guide addresses the case
where the Foundry project's system-assigned managed identity is missing Search
read permissions. A successful Search query by your own user does not prove
that the project identity has access.

The repair is to assign **Search Index Data Reader** to the **project managed
identity**, scoped to the connected Search service, only if that access is
missing. It does not change the agent definition, connection, model, or data.

## Prerequisites and safety

- Azure CLI and PowerShell 7 or later. Examples use PowerShell syntax, not Bash.
- Access to read the Foundry project, connection, and Search service, and to
  invoke the agent for verification.
- To create the assignment, `Microsoft.Authorization/roleAssignments/write`
  at the Search scope, for example through Owner, User Access Administrator,
  or Role Based Access Control Administrator, subject to any assignment conditions.
- A Search service configured to accept Microsoft Entra ID authentication.
- A system-assigned project identity and a connection using
  `ProjectManagedIdentity`. Other authentication modes require a different diagnosis.

Azure operations use `az`; PowerShell supplies variables and a temporary JSON
request file. No SDK, manually acquired token, or portal step is required.
Run each command separately and stop on failure. Do not proceed with empty
resource IDs or an empty principal ID.

All angle-bracket values below are placeholders. Replace them locally and do
not commit the populated values or raw command output. Resource identifiers
are not credentials, but can reveal tenant and infrastructure details. Never
publish tokens, keys, connection secrets, retrieved content, or private source URLs.

Preview APIs can change. The versions below are examples; confirm support for
your environment against the linked documentation before running them.
Examples assume Azure public cloud; sovereign clouds require their own service
endpoints and token audiences.

## 1. Configure your environment and sign in

The Foundry project and Search service can be in different resource groups or
subscriptions. They must use a compatible tenant/identity configuration.

```powershell
$TenantId = "<tenant-id>"
$FoundrySubscriptionId = "<foundry-subscription-id>"
$FoundryResourceGroup = "<foundry-resource-group>"
$FoundryAccountName = "<foundry-account-name>"
$ProjectName = "<foundry-project-name>"
$ProjectEndpoint = "https://<foundry-service-name>.services.ai.azure.com/api/projects/<foundry-project-name>"
$ConnectionName = "<knowledge-base-connection-name>"
$SearchSubscriptionId = "<search-subscription-id>"
$SearchResourceGroup = "<search-resource-group>"
$SearchServiceName = "<search-service-name>"
$AgentName = "<agent-name>"
$AgentApiVersion = "2025-11-15-preview"
$ManagementApiVersion = "2025-06-01"

$ProjectResourceId = "/subscriptions/$FoundrySubscriptionId/resourceGroups/$FoundryResourceGroup/providers/Microsoft.CognitiveServices/accounts/$FoundryAccountName/projects/$ProjectName"
$SearchResourceId = "/subscriptions/$SearchSubscriptionId/resourceGroups/$SearchResourceGroup/providers/Microsoft.Search/searchServices/$SearchServiceName"
```

Copy the project endpoint from your project's configuration. Do not substitute
the Search service name for the Foundry account name in the project resource ID.

```powershell
az login --tenant $TenantId
az account set --subscription $FoundrySubscriptionId
az account show --query "{subscription:name,subscriptionId:id,tenantId:tenantId}" -o json
```

Confirm the selected tenant and subscription locally; do not publish the output.

## 2. Inspect the agent's knowledge-base tool

```powershell
az rest --method get --url "$ProjectEndpoint/agents/${AgentName}?api-version=$AgentApiVersion" --resource https://ai.azure.com --query "{name:name,version:versions.latest.version,tools:versions.latest.definition.tools}" -o json
```

Confirm that the agent version you intend to test has an MCP tool referencing
`$ConnectionName`. Record that version for step 6. Do not assume the latest
version is the same as the one that failed. No particular model is required
by this permission repair.

## 3. Confirm the connection and project identity

```powershell
az rest --method get --url "https://management.azure.com$ProjectResourceId/connections/${ConnectionName}?api-version=$ManagementApiVersion" --query "properties.{authType:authType,audience:audience,target:target}" -o json
```

Check locally that:

- `authType` is `ProjectManagedIdentity`.
- `audience` is `https://search.azure.com`.
- `target` points to the intended Search service's knowledge-base MCP endpoint.

If these differ, stop and investigate the connection. Do not grant access to a
service that is not the actual target. Treat the returned endpoint as
environment-specific information when sharing diagnostic output.

Read the project's current identity, not an ID copied from an earlier deployment:

```powershell
$ProjectPrincipalId = az rest --method get --url "https://management.azure.com${ProjectResourceId}?api-version=$ManagementApiVersion" --query identity.principalId -o tsv
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($ProjectPrincipalId)) { throw "Cannot read the project's system-assigned managed identity. Stop before assigning permissions." }
```

Do not use the parent Foundry account identity, an agent instance identity, or
your own user identity. Re-run this step if the project is recreated.

Confirm the Search resource exists in the configured subscription:

```powershell
az resource show --ids $SearchResourceId --subscription $SearchSubscriptionId --query "{name:name,type:type}" -o json
```

## 4. Inspect existing Search permissions

```powershell
az role assignment list --subscription $SearchSubscriptionId --scope $SearchResourceId --include-inherited --query "[?principalId=='$ProjectPrincipalId'].{role:roleDefinitionName,scope:scope}" -o json
```

If `Search Index Data Reader` is already present at this scope or inherited,
skip step 5. If another role grants the required read access, investigate the
remaining failure instead of adding redundant permissions. An empty result
means no matching assignments were returned; ensure your account can read
role assignments before drawing conclusions.

## 5. Grant the missing read-only permission

**Run only after confirming the identity, target service, and missing access.**

```powershell
az role assignment create --subscription $SearchSubscriptionId --assignee-object-id $ProjectPrincipalId --assignee-principal-type ServicePrincipal --role "Search Index Data Reader" --scope $SearchResourceId --query "{roleDefinitionId:roleDefinitionId,scope:scope}" -o json
```

This grants read access at the Search-service scope, not just to one knowledge
base or index. Other agents using the same project identity share that access.
Confirm this scope is appropriate for the data in the service.

Allow several minutes for RBAC propagation before retrying. Do not enable API
keys, disable TLS validation, widen network access, or grant Contributor as a
workaround for this error.

Verify the assignment using the list command from step 4. A visible assignment
does not by itself prove that data-plane authorization has propagated.

## 6. Test the agent with your own knowledge-base question

Use the agent version inspected in step 2 and a non-sensitive question whose
answer and expected source you already know. The request may incur model and
Search usage charges. The response can contain private retrieved content and
source URLs; inspect it locally.

The temporary UTF-8 JSON file avoids shell-specific JSON quoting issues.
PowerShell removes it after the request, including when the command fails.

```powershell
$AgentVersion = "<agent-version>"
$TestQuestion = "<question answerable from your knowledge base; request a source citation>"
$RequestBody = @{
    agent_reference = @{
        type = "agent_reference"
        name = $AgentName
        version = $AgentVersion
    }
    input = $TestQuestion
    tool_choice = "required"
} | ConvertTo-Json -Depth 5

$RequestFile = [System.IO.Path]::GetTempFileName()
try {
    Set-Content -LiteralPath $RequestFile -Value $RequestBody -Encoding utf8NoBOM
    az rest --method post --url "$ProjectEndpoint/openai/responses?api-version=$AgentApiVersion" --resource https://ai.azure.com --headers "Content-Type=application/json" --body "@$RequestFile" --query "{id:id,status:status,error:error,calls:output[?type=='mcp_call'].{name:name,error:error},messages:output[?type=='message'].content}" -o json
    if ($LASTEXITCODE -ne 0) { throw "Agent verification request failed." }
} finally {
    Remove-Item -LiteralPath $RequestFile -Force
}
```

Azure CLI obtains the token for `https://ai.azure.com` automatically. Requiring
a tool call is useful for this test, but can invoke another configured tool;
verify that the expected knowledge-base retrieval tool actually ran.

Check all of the following:

- `status` is `completed` and `error` is `null`.
- `calls` includes the expected retrieval tool, such as
  `knowledge_base_retrieve`, with no error.
- The answer matches the known content in your knowledge base.
- The message's structured annotations include the expected source citation,
  such as a `url_citation`, where supported by your retrieval configuration.

Do not treat HTTP success alone as proof that retrieval worked. For a language
check, repeat with an equivalent question in the language you need to support.

## If the test still fails

After allowing for propagation, recheck the agent version, connection target,
authentication mode, current project identity, and effective Search permissions.
If these are correct, investigate Search authentication settings, network
restrictions, knowledge-base configuration, indexing health, and API compatibility.
Indexer success does not prove the agent identity can read the indexed content.
Indexer-status checks also require separate permissions for the signed-in user;
do not grant the agent additional roles solely for those diagnostic checks.

Retain request IDs and detailed errors privately for support. Share only
sanitized excerpts, replacing tenant/subscription/principal IDs, resource names,
endpoints, source URLs, and document content. Do not broaden permissions without
evidence of a specific missing operation.

## References

- [Project identity and role requirements for agentic retrieval](https://learn.microsoft.com/en-us/azure/search/agentic-retrieval-how-to-create-pipeline)
- [Foundry MCP authentication](https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/mcp-authentication)
- [Azure AI Search role-based access control](https://learn.microsoft.com/en-us/azure/search/search-security-rbac)