# Solution: Challenge 09 - Deployment Automation using GitHub Actions

This solution demonstrates implementing comprehensive CI/CD pipelines with GitHub Actions, including best practices for automated testing, building, and deployment.

## Overview

This challenge focuses on creating production-ready CI/CD pipelines that automate the entire software delivery process from code commit to production deployment.

## Solution Implementation

### Quick Start: Test Your Deployment

After deploying your services, validate the deployment health:

**Linux/macOS:**
```bash
./test-deployment-health.sh -r "rg-petpal-dev"
```

**Windows PowerShell:**
```powershell
./test-deployment-health.ps1 -ResourceGroup "rg-petpal-dev"
```

**VS Code REST Client:**
Open `test-deployment-health.http` and click "Send Request" on each test.

📖 **See [TEST_DEPLOYMENT.md](./TEST_DEPLOYMENT.md) for complete testing documentation.**

---

### Step 1: Basic CI/CD Pipeline Structure

> **Important Authentication Update**: This solution now uses **Managed Identity with RBAC** for Cosmos DB authentication. Container Apps authenticate using their user-assigned managed identities with the **Cosmos DB Data Contributor** role instead of master keys. This eliminates secret management for database access.

Create `.github/workflows/ci-cd.yml`:

```yaml
name: CI/CD Pipeline - Pet Management Services

on:
  push:
    branches: [main, develop]
    paths: 
      - 'backend/**'
  pull_request:
    branches: [main]
    paths:
      - 'backend/**'
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        required: true
        default: 'staging'
        type: choice
        options:
        - staging
        - production

env:
  REGISTRY: ${{ vars.ACR_NAME }}
  AZURE_RESOURCE_GROUP: ${{ vars.RESOURCE_GROUP_NAME }}

# Note: No COSMOS_KEY needed - services use Managed Identity with RBAC

jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      pet-service: ${{ steps.changes.outputs.pet-service }}
      activity-service: ${{ steps.changes.outputs.activity-service }}
      accessory-service: ${{ steps.changes.outputs.accessory-service }}
    steps:
      - uses: actions/checkout@v4
      - uses: dorny/paths-filter@v2
        id: changes
        with:
          filters: |
            pet-service:
              - 'backend/pet-service/**'
            activity-service:
              - 'backend/activity-service/**'
            accessory-service:
              - 'backend/accessory-service/**'

  test:
    runs-on: ubuntu-latest
    needs: changes
    strategy:
      matrix:
        service: [pet-service, activity-service, accessory-service]
    steps:
      - uses: actions/checkout@v4
        if: needs.changes.outputs[matrix.service] == 'true'
      
      - name: Set up Python
        if: needs.changes.outputs[matrix.service] == 'true'
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
          cache: 'pip'
      
      - name: Install dependencies
        if: needs.changes.outputs[matrix.service] == 'true'
        run: |
          cd backend/${{ matrix.service }}
          pip install -r requirements.txt
          pip install -r requirements-dev.txt
      
      - name: Run tests
        if: needs.changes.outputs[matrix.service] == 'true'
        run: |
          cd backend/${{ matrix.service }}
          python -m pytest tests/ -v --cov=. --cov-report=xml
      
      - name: Upload coverage reports
        if: needs.changes.outputs[matrix.service] == 'true'
        uses: codecov/codecov-action@v3
        with:
          file: backend/${{ matrix.service }}/coverage.xml
          flags: ${{ matrix.service }}

  security-scan:
    runs-on: ubuntu-latest
    needs: changes
    if: always()
    steps:
      - uses: actions/checkout@v4
      
      - name: Run security scan
        uses: github/codeql-action/analyze@v2
        with:
          languages: python
      
      - name: Run dependency check
        uses: pypa/gh-action-pip-audit@v1.0.8
        with:
          inputs: backend/*/requirements.txt

  build:
    runs-on: ubuntu-latest
    needs: [test, security-scan]
    if: github.ref == 'refs/heads/main' || github.event_name == 'workflow_dispatch'
    strategy:
      matrix:
        service: [pet-service, activity-service, accessory-service]
    steps:
      - uses: actions/checkout@v4
        if: needs.changes.outputs[matrix.service] == 'true'
      
      - name: Azure Login
        if: needs.changes.outputs[matrix.service] == 'true'
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Build and push Docker image
        if: needs.changes.outputs[matrix.service] == 'true'
        run: |
          SERVICE_NAME=${{ matrix.service }}
          IMAGE_TAG="${{ env.REGISTRY }}.azurecr.io/${SERVICE_NAME}:${{ github.sha }}"
          
          cd backend/${{ matrix.service }}
          
          # Build image
          docker build -t ${IMAGE_TAG} .
          docker tag ${IMAGE_TAG} ${{ env.REGISTRY }}.azurecr.io/${SERVICE_NAME}:latest
          
          # Push to ACR
          az acr login --name ${{ env.REGISTRY }}
          docker push ${IMAGE_TAG}
          docker push ${{ env.REGISTRY }}.azurecr.io/${SERVICE_NAME}:latest

  deploy-staging:
    runs-on: ubuntu-latest
    needs: [build, changes]
    if: github.ref == 'refs/heads/main'
    environment: staging
    strategy:
      matrix:
        service: [pet-service, activity-service, accessory-service]
    steps:
      - uses: actions/checkout@v4
        if: needs.changes.outputs[matrix.service] == 'true'
      
      - name: Azure Login
        if: needs.changes.outputs[matrix.service] == 'true'
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Get managed identity
        if: needs.changes.outputs[matrix.service] == 'true'
        id: identity
        run: |
          APP_NAME=$(az containerapp list \
            --resource-group ${{ env.AZURE_RESOURCE_GROUP }} \
            --query "[?contains(name, '${{ matrix.service }}-staging')].name" -o tsv)
          
          IDENTITY_CLIENT_ID=$(az containerapp show \
            --name "$APP_NAME" \
            --resource-group ${{ env.AZURE_RESOURCE_GROUP }} \
            --query "identity.userAssignedIdentities" -o json | jq -r 'to_entries[0].value.clientId')
          
          echo "client_id=$IDENTITY_CLIENT_ID" >> "$GITHUB_OUTPUT"

      - name: Deploy to staging
        if: needs.changes.outputs[matrix.service] == 'true'
        run: |
          SERVICE_NAME=${{ matrix.service }}
          IMAGE_TAG="${{ env.REGISTRY }}.azurecr.io/${SERVICE_NAME}:${{ github.sha }}"
          
          # Get Cosmos DB endpoint
          COSMOS_ENDPOINT=$(az cosmosdb list \
            --resource-group ${{ env.AZURE_RESOURCE_GROUP }} \
            --query "[0].documentEndpoint" -o tsv)
          
          az containerapp update \
            --name ${SERVICE_NAME}-staging \
            --resource-group ${{ env.AZURE_RESOURCE_GROUP }} \
            --image ${IMAGE_TAG} \
            --revision-suffix ${{ github.run_number }} \
            --set-env-vars \
              AZURE_CLIENT_ID="${{ steps.identity.outputs.client_id }}" \
              COSMOS_ENDPOINT="$COSMOS_ENDPOINT"
      
      - name: Run health check
        if: needs.changes.outputs[matrix.service] == 'true'
        run: |
          SERVICE_URL="https://${{ matrix.service }}-staging.azurecontainerapps.io"
          
          # Wait for deployment to be ready
          sleep 30
          
          # Check health endpoint
          response=$(curl -s -o /dev/null -w "%{http_code}" ${SERVICE_URL}/health)
          if [ $response != "200" ]; then
            echo "Health check failed with status $response"
            exit 1
          fi

  deploy-production:
    runs-on: ubuntu-latest
    needs: [deploy-staging]
    if: github.event_name == 'workflow_dispatch' && github.event.inputs.environment == 'production'
    environment: production
    strategy:
      matrix:
        service: [pet-service, activity-service, accessory-service]
    steps:
      - uses: actions/checkout@v4
        if: needs.changes.outputs[matrix.service] == 'true'
      
      - name: Azure Login
        if: needs.changes.outputs[matrix.service] == 'true'
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Get managed identity
        if: needs.changes.outputs[matrix.service] == 'true'
        id: identity
        run: |
          APP_NAME=$(az containerapp list \
            --resource-group ${{ env.AZURE_RESOURCE_GROUP }} \
            --query "[?contains(name, '${{ matrix.service }}')].name" -o tsv | head -1)
          
          IDENTITY_CLIENT_ID=$(az containerapp show \
            --name "$APP_NAME" \
            --resource-group ${{ env.AZURE_RESOURCE_GROUP }} \
            --query "identity.userAssignedIdentities" -o json | jq -r 'to_entries[0].value.clientId')
          
          echo "client_id=$IDENTITY_CLIENT_ID" >> "$GITHUB_OUTPUT"

      - name: Blue-Green Deployment
        if: needs.changes.outputs[matrix.service] == 'true'
        run: |
          SERVICE_NAME=${{ matrix.service }}
          IMAGE_TAG="${{ env.REGISTRY }}.azurecr.io/${SERVICE_NAME}:${{ github.sha }}"
          
          # Get Cosmos DB endpoint
          COSMOS_ENDPOINT=$(az cosmosdb list \
            --resource-group ${{ env.AZURE_RESOURCE_GROUP }} \
            --query "[0].documentEndpoint" -o tsv)
          
          # Create new revision (green)
          az containerapp update \
            --name ${SERVICE_NAME} \
            --resource-group ${{ env.AZURE_RESOURCE_GROUP }} \
            --image ${IMAGE_TAG} \
            --revision-suffix green-${{ github.run_number }} \
            --set-env-vars \
              AZURE_CLIENT_ID="${{ steps.identity.outputs.client_id }}" \
              COSMOS_ENDPOINT="$COSMOS_ENDPOINT"
          
          # Health check on new revision
          sleep 60
          
          SERVICE_URL="https://${SERVICE_NAME}.azurecontainerapps.io"
          response=$(curl -s -o /dev/null -w "%{http_code}" ${SERVICE_URL}/health)
          
          if [ $response == "200" ]; then
            echo "Health check passed, switching traffic"
            
            # Switch 100% traffic to new revision
            az containerapp revision set-mode \
              --name ${SERVICE_NAME} \
              --resource-group ${{ env.AZURE_RESOURCE_GROUP }} \
              --mode Single
          else
            echo "Health check failed, rolling back"
            exit 1
          fi
```

