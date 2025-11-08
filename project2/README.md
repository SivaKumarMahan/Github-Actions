1. Create an App Registration in Azure AD:
az ad app create --display-name "github-bicep-deployer"

2. When you created your App Registration (for GitHub Actions OIDC or SP-based auth), Azure does not automatically create a service principal
Create the Missing Service Principal
az ad sp create --id bb76283e-4795-477e-ba2e-436aaa34b59f

3. Assign Contributor access to your resource group:
az role assignment create \
  --assignee "bb76283e-4795-477e-ba2e-436aaa34b59f" \
  --role "Contributor" \
  --scope "/subscriptions/ed79d02d-bd46-4fa8-96bb-4fcddc112959/resourceGroups/aimsplus"

4. Add a Federated Credential between GitHub and Azure AD app:
Under Azure Portal → App Registrations → Certificates & Secrets → Federated Credentials
Configure it as:
Federated Credential Scenario: Github Actions deploying Azure Resources
- Organization: <your GitHub org or username>
- Repository: <repo name>
- Entity Type: branch
- Branch: main
- Name: github-actions

5. In GitHub → Settings → Secrets and Variables → Actions
Add:
   - AZURE_CLIENT_ID
   - AZURE_TENANT_ID
   - AZURE_SUBSCRIPTION_ID