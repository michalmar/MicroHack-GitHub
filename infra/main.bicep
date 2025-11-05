// Main Bicep template for PetPal microservices infrastructure
// This template provisions:
// - Azure Container Apps Environment
// - Azure Cosmos DB (serverless)
// - Container Apps for each microservice (pets, activities, accessories)
// - Container App for frontend
// NOTE: Backend services use hello world containers for infrastructure provisioning
//       Actual service images will be deployed in a separate application deployment phase

targetScope = 'resourceGroup'

// Parameters
@description('The location for all resources')
param location string = resourceGroup().location

@description('Environment name (e.g., dev, staging, prod)')
@minLength(3)
@maxLength(10)
param environmentName string = 'dev'

@description('Unique suffix for resource names to ensure global uniqueness')
param uniqueSuffix string = uniqueString(resourceGroup().id)

@description('Frontend container image')
param frontendImage string = 'ghcr.io/michalmar/petpal-ui:latest'

// Variables
var resourcePrefix = 'petpal-${environmentName}'
var cosmosAccountName = '${resourcePrefix}-cosmos-${uniqueSuffix}'
var containerAppEnvName = '${resourcePrefix}-env-${uniqueSuffix}'
var logAnalyticsName = '${resourcePrefix}-logs-${uniqueSuffix}'

// Module imports
module cosmosDb 'cosmos.bicep' = {
  name: 'cosmosdb-deployment'
  params: {
    accountName: cosmosAccountName
    location: location
  }
}

module containerAppEnvironment 'container-app-environment.bicep' = {
  name: 'container-app-env-deployment'
  params: {
    environmentName: containerAppEnvName
    logAnalyticsName: logAnalyticsName
    location: location
  }
}

module petService 'container-app.pet-service.bicep' = {
  name: 'pet-service-deployment'
  params: {
    name: '${resourcePrefix}-pet-service'
    location: location
    containerAppEnvironmentId: containerAppEnvironment.outputs.environmentId
    cosmosEndpoint: cosmosDb.outputs.endpoint
    cosmosKey: cosmosDb.outputs.primaryKey
  }
  dependsOn: [
    containerAppEnvironment
    cosmosDb
  ]
}

module activityService 'container-app.activity-service.bicep' = {
  name: 'activity-service-deployment'
  params: {
    name: '${resourcePrefix}-activity-service'
    location: location
    containerAppEnvironmentId: containerAppEnvironment.outputs.environmentId
    cosmosEndpoint: cosmosDb.outputs.endpoint
    cosmosKey: cosmosDb.outputs.primaryKey
  }
  dependsOn: [
    containerAppEnvironment
    cosmosDb
  ]
}

module accessoryService 'container-app.accessory-service.bicep' = {
  name: 'accessory-service-deployment'
  params: {
    name: '${resourcePrefix}-accessory-service'
    location: location
    containerAppEnvironmentId: containerAppEnvironment.outputs.environmentId
    cosmosEndpoint: cosmosDb.outputs.endpoint
    cosmosKey: cosmosDb.outputs.primaryKey
  }
  dependsOn: [
    containerAppEnvironment
    cosmosDb
  ]
}

module frontend 'container-app.frontend.bicep' = {
  name: 'frontend-deployment'
  params: {
    name: '${resourcePrefix}-frontend'
    location: location
    containerAppEnvironmentId: containerAppEnvironment.outputs.environmentId
    frontendImage: frontendImage
    petServiceUrl: petService.outputs.fqdn
    activityServiceUrl: activityService.outputs.fqdn
    accessoryServiceUrl: accessoryService.outputs.fqdn
  }
  dependsOn: [
    containerAppEnvironment
    petService
    activityService
    accessoryService
  ]
}

// Outputs
output cosmosEndpoint string = cosmosDb.outputs.endpoint
output petServiceUrl string = petService.outputs.fqdn
output activityServiceUrl string = activityService.outputs.fqdn
output accessoryServiceUrl string = accessoryService.outputs.fqdn
output frontendUrl string = frontend.outputs.fqdn