### Step 2: Advanced Pipeline Features

#### Reusable Workflow for Service Deployment

Create `.github/workflows/deploy-service.yml`:

```yaml
name: Deploy Service

on:
  workflow_call:
    inputs:
      service-name:
        required: true
        type: string
      environment:
        required: true
        type: string
      image-tag:
        required: true
        type: string
    secrets:
      AZURE_CLIENT_ID:
        required: true
      AZURE_TENANT_ID:
        required: true
      AZURE_SUBSCRIPTION_ID:
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    steps:
      - name: Azure Login
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Deploy Container App
        run: |
          az containerapp update \
            --name ${{ inputs.service-name }}-${{ inputs.environment }} \
            --resource-group ${{ vars.RESOURCE_GROUP_NAME }} \
            --image ${{ inputs.image-tag }} \
            --revision-suffix $(date +%Y%m%d-%H%M%S)
      
      - name: Health Check
        run: |
          SERVICE_URL="https://${{ inputs.service-name }}-${{ inputs.environment }}.azurecontainerapps.io"
          
          # Wait for deployment
          sleep 30
          
          # Retry health check up to 5 times
          for i in {1..5}; do
            response=$(curl -s -o /dev/null -w "%{http_code}" ${SERVICE_URL}/health)
            if [ $response == "200" ]; then
              echo "Health check passed"
              exit 0
            fi
            echo "Health check failed, attempt $i/5"
            sleep 10
          done
          
          echo "Health check failed after 5 attempts"
          exit 1
```

