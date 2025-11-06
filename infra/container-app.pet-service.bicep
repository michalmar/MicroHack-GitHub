// Container App for Pet Service
// Provisions Azure Container App for the Pet microservice
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

@description('Cosmos DB key')
@secure()
param cosmosKey string

@description('Cosmos DB database name')
param cosmosDatabaseName string = 'petservice'

@description('Cosmos DB container name')
param cosmosContainerName string = 'pets'

resource petServiceApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: name
  location: location
  properties: {
    environmentId: containerAppEnvironmentId
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        transport: 'auto'
        allowInsecure: false
      }
      secrets: [
        {
          name: 'cosmos-key'
          value: cosmosKey
        }
      ]
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
              name: 'COSMOS_ENDPOINT'
              value: cosmosEndpoint
            }
            {
              name: 'COSMOS_KEY'
              secretRef: 'cosmos-key'
            }
            {
              name: 'COSMOS_DATABASE_NAME'
              value: cosmosDatabaseName
            }
            {
              name: 'COSMOS_CONTAINER_NAME'
              value: cosmosContainerName
            }
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
