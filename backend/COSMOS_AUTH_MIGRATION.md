# Cosmos DB Authentication Migration

## Overview

All three backend microservices (pet-service, activity-service, accessory-service) now support **dual authentication** for Azure Cosmos DB:

- **Local Development**: Key-based authentication (for Cosmos DB Emulator)
- **Azure Deployment**: Entra ID (Managed Identity) authentication

This follows Azure security best practices by eliminating the need to store Cosmos DB keys in production environments.

## Authentication Strategy

### Detection Logic

The services automatically detect the environment based on the `COSMOS_ENDPOINT`:

```python
is_local = "localhost" in cosmos_endpoint or "127.0.0.1" in cosmos_endpoint
```

- **Local**: `http://localhost:8081/` or `http://127.0.0.1:8081/`
- **Azure**: Any other endpoint (e.g., `https://petpal-cosmos.documents.azure.com:443/`)

### Local Development (Key-Based Auth)

When running locally with Cosmos DB Emulator:

```python
from azure.cosmos import CosmosClient

client = CosmosClient(
    url=cosmos_endpoint,
    credential=cosmos_key,  # Use emulator key
    connection_verify=False  # Optional: disable SSL verification for emulator
)
```

**Required Environment Variables:**
```bash
COSMOS_ENDPOINT=http://localhost:8081/
COSMOS_KEY=C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==
COSMOS_EMULATOR_DISABLE_SSL_VERIFY=true  # For HTTP emulator
```

### Azure Deployment (Entra ID Auth)

When deployed to Azure Container Apps:

```python
from azure.cosmos import CosmosClient
from azure.identity import DefaultAzureCredential

credential = DefaultAzureCredential()
client = CosmosClient(
    url=cosmos_endpoint,
    credential=credential  # Managed Identity authentication
)
```

**Required Environment Variables:**
```bash
COSMOS_ENDPOINT=https://petpal-cosmos.documents.azure.com:443/
# No COSMOS_KEY needed - authentication via Managed Identity
```

## Changes Made

### 1. Code Changes

#### All Services (`database.py`)

**Added Import:**
```python
from azure.identity import DefaultAzureCredential
```

**Updated `_build_cosmos_client_options()` method:**
```python
def _build_cosmos_client_options(self) -> Dict[str, Any]:
    is_local = "localhost" in self.cosmos_endpoint.lower() or "127.0.0.1" in self.cosmos_endpoint
    
    options: Dict[str, Any] = {
        "url": self.cosmos_endpoint,
        "connection_timeout": 30,
        "request_timeout": 30,
    }
    
    if is_local:
        # Local: Key-based auth
        logger.info("Using key-based authentication (local development)")
        options["credential"] = self.cosmos_key
        
        disable_ssl_verify = os.getenv("COSMOS_EMULATOR_DISABLE_SSL_VERIFY", "0").lower() in ("1", "true", "yes")
        if disable_ssl_verify:
            options["connection_verify"] = False
    else:
        # Azure: Entra ID auth
        logger.info("Using Entra ID authentication (Azure deployment with Managed Identity)")
        credential = DefaultAzureCredential()
        options["credential"] = credential
    
    return options
```

#### Pet Service (`config.py`)

**Added environment detection:**
```python
class Settings:
    def __init__(self):
        # ... existing config ...
        
        # Determine if running locally or in Azure
        self.is_local: bool = self._is_local_development()
        
        # Key is only required for local development
        if self.is_local and not self.cosmos_key:
            raise ValueError("COSMOS_KEY environment variable is required for local development")
    
    def _is_local_development(self) -> bool:
        endpoint = self.cosmos_endpoint.lower()
        return "localhost" in endpoint or "127.0.0.1" in endpoint
```

### 2. Dependency Updates

**Added to `requirements.txt` for all services:**
```
azure-identity==1.15.0
```

- ✅ pet-service: Added
- ✅ activity-service: Already present
- ✅ accessory-service: Already present

### 3. Infrastructure Changes Required

#### Azure Container Apps - Managed Identity

Each Container App needs a **User-Assigned Managed Identity** with Cosmos DB access:

**Already configured in Bicep** (`container-app.*.bicep`):
```bicep
resource petServiceIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${name}-identity'
  location: location
}

resource petServiceApp 'Microsoft.App/containerApps@2024-03-01' = {
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${petServiceIdentity.id}': {}
    }
  }
}
```

#### Cosmos DB - RBAC Role Assignment

**Required:** Grant the Managed Identity access to Cosmos DB using RBAC:

```bash
# Get Cosmos DB account resource ID
COSMOS_ACCOUNT_ID=$(az cosmosdb show \
  --name <cosmos-account-name> \
  --resource-group <resource-group> \
  --query id -o tsv)

# Get Managed Identity principal ID
IDENTITY_PRINCIPAL_ID=$(az identity show \
  --name <pet-service-identity> \
  --resource-group <resource-group> \
  --query principalId -o tsv)

# Assign Cosmos DB Built-in Data Contributor role
az cosmosdb sql role assignment create \
  --account-name <cosmos-account-name> \
  --resource-group <resource-group> \
  --role-definition-id 00000000-0000-0000-0000-000000000002 \
  --principal-id $IDENTITY_PRINCIPAL_ID \
  --scope $COSMOS_ACCOUNT_ID
```

