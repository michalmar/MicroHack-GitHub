// Cosmos DB Account - Serverless Configuration
// Provisions Azure Cosmos DB with serverless capability model

@description('Cosmos DB account name')
param accountName string

@description('Location for the Cosmos DB account')
param location string = resourceGroup().location

@description('The default consistency level of the Cosmos DB account')
@allowed([
  'Eventual'
  'ConsistentPrefix'
  'Session'
  'BoundedStaleness'
  'Strong'
])
param defaultConsistencyLevel string = 'Session'

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2025-04-15' = {
  name: accountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: defaultConsistencyLevel
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
    enableFreeTier: false
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    publicNetworkAccess: 'Enabled'
    disableKeyBasedMetadataWriteAccess: false
  }
}

// Outputs
output endpoint string = cosmosAccount.properties.documentEndpoint
output primaryKey string = cosmosAccount.listKeys().primaryMasterKey
output accountName string = cosmosAccount.name
output accountId string = cosmosAccount.id
