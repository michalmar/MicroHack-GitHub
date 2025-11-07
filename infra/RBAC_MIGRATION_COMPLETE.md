# Cosmos DB RBAC Migration - Infrastructure Update Complete

## Summary

All Bicep infrastructure files have been successfully updated to implement Managed Identity-based authentication to Azure Cosmos DB using RBAC (Role-Based Access Control) instead of master keys.

## Changes Made

### 1. Cosmos DB Module (`cosmos.bicep`)
**Added:**
- Output `dataContributorRoleId` containing the built-in Cosmos DB Data Contributor role ID (`00000000-0000-0000-0000-000000000002`)
- This role grants read/write access to Cosmos DB data

**Note:**
- `primaryKey` output remains temporarily for backward compatibility during migration

### 2. Pet Service (`container-app.pet-service.bicep`)
**Removed:**
- `@secure() cosmosKey` parameter
- `secrets` section containing cosmos-key
- `COSMOS_KEY` environment variable with secretRef

**Added:**
- `cosmosAccountId` parameter (string) - Full resource ID of Cosmos DB account
- `cosmosDataContributorRoleId` parameter (string) - Role definition ID
- `cosmosRoleAssignment` resource - Grants Cosmos DB Data Contributor role to managed identity
- `cosmosAccount` existing resource reference - For parent scope in role assignment
- Identity outputs: `identityPrincipalId` and `identityClientId`

### 3. Activity Service (`container-app.activity-service.bicep`)
**Changes:** Identical pattern to pet-service
- Removed cosmosKey parameter and secrets
- Added cosmosAccountId and cosmosDataContributorRoleId parameters
- Added RBAC role assignment resource
- Updated outputs with identity information

### 4. Accessory Service (`container-app.accessory-service.bicep`)
**Changes:** Identical pattern to pet-service
- Removed cosmosKey parameter and secrets
- Added cosmosAccountId and cosmosDataContributorRoleId parameters
- Added RBAC role assignment resource
- Updated outputs with identity information

### 5. Main Orchestration (`main.bicep`)
**Updated Module Calls:**
All three backend service modules now receive:
```bicep
cosmosEndpoint: cosmosDb.outputs.endpoint
cosmosAccountId: cosmosDb.outputs.accountId
cosmosDataContributorRoleId: cosmosDb.outputs.dataContributorRoleId
```

**Removed:**
- `cosmosKey: cosmosDb.outputs.primaryKey` parameter passing

## Role Assignment Details

Each container app now has an RBAC role assignment:

```bicep
resource cosmosRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2025-04-15' = {
  name: guid(cosmosAccountId, <service>Identity.id, 'cosmos-data-contributor')
  parent: cosmosAccount
  properties: {
    roleDefinitionId: '${cosmosAccountId}/sqlRoleDefinitions/${cosmosDataContributorRoleId}'
    principalId: <service>Identity.properties.principalId
    scope: cosmosAccountId
  }
}
```

**Key Points:**
- Uses built-in Cosmos DB Data Contributor role (no custom role needed)
- Scoped to entire Cosmos DB account
- Deterministic naming using `guid()` function prevents conflicts
- Grants read/write access to all databases and containers

## Authentication Flow

### Local Development (localhost)
1. Application detects `localhost` or `127.0.0.1` in COSMOS_ENDPOINT
2. Uses COSMOS_KEY from environment variable (`.env` file)
3. Key-based authentication via `credential: cosmos_key`

### Azure Deployment (Container Apps)
1. Application detects non-localhost endpoint
2. Uses `DefaultAzureCredential()` from azure-identity SDK
3. Managed Identity automatically authenticated via IMDS endpoint
4. RBAC role checked: Cosmos DB Data Contributor on account
5. Token-based authentication established

## Security Improvements

