# GitHub Actions Workflows - RBAC Migration

## Summary

All three backend service deployment workflows have been updated to use **Managed Identity with RBAC** for Cosmos DB authentication instead of master keys.

## Changes Applied

### Files Updated
- ✅ `.github/workflows/deploy-pet-service.yml`
- ✅ `.github/workflows/deploy-activity-service.yml`
- ✅ `.github/workflows/deploy-accessory-service.yml`

## What Changed

### 1. Removed Cosmos DB Key Retrieval

**Before:**
```yaml
- name: Get Cosmos DB credentials
  id: cosmos
  run: |
    COSMOS_ACCOUNT=$(az cosmosdb list --resource-group "$RESOURCE_GROUP" --query "[0].name" -o tsv)
    COSMOS_ENDPOINT=$(az cosmosdb show --resource-group "$RESOURCE_GROUP" --name "$COSMOS_ACCOUNT" --query documentEndpoint -o tsv)
    COSMOS_KEY=$(az cosmosdb keys list --resource-group "$RESOURCE_GROUP" --name "$COSMOS_ACCOUNT" --type keys --query primaryMasterKey -o tsv)

    echo "endpoint=$COSMOS_ENDPOINT" >> "$GITHUB_OUTPUT"
    echo "account=$COSMOS_ACCOUNT" >> "$GITHUB_OUTPUT"
    echo "::add-mask::$COSMOS_KEY"
    echo "key=$COSMOS_KEY" >> "$GITHUB_OUTPUT"
```

**After:**
```yaml
- name: Get Cosmos DB endpoint
  id: cosmos
  run: |
    COSMOS_ACCOUNT=$(az cosmosdb list --resource-group "$RESOURCE_GROUP" --query "[0].name" -o tsv)
    COSMOS_ENDPOINT=$(az cosmosdb show --resource-group "$RESOURCE_GROUP" --name "$COSMOS_ACCOUNT" --query documentEndpoint -o tsv)

    echo "endpoint=$COSMOS_ENDPOINT" >> "$GITHUB_OUTPUT"
    echo "account=$COSMOS_ACCOUNT" >> "$GITHUB_OUTPUT"
```

**Key Changes:**
- ❌ Removed `az cosmosdb keys list` command (no longer needed)
- ❌ Removed `COSMOS_KEY` output variable
- ❌ Removed `::add-mask::` secret masking (no secret to mask)
- ✅ Step renamed to "Get Cosmos DB endpoint" (more accurate)

### 2. Removed Secret Management from Deployment

**Before:**
```yaml
- name: Deploy to Container App
  run: |
    APP_NAME=$(az containerapp list --resource-group "$RESOURCE_GROUP" --query "[?contains(name, 'pet-service')].name" -o tsv)
    
    # Get the managed identity ID for the container app
    IDENTITY_ID=$(az containerapp show \
      --name "$APP_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --query "identity.userAssignedIdentities" -o json | jq -r 'keys[0]')
    
    echo "Using managed identity: $IDENTITY_ID"

    # Update or create the secret for Cosmos DB key
    az containerapp secret set \
      --name "$APP_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --secrets cosmos-key="${{ steps.cosmos.outputs.key }}"

    # Update the container app with new image and environment variables
    az containerapp update \
      --name "$APP_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --image "$ACR_LOGIN_SERVER/${{ env.SERVICE_NAME }}:${{ github.sha }}" \
      --replace-env-vars \
        COSMOS_ENDPOINT="${{ steps.cosmos.outputs.endpoint }}" \
        COSMOS_DATABASE_NAME="${{ env.COSMOS_DATABASE_NAME }}" \
        COSMOS_CONTAINER_NAME="${{ env.COSMOS_CONTAINER_NAME }}" \
        COSMOS_KEY="secretref:cosmos-key"
```

