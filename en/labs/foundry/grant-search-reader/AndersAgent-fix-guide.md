# Foundry agent: diagnosis, repair, and testing

This guide covers a potential permission failure for a Foundry agent, such as
`AndersAgent`, using an Azure AI Search knowledge base through an MCP connection
authenticated with `ProjectManagedIdentity`.

HTTP 400 with `tool_user_error` or a failure during `mcp_list_tools` can indicate
a tool integration problem, but does **not** prove that Search permissions are
missing. Confirm the connection, identity, and effective permissions first.

When the project's system-assigned managed identity lacks Search read access,
assigning **Search Index Data Reader** at the connected Search-service scope
can resolve the issue after RBAC propagation. This repair does not require
changing the agent definition, model, connection, or indexed data.

## 1. Configure and diagnose

Follow steps 1-4 of the [Azure CLI repair guide](README.md) in
PowerShell 7 or later with Azure CLI installed. That guide provides reusable
configuration variables, sign-in commands, connection inspection, current
project identity discovery, and checks for existing or inherited Search roles.
Keep the same PowerShell session for the examples below.

Before granting permissions, confirm all of the following:

- The selected tenant and subscriptions belong to your intended environment.
- The agent version you intend to test references the expected MCP connection.
- The connection uses `ProjectManagedIdentity`, the Search token audience
  `https://search.azure.com`, and the intended knowledge-base MCP endpoint.
- `$ProjectPrincipalId` is the current project's system-assigned identity, not
  the parent Foundry account identity, an agent identity, or your user identity.
- `$SearchResourceId` identifies the actual connected Search service. Foundry
  and Search may be in different resource groups or subscriptions.
- The project identity does not already have the required read access.

Stop if authentication uses a different identity mechanism or if any resource
or identity lookup fails. A successful Search query as your own user does not
prove that the project identity can read the service.

All angle-bracket values in these guides are placeholders. Replace them only
locally; do not commit populated commands or raw diagnostic output. Examples
assume Azure public cloud. Confirm supported API versions and use the appropriate
endpoints and audiences for your cloud.

## 2. Apply the read-only permission repair

Creating a role assignment requires
`Microsoft.Authorization/roleAssignments/write` at the Search scope, for example
through Role Based Access Control Administrator, User Access Administrator, or
Owner, subject to any assignment conditions.

**Run only if the required access is missing.** Use this command instead of the
create command in step 5 of the CLI guide if you want to capture the exact
assignment ID for a possible rollback:

```powershell
$CreatedRoleAssignmentId = az role assignment create `
    --subscription $SearchSubscriptionId `
    --assignee-object-id $ProjectPrincipalId `
    --assignee-principal-type ServicePrincipal `
    --role 'Search Index Data Reader' `
    --scope $SearchResourceId `
    --query id -o tsv
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($CreatedRoleAssignmentId)) {
    throw 'Unable to create or confirm the role assignment. Stop and inspect the error.'
}
```

Record the assignment ID privately and whether this run created it. Do not mark
an assignment that already existed as newly created.

The role grants read access at the Search-service scope, not just to one index
or knowledge base. Other agents using the same project identity share that
access. Confirm that this scope is appropriate for the service's data.

Allow several minutes for RBAC propagation, verify the assignment using step 4
of the CLI guide, and retry. Do not enable API keys, disable TLS validation,
widen network access, or grant Contributor to work around this error.

## 3. Check indexing if retrieval still fails

These optional checks use the **signed-in user's** permissions, not the agent
identity. Indexer-status inspection requires separate permissions, typically
Search Service Contributor; document count queries require Search data read
access. Use an appropriately authorized diagnostic account. Do not grant the
agent extra roles solely to run these checks.

Use your actual indexer and index names; a knowledge-base name need not match
either. The API version below is an example and must be supported by your service.

```powershell
$SearchEndpoint = "https://${SearchServiceName}.search.windows.net"
$IndexerName = '<indexer-name>'
$IndexName = '<index-name>'
$SearchApiVersion = '2026-08-01-preview'

az rest --method get `
    --url "$SearchEndpoint/indexers/${IndexerName}/status?api-version=$SearchApiVersion" `
    --resource https://search.azure.com `
    --query 'lastResult.{status:status,itemsProcessed:itemsProcessed,itemsFailed:itemsFailed,errors:errors}' -o json