#### Custom Composite Action for Service Testing

Create `.github/actions/test-service/action.yml`:

```yaml
name: 'Test Microservice'
description: 'Run comprehensive tests for a microservice'

inputs:
  service-path:
    description: 'Path to the service directory'
    required: true
  python-version:
    description: 'Python version to use'
    required: false
    default: '3.11'

outputs:
  coverage:
    description: 'Test coverage percentage'
    value: ${{ steps.test.outputs.coverage }}

runs:
  using: 'composite'
  steps:
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ inputs.python-version }}
        cache: 'pip'
    
    - name: Install dependencies
      shell: bash
      run: |
        cd ${{ inputs.service-path }}
        pip install -r requirements.txt
        pip install -r requirements-dev.txt
    
    - name: Run linting
      shell: bash
      run: |
        cd ${{ inputs.service-path }}
        flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
        flake8 . --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics
    
    - name: Run type checking
      shell: bash
      run: |
        cd ${{ inputs.service-path }}
        mypy . --ignore-missing-imports
    
    - name: Run security scan
      shell: bash
      run: |
        cd ${{ inputs.service-path }}
        bandit -r . -f json -o security-report.json || true
    
    - name: Run tests
      id: test
      shell: bash
      run: |
        cd ${{ inputs.service-path }}
        coverage run -m pytest tests/ -v --junitxml=test-results.xml
        coverage report --format=markdown > coverage-report.md
        coverage xml
        
        # Extract coverage percentage
        COVERAGE=$(coverage report --format=total)
        echo "coverage=$COVERAGE" >> $GITHUB_OUTPUT
    
    - name: Upload test results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: test-results-${{ github.run_id }}
        path: |
          ${{ inputs.service-path }}/test-results.xml
          ${{ inputs.service-path }}/coverage.xml
          ${{ inputs.service-path }}/coverage-report.md
          ${{ inputs.service-path }}/security-report.json
```

