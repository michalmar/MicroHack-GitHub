# Challenge 08: Infrastructure as Code - Azure Deployment

## Overview

Deploy the PetPal microservices to Azure using Infrastructure as Code (IaC). This challenge focuses on provisioning the core infrastructure: Container Apps for backend services and frontend, and Cosmos DB for data storage.

## Learning Objectives

- Implement Infrastructure as Code (IaC) using Bicep
- Deploy microservices to Azure Container Apps
- Provision and configure Azure Cosmos DB
- Understand basic Azure resource management and deployment
- Experience with Azure Developer CLI (azd) for simplified deployments

## Prerequisites

- Azure subscription with appropriate permissions
- Completed Challenge 07 (backend services running locally)
- Azure CLI installed and configured
- Basic understanding of Azure services and containerization
- Familiarity with Bicep or willingness to learn

## Tasks

### Task 1: Infrastructure Design and Planning

1. **Architecture Review**:
   - Review the PetPal microservices architecture (3 backend services + 1 frontend)
   - Identify Azure resources needed:
     - Azure Container Apps Environment
     - 4 Container Apps (pet-service, activity-service, accessory-service, frontend)
     - Azure Cosmos DB (serverless)
     - Azure Container Registry (ACR) for storing Docker images
     - Log Analytics Workspace (for Container Apps requirement)
   - Plan resource naming conventions and organization

2. **Choose IaC Approach**:
   - **Recommended**: Use Bicep for Azure-native IaC
   - Alternative: Terraform or ARM templates
   - Understand modular infrastructure design
   - Plan for environment-specific configurations (dev, staging, prod)

### Task 2: Set Up Bicep Infrastructure

1. **Create Bicep Project Structure**:
   - Create `infra/` directory in your project root
   - Organize Bicep files by resource type:
     - `main.bicep` - orchestration template
     - `cosmos.bicep` - Cosmos DB configuration
     - `acr.bicep` - Azure Container Registry configuration
     - `container-app-environment.bicep` - Container Apps environment
     - `container-app.*.bicep` - individual Container App modules
   - Create `main.parameters.json` for parameter values

2. **Define Core Resources**:
   - Use Copilot to generate Bicep templates:
     ```
     "Create a Bicep template for Azure Container Apps environment with Log Analytics"
     
     "Generate Bicep for Cosmos DB serverless with SQL API"
     
     "Create Bicep template for Azure Container Registry with Basic SKU and admin enabled"
     
     "Create Bicep module for Container App with environment variables and ingress"
     ```

### Task 3: Implement Container Infrastructure

1. **Container Apps Environment**:
   - Define Container Apps managed environment
   - Configure Log Analytics workspace integration
   - Set up environment naming with unique suffixes

2. **Deploy Backend Services**:
   - Create Container App configurations for:
     - Pet Service (port 8010)
     - Activity Service (port 8020)
     - Accessory Service (port 8030)
   - Configure environment variables for each service:
     - `COSMOS_ENDPOINT`
     - `COSMOS_KEY`
     - `COSMOS_DATABASE_NAME`
     - `COSMOS_CONTAINER_NAME`
   - Enable external ingress for each service
   - Configure resource allocation (CPU, memory)

3. **Deploy Frontend**:
   - Create Container App for frontend (port 80)
   - Configure environment variables:
     - `VITE_API_PETS_URL`
     - `VITE_API_ACTIVITIES_URL`
     - `VITE_API_ACCESSORIES_URL`
   - Enable external ingress with public access

### Task 4: Implement Data Services

1. **Azure Cosmos DB Setup**:
   - Provision Cosmos DB account with serverless capability
   - Configure SQL API
   - Set up session consistency level
   - Define database and container specifications
   - Output connection strings and keys for Container Apps

2. **Database Configuration**:
   - Plan database structure:
     - Database: `petservice`, Container: `pets`
     - Database: `activityservice`, Container: `activities`
     - Database: `accessoryservice`, Container: `accessories`
   - Configure partition keys appropriately
   - Set up throughput settings (serverless mode)

