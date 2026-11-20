# Grant Search read access to the Foundry project

Use these steps to give a Foundry project's system-assigned managed identity
read access to its connected Azure AI Search service. This applies to connections
using `ProjectManagedIdentity` authentication, not every agent tool error.

The role grants read access across the selected Search service, not just to one
index or knowledge base. Other agents using the same project identity share
that access. Confirm that this scope is appropriate before proceeding.

## 1. Open Azure Cloud Shell

Open [Azure Cloud Shell](https://shell.azure.com/) and select **Bash**.
Cloud Shell signs you in automatically. Examples below use Bash, not PowerShell.
Your account needs access to inspect the target resources and role assignments.
Creating an assignment requires `Microsoft.Authorization/roleAssignments/write`
at the Search scope, for example through **Owner**, **User Access Administrator**,
or **Role Based Access Control Administrator**, subject to assignment conditions.

The Search service must accept Microsoft Entra ID authentication. Confirm that
the connection uses `ProjectManagedIdentity`, the expected Search endpoint, and
the appropriate token audience. See the [CLI repair guide](README.md) for
PowerShell-based connection and current project identity checks.

## 2. Prepare and check your own values

Replace every angle-bracket placeholder locally. Use the subscription and
resource group containing **Search**, which may differ from those containing
Foundry. Both must use a compatible tenant/identity configuration.

Find the Foundry project's current system-assigned managed identity
**Object (principal) ID** in its identity settings. Do not use the parent
Foundry account identity, an agent identity, or a client/application ID. Recheck
the principal ID if the project was recreated.

```bash
subscription_id="<search-subscription-id>"
resource_group="<search-resource-group>"
search_service="<search-service-name>"
principal_id="<foundry-project-managed-identity-principal-id>"
scope="/subscriptions/${subscription_id}/resourceGroups/${resource_group}/providers/Microsoft.Search/searchServices/${search_service}"

az account show --subscription "$subscription_id" \
  --query '{subscription:name,subscriptionId:id,tenantId:tenantId}' --output json

az search service show \
  --subscription "$subscription_id" \
  --resource-group "$resource_group" \
  --name "$search_service" \
  --query '{name:name,id:id}' --output json

az role assignment list \
  --subscription "$subscription_id" \
  --scope "$scope" \
  --include-inherited \
  --query "[?principalId=='$principal_id'].{Role:roleDefinitionName,Scope:scope}" \
  --output table
```

Run commands separately and stop on failure. Confirm the subscription, tenant,
service, and identity locally. If `Search Index Data Reader` or another role
already grants the required access, skip creating an assignment and investigate
any remaining retrieval failure. An empty list alone is not sufficient evidence
unless your account can read role assignments.

## 3. Review, upload, and run the script

Review [grant-search-reader.sh](grant-search-reader.sh) before uploading it with
Cloud Shell's **Upload/Download files** button. The script has example and
environment-specific defaults; they are **not** a configuration for your project.
Do not accept them automatically.

```bash
bash grant-search-reader.sh
```

## 4. Enter all four parameters explicitly

The script prompts interactively; it does not automatically reuse the shell
variables from step 2. Enter the same verified values at each prompt.

| Prompt | Value to enter |
| --- | --- |
| Subscription ID | Your Search subscription ID |
| Search service resource group | Your Search resource group name |
| Azure AI Search service name | Your connected Search service name |
| Foundry project managed identity object (principal) ID | Your current project identity's principal ID |

Subscription and principal IDs must be valid UUIDs. Resource groups must be
names, not resource paths. The script validates input format, but that does not
prove the principal belongs to the intended project or the service is the
connection's actual target.

## 5. Confirm the assignment

Review the displayed principal ID and service scope against step 2. Enter `y`
only if both are correct and the read permission is missing. Press **Enter** to
cancel without creating an assignment.

**Search Index Data Reader** permits reading index data, not modifying documents.
Do not grant Contributor, enable API keys, widen network access, or disable TLS
validation to work around a retrieval error.

## 6. Verify the assignment

In the same Bash session, use the verified variables from step 2:

```bash
az role assignment list \
  --subscription "$subscription_id" \
  --scope "$scope" \
  --include-inherited \
  --query "[?principalId=='$principal_id' && roleDefinitionName=='Search Index Data Reader'].{Role:roleDefinitionName,Scope:scope}" \
  --output table
```

If you changed any values at the script prompts, update the corresponding shell
variables and rebuild `scope` before verifying. A visible role assignment does
not prove that data-plane authorization has propagated yet.

## 7. Test the agent

Allow several minutes for RBAC propagation. Open your project in
[Microsoft Foundry](https://ai.azure.com/), select your agent and intended version,
and start a new playground conversation.

Use a non-sensitive question with a known answer and source in your knowledge
base. For example, where your documents support it:

> Use the knowledge base to identify the document title and its subject in one sentence. Cite the source. Do not use web search.

Inspect the tool trace to confirm the expected knowledge-base retrieval tool ran
without error. Check the answer against the known source and verify its structured
citation where supported. HTTP success or a plausible answer alone is insufficient.
Live requests may incur model and Search usage charges.

If retrieval still fails after propagation, recheck the connection authentication,
current project identity, target service, and effective permissions. Investigate
network restrictions, Search authentication settings, indexing, and knowledge-base
configuration rather than broadening permissions without evidence.

## Public sharing

Keep populated commands, role-assignment output, tool traces, and test results
private until sanitized. Redact tenant/subscription/principal IDs, resource names,
endpoints, request IDs, source URLs, document content, and personal information.
Never publish tokens, API keys, or connection secrets. Resource IDs are not
credentials, but can reveal infrastructure details.

This guide uses placeholders and does not assert that access is already granted
in any environment. Review the companion script and other files separately before
publishing a directory; sanitizing this document does not sanitize them or
repository history.

## References

- [Azure AI Search role-based access control](https://learn.microsoft.com/en-us/azure/search/search-security-rbac)
- [Foundry MCP authentication](https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/mcp-authentication)