### Step 3: Environment Management and Approval Workflows

#### Environment Protection Rules Configuration

```yaml
# .github/environments/staging.yml
name: staging
deployment_branch_policy:
  protected_branches: true
  custom_branch_policies: false

# .github/environments/production.yml  
name: production
deployment_branch_policy:
  protected_branches: true
  custom_branch_policies: false
protection_rules:
  - type: required_reviewers
    required_reviewers:
      - deployment-team
      - security-team
  - type: wait_timer
    wait_timer: 5 # minutes
```

#### Canary Deployment Workflow

Create `.github/workflows/canary-deployment.yml`:

```yaml
name: Canary Deployment

on:
  workflow_dispatch:
    inputs:
      service:
        description: 'Service to deploy'
        required: true
        type: choice
        options:
          - pet-service
          - activity-service  
          - accessory-service
      traffic-percentage:
        description: 'Percentage of traffic for canary'
        required: true
        default: '10'

jobs:
  canary-deploy:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Deploy Canary
        run: |
          SERVICE_NAME=${{ github.event.inputs.service }}
          TRAFFIC_PERCENT=${{ github.event.inputs.traffic-percentage }}
          IMAGE_TAG="${{ vars.ACR_NAME }}.azurecr.io/${SERVICE_NAME}:${{ github.sha }}"
          
          # Create canary revision
          az containerapp update \
            --name ${SERVICE_NAME} \
            --resource-group ${{ vars.RESOURCE_GROUP_NAME }} \
            --image ${IMAGE_TAG} \
            --revision-suffix canary-${{ github.run_number }}
          
          # Get revision name
          CANARY_REVISION=$(az containerapp revision list \
            --name ${SERVICE_NAME} \
            --resource-group ${{ vars.RESOURCE_GROUP_NAME }} \
            --query "[?ends_with(name, 'canary-${{ github.run_number }}')].name" \
            --output tsv)
          
          # Split traffic
          az containerapp ingress traffic set \
            --name ${SERVICE_NAME} \
            --resource-group ${{ vars.RESOURCE_GROUP_NAME }} \
            --revision-weight ${CANARY_REVISION}=${TRAFFIC_PERCENT}
      
      - name: Monitor Canary
        run: |
          echo "Canary deployment created. Monitor metrics and promote manually if successful."
          echo "Use the following command to promote to 100%:"
          echo "az containerapp ingress traffic set --name ${{ github.event.inputs.service }} --resource-group ${{ vars.RESOURCE_GROUP_NAME }} --revision-weight ${CANARY_REVISION}=100"
```

### Step 4: Monitoring and Observability Integration

#### Deployment Notifications

```yaml
  notify-deployment:
    runs-on: ubuntu-latest
    needs: [deploy-production]
    if: always()
    steps:
      - name: Notify Teams
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          channel: '#deployments'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
      
      - name: Create Deployment Annotation
        run: |
          # Create annotation in Application Insights
          curl -X POST "https://api.applicationinsights.io/v1/apps/${{ secrets.APP_INSIGHTS_ID }}/annotations" \
            -H "X-API-Key: ${{ secrets.APP_INSIGHTS_API_KEY }}" \
            -H "Content-Type: application/json" \
            -d '{
              "AnnotationName": "Deployment",
              "EventTime": "'$(date -u +%Y-%m-%dT%H:%M:%S.000Z)'",
              "Properties": {
                "Category": "Deployment",
                "Environment": "production",
                "Version": "${{ github.sha }}",
                "Services": "${{ toJSON(matrix.service) }}"
              }
            }'
```

