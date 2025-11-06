// Main Bicep template for PetPal microservices infrastructure
// This template provisions:
// - Azure Container Registry (ACR) for Docker images
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

@description('Toggle creation of the user-assigned managed identity for GitHub Actions federation')
param enableGitHubManagedIdentity bool = true

@description('Repository in owner/name format used when constructing GitHub federated credentials')
@minLength(3)
param githubRepository string = 'michalmar/MicroHack-GitHub'

@description('Subjects for GitHub federated identity credentials (for example repo:owner/name:ref:refs/heads/main)')
param githubFederatedSubjects array = [
  'repo:${githubRepository}:ref:refs/heads/main'
]

// Variables
var resourcePrefix = 'petpal-${environmentName}'
var cosmosAccountName = '${resourcePrefix}-cosmos-${uniqueSuffix}'
var containerAppEnvName = '${resourcePrefix}-env-${uniqueSuffix}'
var logAnalyticsName = '${resourcePrefix}-logs-${uniqueSuffix}'
var acrName = replace('${resourcePrefix}acr${uniqueSuffix}', '-', '') // ACR names cannot contain hyphens
var githubIdentityName = '${resourcePrefix}-gha-mi-${uniqueSuffix}'

// Module imports
module containerRegistry 'acr.bicep' = {
  name: 'acr-deployment'
  params: {
    name: acrName
    location: location
    sku: 'Basic'
    adminUserEnabled: false
  }
}

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
}

resource containerRegistryExisting 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = if (enableGitHubManagedIdentity) {
  name: acrName
}

resource githubManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' = if (enableGitHubManagedIdentity) {
  name: githubIdentityName
  location: location
}

// resource githubFederatedIdentityCredentials 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2025-01-31-preview' = [for subject in githubFederatedSubjects: if (enableGitHubManagedIdentity) {
//   name: guid(githubManagedIdentity.id, subject)
//   parent: githubManagedIdentity
//   properties: {
//     issuer: 'https://token.actions.githubusercontent.com'
//     subject: subject
//     audiences: [
//       'api://AzureADTokenExchange'
//     ]
//   }
// }]

resource githubIdentityContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableGitHubManagedIdentity) {
  name: guid(subscription().subscriptionId, githubManagedIdentity.id, 'contributor')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'b24988ac-6180-42a0-ab88-20f7382dd24c'
    )
    principalId: githubManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource githubIdentityAcrPushRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableGitHubManagedIdentity) {
  name: guid(subscription().subscriptionId, githubManagedIdentity.id, 'acr-push')
  scope: containerRegistryExisting
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '8311e382-0749-4cb8-b61a-304f252e45ec'
    )
    principalId: githubManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output cosmosEndpoint string = cosmosDb.outputs.endpoint
output acrLoginServer string = containerRegistry.outputs.loginServer
output acrName string = containerRegistry.outputs.name
output acrResourceId string = containerRegistry.outputs.id
output petServiceUrl string = petService.outputs.fqdn
output activityServiceUrl string = activityService.outputs.fqdn
output accessoryServiceUrl string = accessoryService.outputs.fqdn
output frontendUrl string = frontend.outputs.fqdn
output githubManagedIdentityClientId string = enableGitHubManagedIdentity
  ? githubManagedIdentity.properties.clientId
  : ''
output githubManagedIdentityPrincipalId string = enableGitHubManagedIdentity
  ? githubManagedIdentity.properties.principalId
  : ''
output githubManagedIdentityResourceId string = enableGitHubManagedIdentity ? githubManagedIdentity.id : ''
