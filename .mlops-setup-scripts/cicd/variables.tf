variable "git_token" {
  type        = string
  description = "Azure DevOps personal access token (PAT) used by the created service principal to create Azure DevOps Pipelines and checkout ML code to run during CI/CD. PAT must have read, write and manage permissions for Build and Code scopes on the Azure DevOps project. See the following on how to create and use PATs (https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=Windows)"
  sensitive   = true
  validation {
    condition     = length(var.git_token) > 0
    error_message = "The git_token variable cannot be empty"
  }
}

variable "git_provider" {
  type        = string
  description = "Hosted Git provider, as described in https://learn.microsoft.com/azure/databricks/dev-tools/api/latest/gitcredentials#operation/create-git-credential. For example, 'gitHub' if using GitHub."
  default     = "azureDevOpsServices"
}

variable "staging_profile" {
  type        = string
  description = "Name of Databricks CLI profile on the current machine configured to run against the staging workspace"
  default     = "mlops_stack_ado-staging"
}

variable "prod_profile" {
  type        = string
  description = "Name of Databricks CLI profile on the current machine configured to run against the prod workspace"
  default     = "mlops_stack_ado-prod"
}

variable "azure_tenant_id" {
  type        = string
  description = "Azure tenant (directory) ID under which to create Service Principals for CI/CD. This should be the same Azure tenant as the one containing your Azure Databricks workspaces"
  validation {
    condition     = length(var.azure_tenant_id) > 0
    error_message = "The azure_tenant_id variable cannot be empty"
  }
}

variable "azure_devops_org_url" {
  type        = string
  description = "Azure DevOps organization URL. Should be in the form https://dev.azure.com/<organization_name>"
}

variable "azure_devops_project_name" {
  type        = string
  description = "Project name in Azure DevOps."
}

variable "azure_devops_repo_name" {
  type        = string
  description = "Repository name in Azure DevOps."
}

variable "arm_access_key" {
  type        = string
  description = "Azure resource manager key produced when initially bootstrapping Terraform. View this token by running $ vi ~/.mlops_stack_ado-cicd-terraform-secrets.json"
  sensitive   = true
}

variable "azure_devops_project_id" {
  type        = string
  description = "Project ID in Azure DevOps."
}