## Best Practices Implementation

### Authentication Architecture

**Cosmos DB Access via Managed Identity:**
- Each Container App has a **user-assigned managed identity**
- Bicep infrastructure grants **Cosmos DB Data Contributor** role to each identity
- Backend services detect Azure environment and use `DefaultAzureCredential()`
- Local development still uses `COSMOS_KEY` from `.env` file (detected via localhost endpoint)
- **Zero secrets** in Container App configuration for database access

### 1. Security Best Practices

```yaml
# Security scanning job
security-checks:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    
    - name: Container Security Scan
      uses: anchore/scan-action@v3
      with:
        image: ${{ env.REGISTRY }}.azurecr.io/${{ matrix.service }}:${{ github.sha }}
        fail-build: true
        severity-cutoff: high
    
    - name: Infrastructure Security Scan
      uses: bridgecrewio/checkov-action@master
      with:
        directory: .
        framework: terraform,bicep
        output_format: sarif
        output_file_path: checkov-results.sarif
    
    - name: Upload Security Results
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: checkov-results.sarif

# Validate Managed Identity RBAC configuration
    - name: Verify Cosmos DB RBAC
      run: |
        # Check that Container Apps have Cosmos DB Data Contributor role
        for service in pet-service activity-service accessory-service; do
          echo "Checking RBAC for $service..."
          az role assignment list \
            --scope $COSMOS_ACCOUNT_ID \
            --query "[?principalType=='ServicePrincipal' && contains(roleDefinitionName, 'Cosmos DB Data Contributor')]" \
            -o table
        done
```

### 2. Performance and Efficiency

```yaml
# Caching strategy for improved performance
- name: Cache Docker layers
  uses: actions/cache@v3
  with:
    path: /tmp/.buildx-cache
    key: ${{ runner.os }}-buildx-${{ github.sha }}
    restore-keys: |
      ${{ runner.os }}-buildx-

# Parallel execution for multiple services
strategy:
  matrix:
    service: [pet-service, activity-service, accessory-service]
  max-parallel: 3
```

### 3. Error Handling and Rollback

```yaml
- name: Deploy with Rollback Capability
  run: |
    SERVICE_NAME=${{ matrix.service }}
    
    # Store current active revision for rollback
    CURRENT_REVISION=$(az containerapp revision list \
      --name ${SERVICE_NAME} \
      --resource-group ${{ env.AZURE_RESOURCE_GROUP }} \
      --query "[?properties.active].name" \
      --output tsv)
    
    echo "ROLLBACK_REVISION=${CURRENT_REVISION}" >> $GITHUB_ENV
    
    # Deploy new revision
    az containerapp update \
      --name ${SERVICE_NAME} \
      --resource-group ${{ env.AZURE_RESOURCE_GROUP }} \
      --image ${{ env.REGISTRY }}.azurecr.io/${SERVICE_NAME}:${{ github.sha }}

- name: Rollback on Failure
  if: failure()
  run: |
    echo "Deployment failed, rolling back to ${ROLLBACK_REVISION}"
    az containerapp revision activate \
      --name ${{ matrix.service }} \
      --resource-group ${{ env.AZURE_RESOURCE_GROUP }} \
      --revision ${ROLLBACK_REVISION}
```

## Success Validation

### Authentication Verification

**Validate Managed Identity is Working:**
```bash
# Check Container App managed identity
az containerapp show \
  --name petpal-pet-service \
  --resource-group $RESOURCE_GROUP \
  --query "identity.userAssignedIdentities" -o json

# Check AZURE_CLIENT_ID environment variable is set
az containerapp show \
  --name petpal-pet-service \
  --resource-group $RESOURCE_GROUP \
  --query "properties.template.containers[0].env[?name=='AZURE_CLIENT_ID']" -o json

# Verify Cosmos DB RBAC role assignments
COSMOS_ACCOUNT_ID=$(az cosmosdb show \
  --name $COSMOS_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP \
  --query id -o tsv)

# Check data plane role (Cosmos DB Data Contributor)
az cosmosdb sql role assignment list \
  --account-name $COSMOS_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP \
  -o table

# Check ARM level role (DocumentDB Account Contributor)
az role assignment list \
  --scope $COSMOS_ACCOUNT_ID \
  --query "[?roleDefinitionName=='DocumentDB Account Contributor'].{Principal:principalId,Role:roleDefinitionName}" \
  -o table
```

