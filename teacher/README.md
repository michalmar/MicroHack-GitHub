# Teacher guide

1. Register providers in subscription using `register_providers.ps1`

2. Go to `terraform` folder and modify `sub1.tfvars` to fit your environment, namely your Entra domain suffix, password for created users (they will be forced to enroll for MFA after first login), Entra group for all users and your subscription ID.

3. Apply to create all users, resource groups in subscription, RBAC

```terraform
cd teacher/terraform
terraform init
terraform apply -var-file sub1.tfvars
```

4. Create GitHub Enterprise with Enterprise Managed Users, OIDC and user synchronization for our users.

5. Enable billing from Azure. Enable Copilot Enterprise (so users can access Spark), enable Spark, enable all models.

6. Create Organization, create Team based on our Entra group and give access to Organization

7. Take student branch and use it to create "seed repo" in organization - template participants will start from.