**After:**
```yaml
- name: Deploy to Container App
  run: |
    APP_NAME=$(az containerapp list --resource-group "$RESOURCE_GROUP" --query "[?contains(name, 'pet-service')].name" -o tsv)
    
    echo "Deploying to Container App: $APP_NAME"
    echo "Using Managed Identity for Cosmos DB authentication (RBAC)"

    # Update the container app with new image and environment variables
    # No secrets needed - using Managed Identity with Cosmos DB RBAC
    az containerapp update \
      --name "$APP_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --image "$ACR_LOGIN_SERVER/${{ env.SERVICE_NAME }}:${{ github.sha }}" \
      --set-env-vars \
        COSMOS_ENDPOINT="${{ steps.cosmos.outputs.endpoint }}" \
        COSMOS_DATABASE_NAME="${{ env.COSMOS_DATABASE_NAME }}" \
        COSMOS_CONTAINER_NAME="${{ env.COSMOS_CONTAINER_NAME }}"
```

**Key Changes:**
- ❌ Removed managed identity ID query (not needed for deployment)
- ❌ Removed `az containerapp secret set` command (no secrets to set)
- ❌ Removed `COSMOS_KEY="secretref:cosmos-key"` environment variable
- ✅ Changed `--replace-env-vars` to `--set-env-vars` (more appropriate)
- ✅ Added informative echo statements about RBAC usage

### 3. Added Health Check Validation

**New Addition:**
```yaml
- name: Wait for deployment
  run: sleep 30

- name: Health check
  run: |
    APP_URL=$(az containerapp show \
      --name $(az containerapp list --resource-group "$RESOURCE_GROUP" --query "[?contains(name, 'pet-service')].name" -o tsv) \
      --resource-group "$RESOURCE_GROUP" \
      --query properties.configuration.ingress.fqdn -o tsv)
    
    echo "Testing health endpoint: https://$APP_URL/health"
    
    # Retry health check up to 5 times
    for i in {1..5}; do
      HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$APP_URL/health" || echo "000")
      if [ "$HTTP_CODE" == "200" ]; then
        echo "✅ Health check passed (HTTP $HTTP_CODE)"
        curl -s "https://$APP_URL/health" | jq '.'
        exit 0
      else
        echo "⚠️ Attempt $i: Health check returned HTTP $HTTP_CODE, retrying..."
        sleep 10
      fi
    done
    
    echo "❌ Health check failed after 5 attempts"
    exit 1
```

**Benefits:**
- ✅ Validates deployment was successful
- ✅ Verifies Cosmos DB RBAC authentication is working
- ✅ Provides immediate feedback on deployment health
- ✅ Fails workflow if service is not healthy after deployment
- ✅ Includes retry logic for transient issues

## Security Improvements

### Before (Key-Based Authentication)
1. **Secrets Exposure Risk**: Master key stored in Container App secrets
2. **Broad Permissions**: Master key grants full account access
3. **Key Rotation Burden**: Manual key rotation required
4. **Audit Challenges**: Harder to track which identity accessed data
5. **Secret Management**: Additional operational overhead

### After (RBAC with Managed Identity)
1. **Zero Secrets**: No credentials stored in Container App configuration
2. **Least Privilege**: Cosmos DB Data Contributor role only
3. **Auto-Rotation**: Managed Identity tokens auto-rotate
4. **Full Audit Trail**: All access attributed to specific managed identity
5. **Simplified Operations**: No secret management needed

## Workflow Behavior

### Local Development
- Uses `COSMOS_KEY` from `.env` file (localhost detection)
- Key-based authentication for developer convenience
- No infrastructure changes needed

### Azure Deployment (GitHub Actions)
1. **Build Phase**: Docker image built and pushed to ACR
2. **Deploy Phase**: 
   - Container App updated with new image
   - Only endpoint, database, and container name set as env vars
   - **No secrets configured**
3. **Verification Phase**:
   - Wait 30 seconds for deployment stabilization
   - Health check with 5 retry attempts
   - Validates Cosmos DB connectivity via RBAC

### Authentication Flow in Azure
1. Container App starts with user-assigned managed identity
2. Application code detects non-localhost Cosmos DB endpoint
3. `DefaultAzureCredential()` used (from azure-identity SDK)
4. Managed Identity token obtained from IMDS endpoint
5. Token presented to Cosmos DB
6. Cosmos DB validates token and checks RBAC role assignment
7. Access granted via Cosmos DB Data Contributor role

## Validation

### Check Workflow Syntax
```bash
# GitHub CLI (requires gh CLI installed)
gh workflow list
gh workflow view "Deploy Pet Service"
```

### Manual Workflow Trigger
```bash
# Trigger workflow manually
gh workflow run "Deploy Pet Service"

# Monitor workflow status
gh run list --workflow="Deploy Pet Service"
gh run watch
```

### Verify Deployment
```bash
# After workflow completes, check Container App
az containerapp show \
  --name petpal-pet-service \
  --resource-group $RESOURCE_GROUP \
  --query "{Image:properties.template.containers[0].image,Env:properties.template.containers[0].env}" \
  -o json

# Should show:
# - Latest image from ACR
# - COSMOS_ENDPOINT, COSMOS_DATABASE_NAME, COSMOS_CONTAINER_NAME env vars
# - NO COSMOS_KEY env var
```

### Test Health Endpoint
```bash
# Should return 200 OK with healthy status
curl -i https://$(az containerapp show \
  --name petpal-pet-service \
  --resource-group $RESOURCE_GROUP \
  --query properties.configuration.ingress.fqdn -o tsv)/health
```

## Troubleshooting

### Issue: Health Check Fails with 503

**Cause**: RBAC role assignment not propagated yet

**Solution**: 
```bash
# Wait 5-10 minutes after infrastructure deployment
# Check role assignments
COSMOS_ID=$(az cosmosdb show -n $COSMOS_ACCOUNT -g $RESOURCE_GROUP --query id -o tsv)
az role assignment list --scope $COSMOS_ID --query "[?roleDefinitionName=='Cosmos DB Built-in Data Contributor']" -o table

# Re-run workflow after role propagation
```

### Issue: Health Check Fails with 401/403

**Cause**: Managed Identity not configured or RBAC role missing

**Solution**:
```bash
# Verify Container App has managed identity
az containerapp show -n petpal-pet-service -g $RESOURCE_GROUP \
  --query "identity.userAssignedIdentities" -o json

# Re-deploy infrastructure to ensure RBAC is configured
cd infra
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file main.bicep \
  --parameters main.parameters.json
```

### Issue: Workflow Fails at Build Step

**Cause**: Unrelated to RBAC changes - ACR authentication or Docker build issue

**Solution**:
```bash
# Verify GitHub federated identity has ACR access
az role assignment list \
  --assignee $GITHUB_IDENTITY_CLIENT_ID \
  --scope $(az acr show -n $ACR_NAME --query id -o tsv) \
  -o table

# Check GitHub secrets are configured
gh secret list
```

## Migration Checklist

For teams migrating existing workflows:

- [ ] Update infrastructure (Bicep files with RBAC role assignments)
- [ ] Deploy updated infrastructure (`azd provision` or `az deployment group create`)
- [ ] Wait 5-10 minutes for RBAC role propagation
- [ ] Update backend service code (database.py with DefaultAzureCredential)
- [ ] Update GitHub Actions workflows (remove secret management)
- [ ] Update requirements.txt (add azure-identity dependency)
- [ ] Test workflows manually (`gh workflow run`)
- [ ] Verify health checks pass
- [ ] Monitor Application Insights for any authentication errors
- [ ] Remove old cosmos-key secrets from Container Apps (optional cleanup)

## Cleanup (Optional)

Remove old secrets from Container Apps if they exist:

```bash
# Check existing secrets
az containerapp secret list -n petpal-pet-service -g $RESOURCE_GROUP -o table

# Remove cosmos-key secret if present
az containerapp secret remove \
  --name petpal-pet-service \
  --resource-group $RESOURCE_GROUP \
  --secret-names cosmos-key
```

## Related Documentation

- [Infrastructure RBAC Migration](/infra/RBAC_MIGRATION_COMPLETE.md)
- [Backend Authentication Migration](/backend/COSMOS_AUTH_MIGRATION.md)
- [Challenge 09 Updates](/challenges/challenge-09/README.md)
- [Solution 09 Updates](/solutions/challenge-09/README.md)

---

**Status**: ✅ **All Workflows Updated**  
**Date**: 2025-01-26  
**Impact**: High - Eliminates secret management, improves security posture  
**Breaking Changes**: Requires updated infrastructure with RBAC role assignments
