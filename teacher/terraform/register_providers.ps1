# Register required Azure Resource Providers
# Run this script once per subscription before deploying Terraform

$providers = @(
    "Microsoft.App",
    "Microsoft.OperationalInsights",
    "Microsoft.ContainerRegistry",
    "Microsoft.DocumentDB",
    "Microsoft.ManagedIdentity"
)

foreach ($provider in $providers) {
    Write-Host "Registering provider: $provider"
    az provider register --namespace $provider
}

Write-Host "Waiting for registration to complete..."
foreach ($provider in $providers) {
    do {
        $status = az provider show --namespace $provider --query "registrationState" -o tsv
        Write-Host "$provider status: $status"
        if ($status -ne "Registered") {
            Start-Sleep -Seconds 5
        }
    } until ($status -eq "Registered")
}

Write-Host "All providers registered successfully."