if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect indexer status.' }

az rest --method get `
    --url "$SearchEndpoint/indexes/${IndexName}/docs/`$count?api-version=$SearchApiVersion" `
    --resource https://search.azure.com
if ($LASTEXITCODE -ne 0) { throw 'Unable to read the document count.' }
```

Azure CLI obtains tokens automatically; do not print or save access tokens.
Review the indexing status, errors, and expected document coverage locally.
There is no universal expected document or chunk count. Indexing success does
not prove that the agent identity can read the indexed content.

## 4. Run a repeatable live smoke test

Use step 6 of the [Azure CLI repair guide](README.md) with your
project endpoint, agent name, and intended agent version. Choose a non-sensitive
question with a known answer and source from your own knowledge base. For a
language check, repeat with an equivalent question in the required language.
Live calls consume model/Search capacity and may incur usage charges.

Each test should:

- Finish with response status `completed` and no response error.
- Execute the expected retrieval tool, such as `knowledge_base_retrieve`,
  without an MCP call error. Another tool call is not proof of retrieval.
- Return an answer consistent with the known source content.
- Include the expected structured source citation, where supported by your
  retrieval configuration.

HTTP success alone is insufficient. These are integration smoke tests, not
exhaustive evaluations of answer accuracy.

The neighboring [test script](Test-AndersAgent.ps1) is a scenario-specific
example, not a generic test runner. Its endpoint, agent, and version parameters
do not override its fixed test questions or citation assertions. Review and
adapt those assumptions locally before using it with a different knowledge base;
use the CLI test above for a reusable workflow without editing that script.

Treat all test output and saved reports as potentially confidential. Answers,
citations, response IDs, timestamps, and endpoints may disclose document content
or infrastructure even when no token or raw retrieved chunk is included.

## 5. Confirm in the Foundry portal

1. Open [Microsoft Foundry](https://ai.azure.com/) and select your project.
2. Open **Agents**, select your agent, and select the version under test.
3. Start a new playground conversation.
4. Ask the same non-sensitive knowledge-base question used in the smoke test
   and request a source citation.
5. Inspect the tool trace for successful knowledge-base retrieval and confirm
   the answer matches and cites the expected source.

Portal labels can change. If failure persists after propagation, retain the
request/response ID privately and inspect the tool trace. Recheck the connection
identity, target, audience, agent version, and effective permissions. Then
investigate Search authentication settings, network restrictions, knowledge-base
configuration, indexing health, and API compatibility as applicable.

For a TLS connection reset, investigate client networking, proxy configuration,
and service availability. Do not bypass certificate validation or alter RBAC
to resolve a transport failure.

## Rollback

Rollback is optional and removes access. Only delete the exact assignment
confirmed to have been newly created by your repair, with authorization to
remove it. Do not delete pre-existing or inherited assignments. Other agents
sharing the project identity may also lose retrieval access.

Inspect the captured assignment ID privately and confirm its principal, role,
and scope against step 2 before running:

```powershell
if ([string]::IsNullOrWhiteSpace($CreatedRoleAssignmentId)) {
    throw 'No repair assignment ID recorded. Stop; do not guess an assignment ID.'
}
az role assignment delete --subscription $SearchSubscriptionId --ids $CreatedRoleAssignmentId
if ($LASTEXITCODE -ne 0) { throw 'Role assignment deletion failed.' }
```

No agent-version rollback is needed if only the role assignment was changed.
Confirm the remaining permissions using step 4 of the CLI guide.

## Sharing diagnostics safely

Before publishing excerpts, redact tenant/subscription/principal IDs, assignment
and response IDs, resource names, endpoints, private source URLs, document
content, and personal information. Never share access tokens, keys, connection
secrets, or unsanitized reports and screenshots. Resource IDs are not credentials,
but can still reveal environment details. Review companion files separately
before publishing a directory; sanitizing this guide does not sanitize those files
or repository history.

## References

- [Agentic retrieval pipeline and project identity role requirements](https://learn.microsoft.com/en-us/azure/search/agentic-retrieval-how-to-create-pipeline)
- [Foundry MCP authentication methods](https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/mcp-authentication)
- [Azure AI Search role-based access control](https://learn.microsoft.com/en-us/azure/search/search-security-rbac)
