# Solution: Challenge 08 - Infrastructure as Code and Access Models

This solution provides a complete Infrastructure as Code (IaC) implementation using Azure Bicep for deploying the PetPal microservices application to Azure Container Apps.

## Overview

The solution implements a production-ready infrastructure that includes:

- **Azure Container Apps Environment** with centralized logging
- **Azure Cosmos DB** (serverless) for data persistence
- **Four Container Apps**: Pet Service, Activity Service, Accessory Service, and Frontend
- **Security best practices**: Secrets management, HTTPS-only, managed identities ready
- **Auto-scaling configuration** for all services
- **Modular Bicep templates** for maintainability and reusability

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              Azure Container Apps Environment                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Pet Service  │  │Activity Svc  │  │Accessory Svc │      │
│  │   (8010)     │  │   (8020)     │  │   (8030)     │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                 │                  │               │
│         └─────────────────┴──────────────────┘               │
│                           │                                  │
│                    ┌──────▼───────┐                          │
│                    │   Cosmos DB  │                          │
│                    │  (Serverless)│                          │
│                    └──────────────┘                          │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │           Frontend (React UI)                        │   │
│  │              Port 80                                 │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                           │
                    ┌──────▼───────┐
                    │Log Analytics │
                    │  Workspace   │
                    └──────────────┘
```

## Solution Structure

All infrastructure code is located in the `/infra` directory:

```
infra/
├── main.bicep                           # Main orchestration template
├── main.parameters.json                 # Default parameters
├── cosmos.bicep                         # Cosmos DB module
├── container-app-environment.bicep      # Container Apps environment
├── container-app.pet-service.bicep      # Pet service
├── container-app.activity-service.bicep # Activity service
├── container-app.accessory-service.bicep# Accessory service
├── container-app.frontend.bicep         # Frontend UI
└── README.md                            # Deployment guide
```

## Step-by-Step Implementation

### Task 1: Infrastructure Design ✅

**Design Decisions:**

1. **Service Choice**: Azure Container Apps selected for:
   - Native container support with minimal configuration
   - Built-in auto-scaling and load balancing
   - Integrated ingress with automatic HTTPS
   - Cost-effective serverless compute model
   - Easy integration with Cosmos DB

2. **Database Choice**: Cosmos DB Serverless for:
   - Pay-per-request pricing model (ideal for development)
   - Global distribution capabilities
   - NoSQL flexibility
   - Automatic scaling
   - Multi-API support (SQL API used)

3. **Modular Architecture**:
   - Separate Bicep modules for each component
   - Reusable templates for services
   - Clear separation of concerns
   - Easy to maintain and extend

### Task 2: Identity and Access Management ✅

**Security Implementation:**

1. **Secrets Management**:
   - Cosmos DB keys stored as Container App secrets
   - Secrets referenced via `secretRef` in environment variables
   - Never exposed in logs or outputs (marked with `@secure()`)

2. **Network Security**:
   - HTTPS-only ingress configuration
   - Public network access (can be restricted to VNet)
   - Each service exposed on unique ports

3. **Ready for Managed Identity** (future enhancement):
   - Infrastructure prepared for system-assigned identities
   - Can migrate from key-based to identity-based auth
   - RBAC roles can be assigned post-deployment

### Task 3: Core Infrastructure Implementation ✅

**Components Implemented:**

1. **Cosmos DB Account** (`cosmos.bicep`):
   ```bicep
   - Serverless capability enabled
   - Session consistency level (balanced performance)
   - Single region deployment
   - Automatic failover disabled (cost optimization)
   ```

2. **Container Apps Environment** (`container-app-environment.bicep`):
   ```bicep
   - Log Analytics workspace integration
   - 30-day log retention
   - Centralized logging for all apps
   ```

3. **Backend Services** (pet, activity, accessory):
   ```bicep
   - 0.5 CPU, 1GB memory per replica
   - Auto-scale: 1-10 replicas
   - HTTP scaling based on 10 concurrent requests
   - Environment variables for Cosmos DB connection
   - Secrets for Cosmos DB keys
   ```

4. **Frontend** (`container-app.frontend.bicep`):
   ```bicep
   - 0.5 CPU, 1GB memory per replica
   - Auto-scale: 1-5 replicas
   - HTTP scaling based on 50 concurrent requests
   - Environment variables for backend service URLs
   ```

### Task 4: Environment Variables Configuration ✅

**Backend Services Environment:**
- `COSMOS_ENDPOINT`: Cosmos DB endpoint URL
- `COSMOS_KEY`: Primary key (stored as secret)
- `COSMOS_DATABASE_NAME`: Service-specific database name
- `COSMOS_CONTAINER_NAME`: Service-specific container name

**Frontend Environment:**
- `VITE_API_PETS_URL`: Pet service FQDN (HTTPS)
- `VITE_API_ACTIVITIES_URL`: Activity service FQDN (HTTPS)
- `VITE_API_ACCESSORIES_URL`: Accessory service FQDN (HTTPS)

### Task 5: Deployment Instructions

**Prerequisites:**
```bash
# Install Azure CLI
az version