3. **Azure Container Registry Setup**:
   - Provision Azure Container Registry (ACR) with Basic SKU
   - Enable admin user for simplified authentication (development)
   - Configure ACR to be in same resource group as Container Apps
   - Output ACR login server, username, and password
   - **Note**: In production, use managed identities instead of admin credentials

### Task 5: Deployment and Testing

1. **Deploy Infrastructure**:
   - Validate Bicep templates:
     ```bash
     az deployment group validate \
       --resource-group <rg-name> \
       --template-file infra/main.bicep \
       --parameters infra/main.parameters.json
     ```
   - Deploy to Azure:
     ```bash
     az deployment group create \
       --resource-group <rg-name> \
       --template-file infra/main.bicep \
       --parameters infra/main.parameters.json
     ```
   - **Alternative**: Use Azure Developer CLI (azd):
     ```bash
     azd init
     azd up
     ```

2. **Verify Deployment**:
   - Check all Container Apps are running
   - Test backend service endpoints
   - Verify frontend loads and connects to backends
   - Confirm Cosmos DB databases and containers created
   - Verify ACR is created and accessible
   - Review deployment outputs (URLs, connection strings, ACR credentials)
   - **Save ACR credentials** for use in Challenge 09 (CI/CD):
     ```bash
     # Get ACR credentials from deployment outputs
     ACR_LOGIN_SERVER=$(az deployment group show \
       --resource-group <rg-name> \
       --name <deployment-name> \
       --query properties.outputs.acrLoginServer.value -o tsv)
     
     ACR_USERNAME=$(az acr credential show \
       --name <acr-name> \
       --query username -o tsv)
     
     ACR_PASSWORD=$(az acr credential show \
       --name <acr-name> \
       --query passwords[0].value -o tsv)
     ```

3. **Test the Application**:
   - Access frontend URL from deployment outputs
   - Test CRUD operations for pets, activities, and accessories
   - Verify data persists in Cosmos DB
   - Check Container Apps logs for errors

### Task 6: [OPTIONAL] Infrastructure Documentation

1. **Document Your Infrastructure**:
   - Create README in `infra/` directory
   - Document deployment steps
   - List required parameters and their purposes
   - Include troubleshooting guide
   - Document resource naming conventions

2. **Create Deployment Scripts**:
   - Create `deploy.sh` (or `deploy.ps1`) for automated deployment
   - Add validation and error handling
   - Include deployment output display
   - Add cleanup script for resource deletion

## Success Criteria

- [ ] Infrastructure code organized in modular Bicep templates
- [ ] Azure Container Apps Environment deployed with Log Analytics
- [ ] Four Container Apps deployed (pet, activity, accessory, frontend)
- [ ] Azure Cosmos DB provisioned with serverless capability
- [ ] Azure Container Registry (ACR) created and accessible
- [ ] All services have correct environment variables configured
- [ ] Services accessible via HTTPS endpoints
- [ ] Frontend connects to backend APIs successfully
- [ ] Data persists in Cosmos DB
- [ ] ACR credentials saved for CI/CD (Challenge 09)
- [ ] Deployment can be repeated reliably (infrastructure as code)

**Preparation for Challenge 09:**
After completing this challenge, you should have:
- ACR login server URL (e.g., `petpal12345.azurecr.io`)
- ACR admin username and password
- Resource group name
- Container App names for all services

These will be used in Challenge 09 for automated deployments via GitHub Actions.

## Infrastructure as Code with Copilot

### Getting Started with Bicep
Use GitHub Copilot to generate Bicep templates:

```
"Create main.bicep orchestration template for PetPal microservices"

"Generate Bicep module for Azure Container App with parameters for image, environment variables, and ingress"

"Create Bicep template for Cosmos DB serverless with output for connection string"

"Generate parameters file for Bicep with location, environment name, and image tags"
```