**Test Cosmos DB Access:**
```bash
# Services should return 200 OK (not 503)
curl https://petpal-pet-service.azurecontainerapps.io/health
# Expected: {"status":"healthy","cosmos_db":"connected"}
```

### Metrics to Track
- **Build Success Rate**: Percentage of successful builds
- **Deployment Frequency**: How often deployments occur
- **Lead Time**: Time from commit to production
- **Mean Time to Recovery (MTTR)**: Time to recover from failures
- **Change Failure Rate**: Percentage of deployments causing failures

### Monitoring Dashboard
Create monitoring queries to track pipeline effectiveness:

```kusto
// Deployment frequency
customEvents
| where name == "Deployment"
| summarize DeploymentsPerDay = count() by bin(timestamp, 1d)
| render timechart

// Failure rate
customEvents
| where name == "Deployment"
| summarize 
    Total = count(),
    Failed = countif(customDimensions.status == "failed")
| extend FailureRate = (Failed * 100.0) / Total
```

## Common Issues and Solutions

### Issue 1: Cosmos DB Authentication Failures

**Symptoms:**
- Health check returns 503 or authentication errors
- Logs show "Unauthorized" or "Forbidden" errors accessing Cosmos DB
- Error: "Unable to load the proper Managed Identity"

**Solutions:**
- **Verify AZURE_CLIENT_ID is set**: Check Container App environment variables include `AZURE_CLIENT_ID`
- **Verify RBAC role assignments exist**: 
  - Data plane: `az cosmosdb sql role assignment list`
  - ARM level: `az role assignment list --scope $COSMOS_ACCOUNT_ID`
- Wait 5-10 minutes for role propagation after infrastructure deployment
- Check Container App has user-assigned managed identity configured
- Verify backend code uses `DefaultAzureCredential()` when not on localhost
- Ensure workflows dynamically retrieve and set AZURE_CLIENT_ID during deployment
- Check Application Insights for detailed error messages

### Issue 2: Long Build Times
**Solutions**:
- Implement Docker layer caching
- Use parallel job execution
- Optimize Dockerfile with multi-stage builds
- Cache dependencies between runs

### Issue 3: Flaky Tests
**Solutions**:
- Implement test retry mechanisms
- Use test containers for consistent environments
- Add proper wait conditions and timeouts
- Separate unit tests from integration tests

### Issue 4: Deployment Rollback Complexity
**Solutions**:
- Implement automated rollback triggers
- Use blue-green or canary deployment strategies
- Maintain deployment state and history
- Create clear rollback procedures and documentation

## Next Steps

- Proceed to [Challenge 10: DevSecOps and Governance](/challenges/challenge-10/README.md)
- Implement advanced monitoring and alerting
- Optimize pipeline performance and efficiency
- Create comprehensive deployment documentation

## Additional Resources

- [Azure Cosmos DB RBAC Documentation](https://learn.microsoft.com/azure/cosmos-db/how-to-setup-rbac)
- [Container Apps Managed Identity](https://learn.microsoft.com/azure/container-apps/managed-identity)
- [DefaultAzureCredential Best Practices](https://learn.microsoft.com/python/api/overview/azure/identity-readme)
- [Cosmos DB Authentication Migration Guide](/backend/COSMOS_AUTH_MIGRATION.md)
- [Infrastructure RBAC Migration Summary](/infra/RBAC_MIGRATION_COMPLETE.md)

---

**Key Takeaways**:
- **Managed Identity eliminates secret management** for Azure service-to-service authentication
- Automated pipelines reduce manual errors and increase deployment frequency
- Environment protection rules provide necessary governance and safety
- Monitoring and observability are essential for production deployments
- Rollback capabilities are critical for maintaining system reliability
- Security scanning should be integrated throughout the pipeline
- **RBAC provides fine-grained access control** without exposing master keys