**Role Definition IDs:**
- `00000000-0000-0000-0000-000000000001` - Cosmos DB Built-in Data Reader
- `00000000-0000-0000-0000-000000000002` - Cosmos DB Built-in Data Contributor

**Repeat for all three services:**
- pet-service-identity
- activity-service-identity
- accessory-service-identity

### 4. Deployment Configuration

#### Environment Variables (Azure Container Apps)

**Remove** `COSMOS_KEY` secret from Container Apps:
```bash
# Delete the secret
az containerapp secret remove \
  --name <app-name> \
  --resource-group <resource-group> \
  --secret-names cosmos-key

# Update environment variables to remove COSMOS_KEY reference
az containerapp update \
  --name <app-name> \
  --resource-group <resource-group> \
  --remove-env-vars COSMOS_KEY
```

**Keep only:**
```bash
az containerapp update \
  --name <app-name> \
  --resource-group <resource-group> \
  --set-env-vars \
    COSMOS_ENDPOINT=<cosmos-endpoint> \
    COSMOS_DATABASE_NAME=<database-name> \
    COSMOS_CONTAINER_NAME=<container-name>
```

## Testing

### Local Development Test

```bash
cd backend/pet-service

# Ensure environment variables are set
export COSMOS_ENDPOINT=http://localhost:8081/
export COSMOS_KEY=C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==
export COSMOS_EMULATOR_DISABLE_SSL_VERIFY=true

# Start the service
python main.py

# Test health endpoint
curl http://localhost:8010/health
```

**Expected log output:**
```
Using key-based authentication (local development)
```

### Azure Deployment Test

```bash
# Get Container App URL
FQDN=$(az containerapp show \
  --name pet-service \
  --resource-group <resource-group> \
  --query properties.configuration.ingress.fqdn -o tsv)

# Test health endpoint
curl https://$FQDN/health
```

**Expected log output (check Container App logs):**
```
Using Entra ID authentication (Azure deployment with Managed Identity)
```

## Benefits

### Security
- ✅ **No secrets in code or configuration** (Azure)
- ✅ **Automatic credential rotation** via Managed Identity
- ✅ **Principle of least privilege** with RBAC roles
- ✅ **Audit trail** of access via Azure Monitor

### Operations
- ✅ **Simplified deployment** - no key management
- ✅ **Consistent local development** - still uses emulator key
- ✅ **Automatic environment detection** - no manual configuration
- ✅ **Backward compatible** - existing local setups work unchanged

### Compliance
- ✅ Follows Azure security best practices
- ✅ Meets compliance requirements for secret management
- ✅ Supports zero-trust security model

## Troubleshooting

### Issue: "Authentication failed" in Azure

**Cause:** Managed Identity doesn't have Cosmos DB RBAC role

**Solution:**
```bash
# Check role assignments
az cosmosdb sql role assignment list \
  --account-name <cosmos-account> \
  --resource-group <resource-group>

# Add missing role assignment (see Infrastructure Changes section)
```

### Issue: "DefaultAzureCredential failed to retrieve a token"

**Cause:** Managed Identity not assigned to Container App

**Solution:**
```bash
# Verify identity is assigned
az containerapp show \
  --name <app-name> \
  --resource-group <resource-group> \
  --query identity

# Assign if missing (already in Bicep)
```

### Issue: Works locally but fails in Azure

**Check:**
1. Verify `COSMOS_ENDPOINT` is set correctly (should be Azure endpoint, not localhost)
2. Check Container App logs for authentication errors
3. Verify Managed Identity has Cosmos DB RBAC role
4. Ensure `COSMOS_KEY` environment variable is **NOT** set in Azure (should use Managed Identity)

### Issue: "COSMOS_KEY environment variable is required"

**Cause:** Running locally without `COSMOS_KEY` set

**Solution:**
```bash
# For local development with emulator
export COSMOS_KEY=C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==
```

## Migration Checklist

- [x] Update code in all three services (pet, activity, accessory)
- [x] Add `azure-identity` dependency
- [ ] Deploy updated code to Azure Container Apps
- [ ] Assign Cosmos DB RBAC roles to Managed Identities
- [ ] Remove `COSMOS_KEY` secrets from Container Apps
- [ ] Test health endpoints in Azure
- [ ] Verify services can read/write data
- [ ] Update deployment workflows to remove secret management
- [ ] Update documentation

## Next Steps

1. **Deploy Code Changes**: Push updates to GitHub to trigger CI/CD
2. **Configure RBAC**: Run role assignment commands for each service
3. **Remove Secrets**: Clean up `COSMOS_KEY` from Container Apps
4. **Validate**: Run deployment health tests (`test-deployment-health.sh`)
5. **Monitor**: Check Container App logs for authentication confirmations

## References

- [Azure Cosmos DB RBAC](https://learn.microsoft.com/azure/cosmos-db/how-to-setup-rbac)
- [Managed Identities for Azure Resources](https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/overview)
- [DefaultAzureCredential](https://learn.microsoft.com/python/api/azure-identity/azure.identity.defaultazurecredential)
- [Azure Container Apps Managed Identity](https://learn.microsoft.com/azure/container-apps/managed-identity)
