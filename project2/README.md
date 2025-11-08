Create a User Assigned Managed Identity or App Registration in Azure AD:
az ad app create --display-name "github-bicep-deployer"

When you created your App Registration (for GitHub Actions OIDC or SP-based auth), Azure does not automatically create a service principal

Create the Missing Service Principal
az ad sp create --id bb76283e-4795-477e-ba2e-436aaa34b59f

Assign Contributor access to your subscription or resource group:
az role assignment create \
  --assignee "bb76283e-4795-477e-ba2e-436aaa34b59f" \
  --role "Contributor" \
  --scope "/subscriptions/ed79d02d-bd46-4fa8-96bb-4fcddc112959/resourceGroups/aimsplus"

Add a Federated Credential between GitHub and Azure AD app:
Under Azure Portal → App Registrations → Certificates & Secrets → Federated Credentials
Configure it as:
Entity Type: Repository
Organization: <your GitHub org or username>
Repository: <repo name>
Branch: main
Name: github-actions

In GitHub → Settings → Secrets and Variables → Actions
Add:
    AZURE_CLIENT_ID
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID