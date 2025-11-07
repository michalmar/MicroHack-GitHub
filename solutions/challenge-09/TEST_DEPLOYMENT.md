# Deployment Health Testing

This directory contains test utilities to validate successful deployment of PetPal microservices to Azure Container Apps.

## Test Files

### 1. `test-deployment-health.http`
HTTP file for interactive API testing using VS Code REST Client extension.

**Features:**
- Individual health endpoint tests for each service
- Root endpoint validation
- Functional API tests (list operations)
- Clear documentation and expected responses

**Usage:**
1. Install VS Code REST Client extension
2. Update the `@*ServiceUrl` variables with your deployed service FQDNs
3. Click "Send Request" above each test or use "Send All Requests"

**Getting Service URLs:**
```bash
# Get pet-service URL
az containerapp show \
  --name $(az containerapp list --resource-group <rg> --query "[?contains(name, 'pet-service')].name" -o tsv) \
  --resource-group <your-resource-group> \
  --query properties.configuration.ingress.fqdn -o tsv

# Repeat for activity-service and accessory-service
```

### 2. `test-deployment-health.ps1`
PowerShell automation script for comprehensive deployment validation.

**Features:**
- Automatic service discovery via Azure CLI
- Health check validation with response time measurement
- Database connectivity verification
- Color-coded output and detailed reporting
- Error diagnostics and troubleshooting tips

**Usage:**
```powershell
# Basic usage (requires RESOURCE_GROUP env var)
./test-deployment-health.ps1

# Specify resource group
./test-deployment-health.ps1 -ResourceGroup "rg-petpal-dev"

# Show detailed responses
./test-deployment-health.ps1 -ResourceGroup "rg-petpal-dev" -Detailed
```

**Prerequisites:**
- Azure CLI installed and authenticated (`az login`)
- PowerShell 7+ or Windows PowerShell 5.1+
- Network access to deployed Container Apps

**Exit Codes:**
- `0` - All services healthy
- `1` - One or more services unhealthy or errors occurred

### 3. `test-deployment-health.sh`
Bash/shell script for Linux/macOS environments with comprehensive deployment validation.

**Features:**
- Automatic service discovery via Azure CLI
- Health check validation with response time measurement
- Database connectivity verification
- Color-coded terminal output and detailed reporting
- Error diagnostics and troubleshooting tips
- POSIX-compliant with modern bash features

**Usage:**
```bash
# Basic usage (requires RESOURCE_GROUP env var)
export RESOURCE_GROUP="rg-petpal-dev"
./test-deployment-health.sh

# Specify resource group as argument
./test-deployment-health.sh -r "rg-petpal-dev"

# Show detailed responses
./test-deployment-health.sh -r "rg-petpal-dev" -d

# Show help
./test-deployment-health.sh -h
```

**Prerequisites:**
- Azure CLI installed and authenticated (`az login`)
- `jq` for JSON parsing
- `curl` for HTTP requests
- Bash 4.0+ (for associative arrays)
- Network access to deployed Container Apps

**Exit Codes:**
- `0` - All services healthy
- `1` - One or more services unhealthy or errors occurred

## What Gets Tested

Both test utilities validate:

### Health Checks
- ✅ Service reachability (HTTPS endpoint accessible)
- ✅ Health status (`status: "healthy"`)
- ✅ Database connectivity (`database.status: "connected"`)
- ✅ Service version information
- ✅ Response time (PowerShell script only)

### Port Configuration Validation
Each service runs on its designated port:
- **Pet Service**: Port 8010
- **Activity Service**: Port 8020
- **Accessory Service**: Port 8030

The tests confirm that Azure Container Apps ingress configuration correctly routes to these ports.

### Database Integration
Tests verify Cosmos DB connectivity for each service:
- Pet Service → `petservice` database, `pets` container
- Activity Service → `activityservice` database, `activities` container
- Accessory Service → `accessoryservice` database, `accessories` container

## Integration with CI/CD

### GitHub Actions Integration

**PowerShell Script (cross-platform):**
```yaml
- name: Validate Deployment Health
  shell: pwsh
  run: |
    ./solutions/challenge-09/test-deployment-health.ps1 `
      -ResourceGroup ${{ vars.RESOURCE_GROUP }}
```

**Bash Script (Linux/macOS runners):**
```yaml
- name: Validate Deployment Health
  shell: bash
  run: |
    chmod +x ./solutions/challenge-09/test-deployment-health.sh
    ./solutions/challenge-09/test-deployment-health.sh -r ${{ vars.RESOURCE_GROUP }}
```

**HTTP file with `httpYac` CLI:**
```yaml
- name: Install httpYac CLI
  run: npm install -g httpyac

- name: Run API Health Tests
  run: |
    # Update URLs in HTTP file
    httpyac send solutions/challenge-09/test-deployment-health.http \
      --all \
      --var petServiceUrl=https://$(az containerapp show --name pet-service --resource-group ${{ vars.RESOURCE_GROUP }} --query properties.configuration.ingress.fqdn -o tsv)
```

### Azure DevOps Integration

**PowerShell:**
```yaml
- task: PowerShell@2
  displayName: 'Health Check Tests'
  inputs:
    targetType: 'filePath'
    filePath: 'solutions/challenge-09/test-deployment-health.ps1'
    arguments: '-ResourceGroup $(RESOURCE_GROUP)'
    pwsh: true
```

**Bash:**
```yaml
- task: Bash@3
  displayName: 'Health Check Tests'
  inputs:
    targetType: 'filePath'
    filePath: 'solutions/challenge-09/test-deployment-health.sh'
    arguments: '-r $(RESOURCE_GROUP)'
```

## Expected Output

### Successful Deployment
```
╔════════════════════════════════════════════════════════════╗
║   PetPal Microservices Deployment Health Check           ║
╚════════════════════════════════════════════════════════════╝

✅ Azure CLI authenticated

───────────────────────────────────────────────────────────
Testing: Pet Management Service
───────────────────────────────────────────────────────────

✅ Service is healthy (245ms)
    • Version: 1.0.0
    • Database: Connected to petservice

[... similar output for other services ...]

╔════════════════════════════════════════════════════════════╗
║                    TEST SUMMARY                           ║
╚════════════════════════════════════════════════════════════╝

  ✅ pet-service          HEALTHY (245ms)
  ✅ activity-service     HEALTHY (198ms)
  ✅ accessory-service    HEALTHY (221ms)

═══════════════════════════════════════════════════════════
✅ All services are healthy and operational!
═══════════════════════════════════════════════════════════
```

### Failed Deployment
```
❌ Service status is not healthy: unhealthy
❌ One or more services failed health checks

ℹ️  Troubleshooting tips:
  1. Check Container App logs: az containerapp logs show --name <app-name> ...
  2. Verify environment variables are set correctly
  3. Ensure Cosmos DB credentials are valid
  4. Check ingress configuration matches service port
```

## Troubleshooting

### Service Not Found
**Issue:** Container App not found in resource group
**Solution:** Verify deployment completed successfully and resource group name is correct

### Connection Timeout
**Issue:** Health endpoint not responding
**Solution:** 
1. Check Container App is running: `az containerapp show --name <app> --resource-group <rg>`
2. Verify ingress is enabled and external
3. Check firewall/network rules

### Database Not Connected
**Issue:** Service healthy but database shows disconnected
**Solution:**
1. Verify Cosmos DB credentials are set correctly
2. Check Container App secrets: `az containerapp secret list --name <app> --resource-group <rg>`
3. Ensure environment variables reference correct secret

### Port Mismatch
**Issue:** Service returns 404 or connection refused
**Solution:** Verify `targetPort` in Bicep matches `EXPOSE` in Dockerfile and uvicorn port in `main.py`

## Additional Resources

- [Challenge 09 README](../../challenges/challenge-09/README.md)
- [Azure Container Apps Health Probes](https://learn.microsoft.com/azure/container-apps/health-probes)
- [VS Code REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client)
