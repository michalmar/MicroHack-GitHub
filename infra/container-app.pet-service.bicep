// Container App for Pet Service
// Provisions Azure Container App for the Pet microservice with Entra ID authentication to Cosmos DB
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

@description('Cosmos DB Data Contributor role definition ID. Leave empty to create a custom role for the pet service.')
param cosmosDataContributorRoleId string = ''

@description('Cosmos DB database name')
param cosmosDatabaseName string = 'petservice'

@description('Cosmos DB container name')
param cosmosContainerName string = 'pets'

@description('Azure RBAC role definition ID to grant control plane permissions (defaults to Cosmos DB Operator).')
param cosmosControlPlaneRoleDefinitionId string = '230815da-be43-4aae-9cb4-875f7bd000aa'

@description('Name of the custom Cosmos DB data plane role definition to create when no built-in role is supplied.')
param cosmosDataRoleDefinitionName string = '${name}-data-role'

@description('Optional scope suffix for the data plane role assignment (for example "/dbs/petservice"). Leave empty to scope to the entire account.')
param cosmosDataPlaneScope string = ''

@description('Azure Container Registry name')
param acrName string = ''

@description('Azure Container Registry login server')
param acrLoginServer string = ''

// Managed Identity for ACR Pull - always create for future use
resource petServiceIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${name}-identity'
  location: location
}

// Reference to ACR for role assignment
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = if (acrName != '') {
  name: acrName
}

// Grant AcrPull role to the managed identity if ACR is specified
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (acrName != '') {
  name: guid(acr.id, petServiceIdentity.id, 'acrpull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    ) // AcrPull role
    principalId: petServiceIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Reference to Cosmos DB account for role assignment
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2025-04-15' existing = {
  name: split(cosmosAccountId, '/')[8] // Extract account name from resource ID
}

var useCustomCosmosDataRole = empty(cosmosDataContributorRoleId)
var cosmosDataPlaneRoleDefinitionId = useCustomCosmosDataRole
  ? cosmosDataPlaneRoleDefinition.id
  : '${cosmosAccountId}/sqlRoleDefinitions/${cosmosDataContributorRoleId}'
var cosmosDataPlaneAssignmentScope = empty(cosmosDataPlaneScope)
  ? cosmosAccountId
  : (startsWith(cosmosDataPlaneScope, '/subscriptions/')
      ? cosmosDataPlaneScope
      : '${cosmosAccountId}${cosmosDataPlaneScope}')

resource cosmosDataPlaneRoleDefinition 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2025-04-15' = if (useCustomCosmosDataRole) {
  name: guid(cosmosAccount.id, cosmosDataRoleDefinitionName)
  parent: cosmosAccount
  properties: {
    roleName: cosmosDataRoleDefinitionName
    type: 'CustomRole'
    assignableScopes: [
      cosmosAccount.id
    ]
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

// Grant Cosmos DB data plane permissions to the managed identity
resource cosmosRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2025-04-15' = {
  name: guid(cosmosAccountId, petServiceIdentity.id, 'cosmos-data-contributor')
  parent: cosmosAccount
  properties: {
    roleDefinitionId: cosmosDataPlaneRoleDefinitionId
    principalId: petServiceIdentity.properties.principalId
    scope: cosmosDataPlaneAssignmentScope
  }
}

// Grant control plane access so the identity can manage Cosmos DB account resources when required
resource cosmosControlPlaneRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cosmosAccountId, petServiceIdentity.id, 'cosmos-control-plane')
  scope: cosmosAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      cosmosControlPlaneRoleDefinitionId
    )
    principalId: petServiceIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource petServiceApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: name
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${petServiceIdentity.id}': {}
    }
  }
  properties: {
    environmentId: containerAppEnvironmentId
    configuration: {
      ingress: {
        external: true
        targetPort: 8010
        transport: 'auto'
        allowInsecure: false
      }
      registries: (acrLoginServer != '')
        ? [
            {
              server: acrLoginServer
              identity: petServiceIdentity.id
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
              value: petServiceIdentity.properties.clientId
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
output fqdn string = 'https://${petServiceApp.properties.configuration.ingress.fqdn}'
output name string = petServiceApp.name
output id string = petServiceApp.id
output identityPrincipalId string = petServiceIdentity.properties.principalId
output identityClientId string = petServiceIdentity.properties.clientId
