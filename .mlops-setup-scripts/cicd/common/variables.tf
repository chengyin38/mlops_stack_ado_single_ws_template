variable "git_token" {
  type        = string
  description = "Git token used to (1) checkout ML code to run during CI and (2) call back from Databricks -> GitHub Actions to trigger a model deployment CD workflow when automated model retraining completes. Must have read and write permissions on the Git repo containing the current ML project"
  sensitive   = true
}

variable "git_provider" {
  type        = string
  description = "Hosted Git provider, as described in https://learn.microsoft.com/azure/databricks/dev-tools/api/latest/gitcredentials#operation/create-git-credential. For example, 'gitHub' if using GitHub, or 'azureDevOpsServices' if using Azure DevOps."
}