# Login to Azure
az login

# Set subscription
az account set --subscription <subscription-id>

# Create resource group
az group create --name petpal-rg --location eastus
```

**Deploy Infrastructure:**
```bash
# Navigate to infra directory
cd /workspaces/MicroHack-GitHub/infra

# Validate deployment (optional)
az deployment group validate \
  --resource-group petpal-rg \
  --template-file main.bicep \
  --parameters main.parameters.json

# Deploy infrastructure
az deployment group create \
  --resource-group petpal-rg \
  --template-file main.bicep \
  --parameters main.parameters.json \
  --name petpal-infrastructure

# Monitor deployment
az deployment group show \
  --resource-group petpal-rg \
  --name petpal-infrastructure \
  --query properties.provisioningState
```

**Retrieve Outputs:**
```bash
# Get all outputs
az deployment group show \
  --resource-group petpal-rg \
  --name petpal-infrastructure \
  --query properties.outputs

# Get frontend URL
az deployment group show \
  --resource-group petpal-rg \
  --name petpal-infrastructure \
  --query properties.outputs.frontendUrl.value -o tsv
```

## Key Learning Points

### 1. Infrastructure as Code Benefits
- **Repeatability**: Deploy same infrastructure consistently across environments
- **Version Control**: Track infrastructure changes in Git
- **Documentation**: Code serves as living documentation
- **Automation**: Integrate with CI/CD pipelines
- **Testing**: Validate before deployment

### 2. Azure Container Apps Best Practices
- **Modular Templates**: Separate modules for different resource types
- **Parameterization**: Make templates flexible with parameters
- **Secrets Management**: Never hardcode sensitive values
- **Resource Dependencies**: Use module outputs for dependencies
- **Naming Conventions**: Use consistent, descriptive names

### 3. Security Principles Applied
- **Least Privilege**: Services only access required resources
- **Secrets Protection**: Cosmos keys stored as secrets, not plain text
- **HTTPS Enforcement**: All ingress configured for secure transport
- **Network Isolation**: Services communicate within Container Apps environment
- **Audit Ready**: All actions logged to Log Analytics

### 4. Cosmos DB Serverless Advantages
- **Cost-Effective**: Pay only for operations consumed
- **Auto-Scaling**: No throughput provisioning required
- **Ideal for Dev/Test**: Perfect for variable workloads
- **Migration Path**: Can upgrade to provisioned throughput later

### 5. Scaling Configuration
- **Horizontal Scaling**: Replicas increase based on load
- **Metric-Based**: HTTP concurrency triggers scaling
- **Min/Max Replicas**: Prevents over/under scaling
- **Cost Control**: Max replicas limit prevents runaway costs

## Common Pitfalls and Solutions

### Pitfall 1: Missing Secrets Configuration
**Problem**: Cosmos key not added to secrets section
**Solution**: Each backend service includes secrets configuration with cosmos-key

### Pitfall 2: Incorrect Environment Variable References
**Problem**: Using `value` instead of `secretRef` for secrets
**Solution**: Secrets use `secretRef`, non-sensitive values use `value`

### Pitfall 3: Port Mismatch
**Problem**: Container App targetPort doesn't match service port
**Solution**: Verified ports: Pet (8010), Activity (8020), Accessory (8030), Frontend (80)

### Pitfall 4: Missing Dependencies
**Problem**: Services deployed before Cosmos DB ready
**Solution**: Used module outputs to create implicit dependencies

### Pitfall 5: Hardcoded Secrets in Outputs
**Problem**: Bicep warning about secrets in outputs
**Solution**: Outputs expose endpoints, not keys. Keys passed securely to services only.

## Success Validation

### Verify Deployment
```bash
# Check deployment status
az deployment group show \
  --resource-group petpal-rg \
  --name petpal-infrastructure \
  --query properties.provisioningState

