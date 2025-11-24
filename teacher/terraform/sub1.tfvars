# Example configuration file for Terraform variables

# Number of user environments to provision (adjust based on your workshop size)
n = 60

# Azure regions to distribute environments across (choose regions close to your participants)
locations = ["swedencentral", "germanywestcentral", "francecentral", "norwayeast"]

# Your Azure subscription ID
subscription_id = "6766574f-da48-496f-b65a-18d9e5f726a4"

# Entra details
entra_user_domain   = "github.microhack.org"
entra_user_password = "Azure12345678"
entra_user_group    = "microhack-users"

enable_test_deployment = false