### Copilot Tips
- Ask Copilot to explain Bicep syntax and best practices
- Use Copilot to generate module parameters and outputs
- Guide Copilot by referencing any specific files (#)
- Specify ACA images (hello world - mcr.microsoft.com/azuredocs/containerapps-helloworld:latest )
- Request Copilot to create deployment scripts
- Ask for troubleshooting help with deployment errors

## Azure Developer CLI (azd) - Recommended Approach

### Why Use azd?
- Simplified infrastructure provisioning and deployment
- Built-in support for Bicep templates
- Streamlined environment management
- Integrated CI/CD workflows
- Consistent deployment experience

### Getting Started with azd
```bash
# Initialize azd project
azd init

# Provision infrastructure and deploy
azd up

# Deploy code changes only
azd deploy

# Clean up all resources
azd down
```

### azd Project Structure
```
/
├── infra/                  # Bicep templates
│   ├── main.bicep
│   ├── main.parameters.json
│   └── modules/
├── azure.yaml             # azd configuration
└── .azure/                # azd environment files
```

## Resource Naming Conventions

Use consistent naming patterns for better organization:
- Resource Group: `rg-petpal-{env}`
- Container Apps Environment: `petpal-{env}-env`
- Container Apps: `petpal-{env}-{service-name}`
- Cosmos DB: `cosmos-petpal-{env}-{uniqueid}`
- Log Analytics: `logs-petpal-{env}`

## Troubleshooting Common Issues

### Deployment Failures
- Check resource naming conflicts (use unique suffixes)
- Verify subscription permissions
- Review Bicep validation warnings
- Check parameter values match expected types

### Container Apps Not Starting
- Verify container image exists and is accessible
- Check environment variables are set correctly
- Review Container Apps logs in Azure Portal
- Verify Log Analytics workspace connection

### Service Communication Issues
- Confirm all services have external ingress enabled
- Check environment variable URLs are correct
- Verify network connectivity between services
- Test endpoints individually before integration

### Cosmos DB Connection Issues
- Verify connection string format
- Check Cosmos DB key is correctly passed
- Confirm database and container names match
- Review firewall settings (allow Azure services)

## Cost Considerations

**Estimated monthly costs for development environment:**
- Container Apps (4 services): ~$30-60
- Cosmos DB (serverless): ~$5-15 (depends on usage)
- Log Analytics: ~$5 (5GB free tier)

**Total estimated cost: $40-80/month**

💡 **Tip**: Delete resources when not in use to minimize costs!

## Optional Extensions (Not Required for Challenge Completion)

The following topics are advanced features that can enhance your deployment but are **not required** to complete this challenge:

### Security Enhancements
- Implement managed identities for service authentication
- Use Azure Key Vault for secrets management
- Configure private endpoints for Cosmos DB
- Set up network security groups and access restrictions
- Implement Azure AD authentication

### Monitoring and Observability
- Configure Application Insights for distributed tracing
- Set up Azure Monitor dashboards
- Create alerts for service health and performance
- Implement custom metrics and logging
- Configure log aggregation and analysis

### Deployment Automation
- Create GitHub Actions workflows for CI/CD
- Implement automated testing before deployment
- Set up environment promotion pipelines
- Configure blue-green or canary deployments
- Implement rollback strategies

These optional extensions will be covered in future challenges focused on production readiness, security hardening, and operational excellence.

## Additional Resources

- [Azure Container Apps Documentation](https://docs.microsoft.com/azure/container-apps/)
- [Bicep Language Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Developer CLI (azd)](https://docs.microsoft.com/azure/developer/azure-developer-cli/)
- [Azure Cosmos DB Serverless](https://docs.microsoft.com/azure/cosmos-db/serverless)
- [Container Apps Pricing](https://azure.microsoft.com/pricing/details/container-apps/)

## Solution

Need help? Check the [Solution Guide](/solutions/challenge-08/README.md) for detailed implementation steps and reference code.
