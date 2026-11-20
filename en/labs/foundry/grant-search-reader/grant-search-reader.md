# Grant Search read access to the Foundry project

Use these steps to give the Foundry project's managed identity read access to Azure AI Search.

## 1. Open Azure Cloud Shell

Open [Azure Cloud Shell](https://shell.azure.com/) and select **Bash**.
Cloud Shell signs you in automatically. Your account needs permission to create role assignments, such as **Owner** or **Role Based Access Control Administrator** at the target scope.

## 2. Upload the script

Use Cloud Shell's **Upload/Download files** button to upload `grant-search-reader.sh` from this folder.

## 3. Run the script

```bash
bash grant-search-reader.sh
```

## 4. Enter the parameters

Press **Enter** to accept each default, or enter a different value.

| Parameter | Default |
| --- | --- |
| Subscription ID | `xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx` |
| Search service resource group | `rg-contoso-retail` |
| Azure AI Search service name | `aip-contosoretail-xxxxx-xxxxxx-xxxxx` |
| Foundry project managed identity principal ID | `xxxxx-xxxxx-xxxxx-xxxxx-xxxxxx` |

For another project, find its managed identity's **Object (principal) ID** in the project's identity settings. Do not use the agent's identity or a client/application ID.

## 5. Confirm the assignment

Review the displayed principal ID and scope. Enter `y` to grant **Search Index Data Reader**, or press **Enter** to cancel.

The role permits reading indexes across the selected Search service; it does not permit modifying documents.

## 6. Verify the assignment

For the default values, run:

```bash
az role assignment list \
  --subscription "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx" \
  --assignee "4d050219-c84c-4d03-9be5-3fbc9c8000a1" \
  --scope "/subscriptions/xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx/resourceGroups/rg-contoso-retail/providers/Microsoft.Search/searchServices/aip-contosoretail-xxxxx-xxxxxx-xxxxx" \
  --query "[?roleDefinitionName=='Search Index Data Reader'].{Role:roleDefinitionName,Principal:principalId,Scope:scope}" \
  --output table
```

If you entered different parameters, replace the corresponding values in this command.

## 7. Test the agent

Allow a few minutes for permissions to propagate. Open `Anders` in the Foundry playground and start a new conversation.

For `knowledgebaseXXX`, try:

> Use the knowledge base to identify the document title and its subject in one sentence. Cite the source. Do not use web search.

The previous successful test identified the **2024 Procaliber Alloy Service Manual** and included a source citation.

**Note:** This role assignment is already applied for the default project and Search service.
