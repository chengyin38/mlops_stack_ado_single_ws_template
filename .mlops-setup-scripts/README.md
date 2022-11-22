# MLOps Setup Scripts
[(back to MLOps setup guide)](../docs/mlops-setup.md)

This directory contains setup scripts intended to automate CI/CD and ML resource config setup
for MLOps engineers.

The scripts set up CI/CD with Azure DevOps. During initial set up we do the following:
1. Create an Azure Blob Storage container for storing ML resource config (job, MLflow experiment, etc) state for the
   current ML project
2. Create another Azure Blob Storage container for storing the state of CI/CD principals provisioned for the current
   ML project
3. Write credentials for accessing the container in (1) to a file
4. Create Databricks service principals configured for CI/CD, write their credentials to a file, and store their
   state in the Azure Blob Storage container created in (2).
5. Create two Azure DevOps Pipelines:
    * `testing_ci` - Unit tests and integration tests triggered upon PR to the main branch.
    * `terraform_cicd` - Continuous integration for Terraform triggered upon a PR to main and changes to `databricks-config`, 
                         followed by continuous deployment of changes upon successfully merging into main.
## Prerequisites

### Install CLIs
* Install the [Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli)
* Install the [Databricks CLI](https://github.com/databricks/databricks-cli): ``pip install databricks-cli``
* Install Azure CLI: ``pip install azure-cli``


### Verify permissions
To use the scripts, you must:
* Be a Databricks workspace admin in the staging and prod workspaces. Verify that you're an admin by viewing the
  [staging workspace admin console](https://adb-1352164841139608.8.azuredatabricks.net #setting/accounts) and
  [prod workspace admin console](https://adb-1352164841139608.8.azuredatabricks.net #setting/accounts). If
  the admin console UI loads instead of the Databricks workspace homepage, you are an admin.
* Be able to create Git tokens with permission to check out the current repository
* Determine the Azure AAD tenant (directory) ID and subscription associated with your staging and prod workspaces,
  and verify that you have at least [Application.ReadWrite.All](https://docs.microsoft.com/en-us/graph/permissions-reference#application-resource-permissions) permissions on
  the AAD tenant and ["Contributor" permissions](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#all) on
  the subscription. To do this:
    1. Navigate to the [Azure Databricks resource page](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.Databricks%2Fworkspaces) in the Azure portal. Ensure there are no filters configured in the UI, i.e. that
       you're viewing workspaces across all Subscriptions and Resource Groups.
    2. Search for your staging and prod workspaces by name to verify that they're part of the current directory. If you don't know the workspace names, you can log into the
       [staging workspace](https://adb-1352164841139608.8.azuredatabricks.net ) and [prod workspace](https://adb-1352164841139608.8.azuredatabricks.net ) and use the
       [workspace switcher](https://learn.microsoft.com/azure/databricks/workspace/#switch-to-a-different-workspace) to view
       the workspace name
    3. If you can't find the workspaces, switch to another directory by clicking your profile info in the top-right of the Azure Portal, then
       repeat steps i) and ii). If you still can't find the workspace, ask your Azure account admin to ensure that you have
       at least ["Contributor" permissions](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#all)
       on the subscription containing the workspaces. After confirming that the staging and prod workspaces are in the current directory, proceed to the next steps.
    4. The [Azure Databricks resource page](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.Databricks%2Fworkspaces)
       contains links to the subscription containing your staging and prod workspaces. Click into the subscription, copy its ID ("Subscription ID"), and
       store it as an environment variable by running `export AZURE_SUBSCRIPTION_ID=<subscription-id>`
    5. Verify that you have "Contributor" access by clicking into
       "Access Control (IAM)" > "View my access" within the subscription UI,
       as described in [this doc page](https://docs.microsoft.com/en-us/azure/role-based-access-control/check-access#step-1-open-the-azure-resources).
       If you don't have [Contributor permissions](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#all),
       ask an Azure account admin to grant access.
    6. Find the current tenant ID
       by navigating to [this page](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/Properties),
       also accessible by navigating to the [Azure Active Directory UI](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/Overview)
       and clicking Properties. Save the tenant ID as an environment variable by running `export AZURE_TENANT_ID=<id>`
    7. Verify that you can create and manage service principals in the AAD tenant, by opening the
       [App registrations UI](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps)
       under the Azure Active Directory resource within the Azure portal. Then, verify that you can click "New registration" to create
       a new AAD application, but don't actually create one. If unable to click "New registration", ask your Azure admin to grant you [Application.ReadWrite.All](https://docs.microsoft.com/en-us/graph/permissions-reference#application-resource-permissions) permissions
  

### Configure Azure auth
* Log into Azure via `az login --tenant "$AZURE_TENANT_ID"`
* Run `az account set --subscription "$AZURE_SUBSCRIPTION_ID"` to set the active Azure subscription


### Configure Databricks auth
* Configure a Databricks CLI profile for your staging workspace by running
  ``databricks configure --token --profile "mlops_stack_ado-staging" --host https://adb-1352164841139608.8.azuredatabricks.net ``, 
  which will prompt you for a REST API token
* Create a [Databricks REST API token](https://learn.microsoft.com/azure/databricks/dev-tools/api/latest/authentication#generate-a-personal-access-token)
  in the staging workspace ([link](https://adb-1352164841139608.8.azuredatabricks.net #setting/account))
  and paste the value into the prompt.
* Configure a Databricks CLI for your prod workspace by running ``databricks configure --token --profile "mlops_stack_ado-prod" --host https://adb-1352164841139608.8.azuredatabricks.net ``
* Create a Databricks REST API token in the prod workspace ([link](https://adb-1352164841139608.8.azuredatabricks.net #setting/account)).
  and paste the value into the prompt

### Obtain a git token for use in CI/CD
The setup script prompts a Git token with both read and write permissions
on the current repo.

This token is used to fetch ML code from the current repo to run on Databricks for CI/CD (e.g. to check out code from a PR branch and run it
during CI/CD). You can generate a PAT token for Azure DevOps by following the steps described [here](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=Windows).

### Grant version control permissions to CI/CD
The provided CI/CD workflows attempt to run `git` commands to commit and modify files. To ensure the workflows can work properly, [grant version control permissions](https://learn.microsoft.com/en-us/azure/devops/pipelines/scripts/git-commands?view=azure-devops&tabs=yaml#grant-version-control-permissions-to-the-build-service) within your hosted Azure DevOps repo.
The user `mlops_stack_ado Build Service (<your-username>)` should be granted the following:
- **Create branch:** Allow
- **Contribute:** Allow
- **Read:** Allow
- **Create tag:** Allow
## Usage

### Run the scripts
From the repo root directory, run:

```
python .mlops-setup-scripts/terraform/bootstrap.py
```
This initial bootstrap will produce an ARM access key. This key is required as a variable in the next step. To view this
key locally and copy the key for this step you can do the following `vi ~/.mlops_stack_ado-cicd-terraform-secrets.json`.
Then, run the following command, providing the required vars to bootstrap CI/CD.
```
python .mlops-setup-scripts/cicd/bootstrap.py \
  --var azure_tenant_id="$AZURE_TENANT_ID" \
  --var azure_devops_org_url=https://dev.azure.com/<your-org-name> \
  --var azure_devops_project_name=<name-of-project> \
  --var azure_devops_repo_name=<name-of-repo> \
  --var git_token=<your-git-token> \
  --var arm_access_key=<arm-access-key>
```

Take care to run the Terraform bootstrap script before the CI/CD bootstrap script. This will:


1. Create an Azure Blob Storage container for storing ML resource config (job, MLflow experiment, etc) state for the
   current ML project
2. Create another Azure Blob Storage container for storing the state of CI/CD principals provisioned for the current
   ML project
3. Write credentials for accessing the container in (1) to a file
4. Create Databricks service principals configured for CI/CD, write their credentials to a file, and store their
   state in the Azure Blob Storage container created in (2).

5. Create two Azure DevOps Pipelines:
    * `testing_ci` - Unit tests and integration tests triggered upon PR to the main branch.
    * `terraform_cicd` - Continuous integration for Terraform triggered upon a PR to main and changes to `databricks-config`, 
                         followed by continuous deployment of changes upon successfully merging into main.



Each `bootstrap.py` script will print out the path to a JSON file containing generated secret values
to store for CI/CD. **Note the paths of these secrets files for subsequent steps.** If either script
fails or the generated resources are misconfigured (e.g. you supplied invalid Git credentials for CI/CD
service principals when prompted), simply rerun and supply updated input values.




### Add Azure DevOps pipelines to hosted Git repo
Create and push a PR branch adding the Azure DevOps Pipelines under `.azure`:

```
git checkout -b add-cicd-workflows
git add .azure
git commit -m "Add CI/CD workflows"
git push upstream add-cicd-workflows
```

Follow [Azure DevOps docs](https://learn.microsoft.com/en-us/azure/devops/pipelines/get-started/what-is-azure-pipelines?view=azure-devops) 
to learn how to create an Azure DevOps build pipeline. Then, open and merge a pull request based on your PR branch to add the CI/CD workflows to your hosted Git Repo.


Note that the CI/CD workflows will fail
until ML code is introduced to the repo in subsequent steps - you should
merge the pull request anyways.

After the pull request merges, pull the changes back into your local `main`
branch:

```
git checkout main
git pull upstream main
```


Finally, [create environments](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/environments?view=azure-devops)
in your repo named "staging" and "prod"


### Secret rotation
The generated CI/CD
Azure application client secrets have an expiry of [2 years](https://github.com/databricks/terraform-databricks-mlops-azure-project-with-sp-creation#outputs)
and will need to be rotated thereafter. To rotate CI/CD secrets after expiry, simply rerun `python .mlops-setup-scripts/cicd/bootstrap.py`
with updated inputs, after configuring auth as described in the prerequisites.

## Next steps
In this project, interactions with the staging and prod workspace are driven through CI/CD. After you've configured
CI/CD and ML resource state storage, you can productionize your ML project by testing and deploying ML code, deploying model training and
inference jobs, and more. See the [MLOps setup guide](../docs/mlops-setup.md) for details.
