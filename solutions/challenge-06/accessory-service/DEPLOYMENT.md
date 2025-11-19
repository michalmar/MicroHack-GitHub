# Service Deployment Plan

Describe how this service moves from commit to production, referencing shared workflows in `../../platform/DEPLOYMENT.md`.

## Pipelines
- **CI**: Standard Python CI (linting, tests).
- **CD**: Build Docker image, push to ACR, deploy to Azure Container Apps.

## Environments
| Environment | Branch/Artifact | Purpose | Approvals |
| --- | --- | --- | --- |
| **Development** | `main` | Integration testing | None |
| **Production** | Tagged Release | Live traffic | Manual |

## Infrastructure
- **Compute**: Azure Container Apps (`accessory-service`).
- **Database**: Azure Cosmos DB (`accessoryservice` database, `accessories` container).
- **IaC**: Bicep templates in `infra/` folder (e.g., `container-app.accessory-service.bicep`).