✅ **Eliminated Secrets**: No more COSMOS_KEY in Container App secrets  
✅ **Zero Secret Rotation**: Managed Identity tokens auto-rotate  
✅ **Least Privilege**: Data Contributor role (not account keys)  
✅ **Audit Trail**: All access logged via Azure Activity Log  
✅ **No Secret Leakage**: Cannot accidentally expose in logs/code

## Validation Status

✅ Bicep compilation successful (`az bicep build --file main.bicep`)  
✅ All module parameters validated  
✅ Role assignment syntax verified  
⚠️ Warnings (non-blocking):
- `outputs-should-not-contain-secrets` on cosmos.bicep (acceptable during migration)
- `BCP318` on githubManagedIdentity conditionals (pre-existing, unrelated)

## Deployment Checklist

Before deploying these updated Bicep files:

- [ ] Ensure backend services have updated code with dual authentication support
- [ ] Verify `azure-identity==1.15.0` in all service `requirements.txt`
- [ ] Confirm database.py implements `DefaultAzureCredential` logic
- [ ] Test locally with COSMOS_KEY to ensure local development still works
- [ ] Deploy infrastructure: `az deployment group create --template-file main.bicep`
- [ ] Wait for role assignments to propagate (~5 minutes)
- [ ] Deploy application code to Container Apps
- [ ] Test /health endpoints for all services
- [ ] Verify Cosmos DB operations work without COSMOS_KEY
- [ ] Monitor Azure Activity Log for RBAC events

## Testing

Use the deployment health testing tools in `solutions/challenge-09/`:
- `test-deployment-health.http` - VS Code REST Client
- `test-deployment-health.ps1` - PowerShell script
- `test-deployment-health.sh` - Bash script

All tools test the /health endpoint which validates Cosmos DB connectivity.

## Rollback Plan

If issues occur:
1. Revert to previous Bicep files (git checkout)
2. Redeploy with cosmosKey parameter
3. Backend code still supports key-based auth via localhost detection
4. No data loss - only authentication method changes

## Documentation

Related documentation:
- `/backend/COSMOS_AUTH_MIGRATION.md` - Backend code changes and rationale
- `/solutions/challenge-09/TEST_DEPLOYMENT.md` - Testing procedures
- Azure docs: https://learn.microsoft.com/azure/cosmos-db/how-to-setup-rbac

## Next Steps

1. **Deploy Updated Infrastructure**:
   ```bash
   cd /workspaces/MicroHack-GitHub/infra
   az deployment group create \
     --resource-group <your-rg> \
     --template-file main.bicep \
     --parameters main.parameters.json
   ```

2. **Wait for Role Propagation** (5-10 minutes)

3. **Deploy Application Code** (rebuild containers with updated dependencies)

4. **Validate Services**:
   ```bash
   ./solutions/challenge-09/test-deployment-health.sh
   ```

5. **Monitor First 24 Hours**:
   - Check Azure Monitor logs for authentication errors
   - Verify Cosmos DB request metrics
   - Monitor Container App logs for RBAC issues

## Files Modified

Infrastructure (Bicep):
- ✅ `infra/cosmos.bicep`
- ✅ `infra/container-app.pet-service.bicep`
- ✅ `infra/container-app.activity-service.bicep`
- ✅ `infra/container-app.accessory-service.bicep`
- ✅ `infra/main.bicep`

Backend Services (previously completed):
- ✅ `backend/pet-service/database.py`
- ✅ `backend/pet-service/config.py`
- ✅ `backend/pet-service/requirements.txt`
- ✅ `backend/activity-service/database.py`
- ✅ `backend/accessory-service/database.py`

## Compliance & Best Practices

✅ **Azure Well-Architected Framework**: Security pillar - identity-based authentication  
✅ **Zero Trust**: No standing credentials in application configuration  
✅ **Defense in Depth**: RBAC + Network isolation (if VNET used)  
✅ **Operational Excellence**: Infrastructure as Code, reproducible deployments

---

**Migration Status**: ✅ **COMPLETE** (Infrastructure Ready for Deployment)  
**Date**: 2025-01-26  
**Version**: 1.0