# List Container Apps
az containerapp list \
  --resource-group petpal-rg \
  --output table

# Check Cosmos DB
az cosmosdb show \
  --resource-group petpal-rg \
  --name <cosmos-account-name>
```

### Test Endpoints
```bash
# Get frontend URL
FRONTEND_URL=$(az deployment group show \
  --resource-group petpal-rg \
  --name petpal-infrastructure \
  --query properties.outputs.frontendUrl.value -o tsv)

# Test frontend (should return 200)
curl -I $FRONTEND_URL

# Get pet service URL
PET_URL=$(az deployment group show \
  --resource-group petpal-rg \
  --name petpal-infrastructure \
  --query properties.outputs.petServiceUrl.value -o tsv)

# Test pet service API
curl $PET_URL/api/pets
```

### View Logs
```bash
# Stream Container App logs
az containerapp logs show \
  --name <container-app-name> \
  --resource-group petpal-rg \
  --follow

# Query Log Analytics
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "ContainerAppConsoleLogs_CL | where TimeGenerated > ago(1h)"
```

## Cost Estimation

**Development Environment (Monthly):**
- Container Apps Environment: ~$0 (consumption-based)
- Container Apps (4 services, 1-2 replicas avg): ~$20-40
- Cosmos DB Serverless (low usage): ~$5-15
- Log Analytics (basic): ~$5 (first 5GB free)
- **Total**: ~$30-60/month

**Production Environment (Monthly):**
- Scaled replicas and higher usage: ~$200-500/month
- Can be optimized based on actual usage patterns

## Next Steps

### 1. Application Deployment (Challenge 09)
- Build and push container images
- Update Container Apps with custom images
- Configure continuous deployment

### 2. Security Enhancements
- Implement Managed Identity for Cosmos DB
- Enable VNet integration
- Add Key Vault for secrets management
- Configure custom domains with SSL

### 3. Monitoring & Observability
- Set up Application Insights
- Create custom dashboards
- Configure alerts and notifications
- Implement distributed tracing

### 4. CI/CD Integration
- Create GitHub Actions workflow
- Automate Bicep deployments
- Implement environment promotion
- Add deployment approval gates

### 5. Advanced Features
- Configure Dapr for service communication
- Implement API Management gateway
- Add Azure Front Door for global distribution
- Enable geo-replication for Cosmos DB

## Additional Resources

### Official Documentation
- [Azure Container Apps](https://docs.microsoft.com/azure/container-apps/)
- [Azure Cosmos DB](https://docs.microsoft.com/azure/cosmos-db/)
- [Bicep Language](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Well-Architected Framework](https://docs.microsoft.com/azure/architecture/framework/)

### Security Best Practices
- [Azure Security Baseline for Container Apps](https://docs.microsoft.com/security/benchmark/azure/baselines/container-apps-security-baseline)
- [Cosmos DB Security](https://docs.microsoft.com/azure/cosmos-db/database-security)
- [Managed Identities](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/)

### Bicep Resources
- [Bicep Playground](https://aka.ms/bicepdemo)
- [Bicep Examples](https://github.com/Azure/bicep/tree/main/docs/examples)
- [Azure Quickstart Templates](https://github.com/Azure/azure-quickstart-templates)

## Troubleshooting Guide

### Issue: Deployment Fails with "Name Already Exists"
**Cause**: Resource names must be globally unique
**Solution**: Modify `uniqueSuffix` parameter or `environmentName`

### Issue: Container App Fails to Start
**Cause**: Missing or incorrect environment variables
**Solution**: Check Container App configuration and Cosmos DB connection

### Issue: Cannot Access Services
**Cause**: Ingress not properly configured
**Solution**: Verify ingress settings and external access enabled

### Issue: High Costs
**Cause**: Too many replicas or high RU consumption
**Solution**: Adjust scaling rules and optimize database queries

---

**Solution Status**: ✅ Complete and Production-Ready

This solution demonstrates enterprise-grade Infrastructure as Code practices with security, scalability, and maintainability in mind. It serves as a foundation for deploying microservices to Azure Container Apps and can be extended with additional features as requirements evolve.
