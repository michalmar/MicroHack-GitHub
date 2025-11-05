# PetPal Infrastructure - Quick Start Guide

Get the PetPal microservices infrastructure up and running in Azure in under 10 minutes!

## Prerequisites (2 minutes)

1. **Azure CLI** installed:
   ```bash
   az version
   ```
   If not installed: https://aka.ms/azure-cli

2. **Login to Azure**:
   ```bash
   az login
   az account set --subscription <your-subscription-id>
   ```

3. **Verify access**:
   ```bash
   az account show
   ```

## Quick Deployment (5 minutes)

### Option 1: Using the Deployment Script (Easiest)

```bash
cd /workspaces/MicroHack-GitHub/infra
./deploy.sh
```

Follow the prompts:
- Resource Group: `petpal-rg` (or your choice)
- Location: `eastus` (or your choice)
- Environment: `dev`
- Accept default image tags (press Enter for each)

### Option 2: Using Azure CLI Directly

```bash
cd /workspaces/MicroHack-GitHub/infra

# Create resource group
az group create --name petpal-rg --location eastus

# Deploy infrastructure
az deployment group create \
  --resource-group petpal-rg \
  --template-file main.bicep \
  --parameters main.parameters.json \
  --name petpal-infrastructure
```

## Verify Deployment (2 minutes)

```bash
# Get deployment outputs
az deployment group show \
  --resource-group petpal-rg \
  --name petpal-infrastructure \
  --query properties.outputs

# Get frontend URL
FRONTEND_URL=$(az deployment group show \
  --resource-group petpal-rg \
  --name petpal-infrastructure \
  --query properties.outputs.frontendUrl.value -o tsv)

# Open in browser
echo "Frontend URL: $FRONTEND_URL"
```

## What Gets Deployed

✅ **Container Apps Environment** - Hosting platform  
✅ **Log Analytics Workspace** - Centralized logging  
✅ **Cosmos DB Account** - Serverless NoSQL database  
✅ **Pet Service** - Container App using hello world container (port 80)  
✅ **Activity Service** - Container App using hello world container (port 80)  
✅ **Accessory Service** - Container App using hello world container (port 80)  
✅ **Frontend** - React UI Container App (port 80)

> **Note**: Backend services currently use `mcr.microsoft.com/azuredocs/containerapps-helloworld:latest` as placeholder containers for infrastructure provisioning. This validates the infrastructure setup before deploying actual service images. All environment variables and database configurations are pre-configured for future service deployment.

## Common Commands

### View Resources
```bash
az resource list --resource-group petpal-rg --output table
```

### View Container Apps
```bash
az containerapp list --resource-group petpal-rg --output table
```

### Stream Logs
```bash
az containerapp logs show \
  --name petpal-dev-pet-service \
  --resource-group petpal-rg \
  --follow
```

### Get Service URLs
```bash
# All services
az deployment group show \
  --resource-group petpal-rg \
  --name petpal-infrastructure \
  --query properties.outputs

# Just frontend
az deployment group show \
  --resource-group petpal-rg \
  --name petpal-infrastructure \
  --query properties.outputs.frontendUrl.value -o tsv
```

## Test Your Deployment

> **Note**: Backend services are running hello world containers, so they will respond with a simple hello world page instead of pet service APIs. This is expected for infrastructure provisioning phase.

```bash
# Get URLs
PET_URL=$(az deployment group show \
  --resource-group petpal-rg \
  --name petpal-infrastructure \
  --query properties.outputs.petServiceUrl.value -o tsv)

FRONTEND_URL=$(az deployment group show \
  --resource-group petpal-rg \
  --name petpal-infrastructure \
  --query properties.outputs.frontendUrl.value -o tsv)

# Test pet service endpoint (returns hello world page)
curl ${PET_URL}

# Test frontend
curl -I $FRONTEND_URL
```

## Cleanup

When you're done:

```bash
# Delete resource group (removes all resources)
az group delete --name petpal-rg --yes --no-wait
```

## Troubleshooting

### Deployment Failed?
```bash
# Check deployment errors
az deployment group show \
  --resource-group petpal-rg \
  --name petpal-infrastructure \
  --query properties.error
```

### Services Not Starting?
```bash
# Check container app status
az containerapp show \
  --name petpal-dev-pet-service \
  --resource-group petpal-rg \
  --query properties.runningStatus

# View logs
az containerapp logs show \
  --name petpal-dev-pet-service \
  --resource-group petpal-rg \
  --tail 50
```

### Name Already Exists?
The `uniqueSuffix` parameter uses `uniqueString(resourceGroup().id)` to ensure unique names. If you still encounter conflicts, modify the `environmentName` parameter:

```bash
az deployment group create \
  --resource-group petpal-rg \
  --template-file main.bicep \
  --parameters main.parameters.json \
  --parameters environmentName=dev2 \
  --name petpal-infrastructure
```

## Next Steps

1. **Explore the deployed resources** in the Azure Portal
2. **View logs** in Log Analytics workspace
3. **Test the APIs** using the provided URLs
4. **Customize the deployment** by modifying parameters
5. **Deploy your own container images** (Challenge 09)

## Estimated Costs

💰 **Development (low usage)**: ~$30-60/month
- Container Apps: ~$20-40
- Cosmos DB Serverless: ~$5-15
- Log Analytics: ~$5 (5GB free tier)

💡 **Tip**: Delete resources when not in use to avoid charges!

## Need Help?

- 📖 [Full Documentation](README.md)
- 📋 [Solution Guide](../solutions/challenge-08/README.md)
- 🔗 [Azure Container Apps Docs](https://docs.microsoft.com/azure/container-apps/)
- 🔗 [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)

---

**Ready to Deploy?** Run `./deploy.sh` and you'll be up in minutes! 🚀
