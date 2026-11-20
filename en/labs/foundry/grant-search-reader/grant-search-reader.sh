#!/usr/bin/env bash
set -euo pipefail

if ! command -v az >/dev/null 2>&1; then
  printf 'Error: Azure CLI (az) is required.\n' >&2
  exit 1
fi

if ! az account show --output none; then
  printf 'Error: Sign in first using az login --use-device-code.\n' >&2
  exit 1
fi

prompt_value() {
  local label="$1" default="$2" value
  read -r -p "$label [$default]: " value
  printf '%s' "${value:-$default}"
}

subscription_id="$(prompt_value 'Subscription ID' 'a3c8c0f4-f849-4b31-bbd3-737858cc843f')"
resource_group="$(prompt_value 'Search service resource group' 'rg-contoso-retail')"
search_service="$(prompt_value 'Azure AI Search service name' 'aip-contosoretail-bu5o6-srch-jzzs')"
principal_id="$(prompt_value 'Foundry project managed identity object (principal) ID' '4d050219-c84c-4d03-9be5-3fbc9c8000a1')"

uuid_pattern='^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$'
if [[ ! "$subscription_id" =~ $uuid_pattern || ! "$principal_id" =~ $uuid_pattern ]]; then
  printf 'Error: Subscription ID and principal ID must be UUIDs.\n' >&2
  exit 1
fi
if [[ "$resource_group" == *'/'* || "$resource_group" == *'\'* ]]; then
  printf 'Error: Resource group must be a name, not a resource path.\n' >&2
  exit 1
fi
if [[ ! "$search_service" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]]; then
  printf 'Error: Search service name must contain lowercase letters, digits, or hyphens.\n' >&2
  exit 1
fi

scope="/subscriptions/$subscription_id/resourceGroups/$resource_group/providers/Microsoft.Search/searchServices/$search_service"
printf '\nRole: Search Index Data Reader\nPrincipal ID: %s\nScope: %s\n\n' "$principal_id" "$scope"
read -r -p 'Grant read access to this Search service? [y/N]: ' confirmation
if [[ "$confirmation" != 'y' && "$confirmation" != 'Y' ]]; then
  printf 'Cancelled. No permissions changed.\n'
  exit 0
fi

az role assignment create \
  --subscription "$subscription_id" \
  --assignee-object-id "$principal_id" \
  --assignee-principal-type ServicePrincipal \
  --role "Search Index Data Reader" \
  --scope "$scope" \
  --query '{principalId:principalId,roleDefinitionId:roleDefinitionId,scope:scope}' \
  --output json

printf '\nRole assignment applied. Allow a few minutes for propagation before testing the agent.\n'
