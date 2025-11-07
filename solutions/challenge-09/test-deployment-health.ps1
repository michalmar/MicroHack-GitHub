#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Tests health endpoints of deployed PetPal microservices
    
.DESCRIPTION
    Validates that all three backend microservices are deployed and healthy
    by checking their /health endpoints. Tests connectivity, response time,
    and database connection status.
    
.PARAMETER ResourceGroup
    Azure resource group containing the Container Apps
    
.PARAMETER Detailed
    Show detailed response from each service
    
.EXAMPLE
    ./test-deployment-health.ps1 -ResourceGroup "rg-petpal-dev"
    
.EXAMPLE
    ./test-deployment-health.ps1 -ResourceGroup "rg-petpal-dev" -Detailed
    
.NOTES
    Requires: Azure CLI installed and authenticated
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup = $env:RESOURCE_GROUP,
    
    [Parameter(Mandatory = $false)]
    [switch]$Detailed
)

# Configuration
$Services = @(
    @{
        Name        = "pet-service"
        Port        = 8010
        ExpectedDB  = "petservice"
        Description = "Pet Management Service"
    },
    @{
        Name        = "activity-service"
        Port        = 8020
        ExpectedDB  = "activityservice"
        Description = "Activity Tracking Service"
    },
    @{
        Name        = "accessory-service"
        Port        = 8030
        ExpectedDB  = "accessoryservice"
        Description = "Accessory Management Service"
    }
)

# Color output helpers
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Failure { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }

# Main execution
Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   PetPal Microservices Deployment Health Check           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Validate resource group
if ([string]::IsNullOrEmpty($ResourceGroup)) {
    Write-Failure "Resource group not specified. Use -ResourceGroup parameter or set RESOURCE_GROUP environment variable."
    exit 1
}

Write-Info "Testing services in resource group: $ResourceGroup`n"

# Check Azure CLI authentication
Write-Host "Checking Azure CLI authentication..." -ForegroundColor Gray
try {
    $null = az account show 2>$null
    Write-Success "Azure CLI authenticated"
} catch {
    Write-Failure "Azure CLI not authenticated. Run: az login"
    exit 1
}

# Results tracking
$results = @()
$allHealthy = $true

# Test each service
foreach ($service in $Services) {
    Write-Host "`n───────────────────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host "Testing: $($service.Description)" -ForegroundColor Yellow
    Write-Host "───────────────────────────────────────────────────────────`n" -ForegroundColor Gray
    
    # Get Container App FQDN
    Write-Host "  Looking up service URL..." -ForegroundColor Gray
    $appName = (az containerapp list `
        --resource-group $ResourceGroup `
        --query "[?contains(name, '$($service.Name)')].name" `
        -o tsv)
    
    if ([string]::IsNullOrEmpty($appName)) {
        Write-Failure "Service not found in resource group"
        $results += @{
            Service = $service.Name
            Status  = "NOT_FOUND"
            URL     = "N/A"
            Healthy = $false
        }
        $allHealthy = $false
        continue
    }
    
    $fqdn = (az containerapp show `
        --name $appName `
        --resource-group $ResourceGroup `
        --query "properties.configuration.ingress.fqdn" `
        -o tsv)
    
    if ([string]::IsNullOrEmpty($fqdn)) {
        Write-Failure "Could not retrieve service URL"
        $results += @{
            Service = $service.Name
            Status  = "NO_INGRESS"
            URL     = "N/A"
            Healthy = $false
        }
        $allHealthy = $false
        continue
    }
    
    $healthUrl = "https://$fqdn/health"
    Write-Info "Service URL: $healthUrl"
    
    # Test health endpoint
    Write-Host "  Testing /health endpoint..." -ForegroundColor Gray
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-RestMethod -Uri $healthUrl -Method Get -TimeoutSec 30 -ErrorAction Stop
        $stopwatch.Stop()
        $responseTime = $stopwatch.ElapsedMilliseconds
        
        # Validate response structure
        $isHealthy = $response.status -eq "healthy"
        $hasVersion = -not [string]::IsNullOrEmpty($response.version)
        $dbConnected = $response.database.status -eq "connected"
        
        if ($isHealthy -and $dbConnected) {
            Write-Success "Service is healthy (${responseTime}ms)"
            Write-Host "    • Version: $($response.version)" -ForegroundColor Gray
            Write-Host "    • Database: Connected to $($response.database.database)" -ForegroundColor Gray
            
            if ($Detailed) {
                Write-Host "`n    Full Response:" -ForegroundColor Gray
                $response | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor DarkGray
            }
            
            $results += @{
                Service      = $service.Name
                Status       = "HEALTHY"
                URL          = $healthUrl
                ResponseTime = $responseTime
                Version      = $response.version
                Database     = $response.database.database
                Healthy      = $true
            }
        }
        elseif (-not $isHealthy) {
            Write-Failure "Service status is not healthy: $($response.status)"
            $allHealthy = $false
            $results += @{
                Service = $service.Name
                Status  = $response.status
                URL     = $healthUrl
                Healthy = $false
            }
        }
        elseif (-not $dbConnected) {
            Write-Failure "Database connection failed: $($response.database.status)"
            $allHealthy = $false
            $results += @{
                Service = $service.Name
                Status  = "DB_ERROR"
                URL     = $healthUrl
                Healthy = $false
            }
        }
    }
    catch {
        Write-Failure "Health check failed: $($_.Exception.Message)"
        $allHealthy = $false
        $results += @{
            Service = $service.Name
            Status  = "ERROR"
            URL     = $healthUrl
            Error   = $_.Exception.Message
            Healthy = $false
        }
    }
}

# Summary
Write-Host "`n`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    TEST SUMMARY                           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Display results table
$results | ForEach-Object {
    $icon = if ($_.Healthy) { "✅" } else { "❌" }
    $status = if ($_.Healthy) { "HEALTHY" } else { $_.Status }
    $time = if ($_.ResponseTime) { " (${_}.ResponseTime}ms)" } else { "" }
    
    Write-Host "  $icon $($_.Service.PadRight(20)) " -NoNewline
    if ($_.Healthy) {
        Write-Host "$status$time" -ForegroundColor Green
    } else {
        Write-Host "$status" -ForegroundColor Red
    }
}

Write-Host ""

# Overall result
if ($allHealthy) {
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Success "All services are healthy and operational!"
    Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Failure "One or more services failed health checks"
    Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Red
    
    Write-Info "Troubleshooting tips:"
    Write-Host "  1. Check Container App logs: az containerapp logs show --name <app-name> --resource-group $ResourceGroup --follow" -ForegroundColor Gray
    Write-Host "  2. Verify environment variables are set correctly" -ForegroundColor Gray
    Write-Host "  3. Ensure Cosmos DB credentials are valid" -ForegroundColor Gray
    Write-Host "  4. Check ingress configuration matches service port" -ForegroundColor Gray
    
    exit 1
}
