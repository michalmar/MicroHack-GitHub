// Container App for Activity Service
// Provisions Azure Container App for the Activity microservice with Entra ID authentication to Cosmos DB
// NOTE: Currently using hello world container for infrastructure provisioning
//       Replace with actual service image during application deployment phase

@description('Name of the Container App')
param name string

@description('Location for the Container App')
param location string = resourceGroup().location

@description('Container Apps Environment ID')
param containerAppEnvironmentId string

@description('Cosmos DB endpoint')
param cosmosEndpoint string

@description('Cosmos DB account resource ID for RBAC role assignment')
param cosmosAccountId string

@description('Cosmos DB Data Contributor role definition ID')
param cosmosDataContributorRoleId string = ''

@description('Cosmos DB database name')
param cosmosDatabaseName string = 'activityservice'

@description('Cosmos DB container name')
param cosmosContainerName string = 'activities'

@description('Whether to pre-provision the Cosmos SQL database and container (avoids needing sqlDatabases/write at runtime).')
param provisionCosmosResources bool = true

@description('Azure Container Registry name')
param acrName string = ''

@description('Azure Container Registry login server')
param acrLoginServer string = ''

// Managed Identity for ACR Pull - separate identity per microservice
resource activityServiceIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${name}-identity'
  location: location
}

// Reference to ACR for role assignment
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = if (acrName != '') {
  name: acrName
}

// Grant AcrPull role to the managed identity if ACR is specified
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (acrName != '') {
  name: guid(acr.id, activityServiceIdentity.id, 'acrpull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    ) // AcrPull role
    principalId: activityServiceIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Reference to Cosmos DB account for role assignment
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2025-04-15' existing = {
  name: split(cosmosAccountId, '/')[8] // Extract account name from resource ID
}

// Grant Cosmos DB Data Contributor role to the managed identity (for data plane operations)
var useCustomDataPlaneRole = empty(cosmosDataContributorRoleId)
var cosmosDataPlaneRoleDefinitionId = useCustomDataPlaneRole
  ? cosmosCustomDataPlaneRoleDefinition.id
  : '${cosmosAccountId}/sqlRoleDefinitions/${cosmosDataContributorRoleId}'

resource cosmosCustomDataPlaneRoleDefinition 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2025-04-15' = if (useCustomDataPlaneRole) {
  name: guid(cosmosAccount.id, '${name}-data-role')
  parent: cosmosAccount
  properties: {
    roleName: '${name}-data-role'
    type: 'CustomRole'
    assignableScopes: [ cosmosAccount.id ]
    permissions: [
      {
        dataActions: [
          'Microsoft.DocumentDB/databaseAccounts/readMetadata'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/*'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
        ]
      }
    ]
  }
}

resource cosmosRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2025-04-15' = {
  name: guid(cosmosAccountId, activityServiceIdentity.id, 'cosmos-data-contributor')
  parent: cosmosAccount
  properties: {
    roleDefinitionId: cosmosDataPlaneRoleDefinitionId
    principalId: activityServiceIdentity.properties.principalId
    scope: cosmosAccountId
  }
}

resource activityDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2025-04-15' = if (provisionCosmosResources) {
  name: cosmosDatabaseName
  parent: cosmosAccount
  properties: {
    resource: { id: cosmosDatabaseName }
    options: {}
  }
}

resource activityContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2025-04-15' = if (provisionCosmosResources) {
  name: cosmosContainerName
  parent: activityDatabase
  properties: {
    resource: {
      id: cosmosContainerName
      partitionKey: { paths: [ '/id' ], kind: 'Hash' }
    }
    options: {}
  }
}

resource activityServiceApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: name
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${activityServiceIdentity.id}': {}
    }
  }
  properties: {
    environmentId: containerAppEnvironmentId
    configuration: {
      ingress: {
        external: true
        targetPort: 8020
        transport: 'auto'
        allowInsecure: false
      }
      registries: (acrLoginServer != '')
        ? [
            {
              server: acrLoginServer
              identity: activityServiceIdentity.id
            }
          ]
        : []
      // No secrets needed - using Managed Identity for Cosmos DB auth
    }
    template: {
      containers: [
        {
          name: 'simple-hello'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'AZURE_CLIENT_ID'
              value: activityServiceIdentity.properties.clientId
            }
            {
              name: 'COSMOS_ENDPOINT'
              value: cosmosEndpoint
            }
            {
              name: 'COSMOS_DATABASE_NAME'
              value: cosmosDatabaseName
            }
            {
              name: 'COSMOS_CONTAINER_NAME'
              value: cosmosContainerName
            }
            // No COSMOS_KEY - using Managed Identity authentication
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
        rules: [
          {
            name: 'http-rule'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}

// Outputs
output fqdn string = 'https://${activityServiceApp.properties.configuration.ingress.fqdn}'
output name string = activityServiceApp.name
output id string = activityServiceApp.id
output identityPrincipalId string = activityServiceIdentity.properties.principalId
output identityClientId string = activityServiceIdentity.properties.clientId
output dataPlaneRoleDefinitionId string = cosmosDataPlaneRoleDefinitionId
output databaseProvisioned bool = provisionCosmosResources
