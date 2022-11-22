terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 0.5.8"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.15.0"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">= 0.2.1"
    }
    azurerm = { 
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
  }
  // The `backend` block below configures the azurerm backend
  // (docs:
  // https://www.terraform.io/language/settings/backends/azurerm and
  // https://docs.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage)
  // for storing Terraform state in Azure Blob Storage. The targeted Azure Blob Storage bucket is
  // provisioned by the Terraform config under .mlops-setup-scripts/terraform:
  //
  backend "azurerm" {
    resource_group_name  = "cy_mlopsstackado"
    storage_account_name = "cymlopsstackado"
    container_name       = "cicd-setup-tfstate"
    key                  = "cicd-setup.terraform.tfstate"
  }

}

provider "databricks" {
  alias   = "staging"
  profile = var.staging_profile
}

provider "databricks" {
  alias   = "prod"
  profile = var.prod_profile
}

provider "azuread" {}

// Additional providers for Azure DevOps
provider "azuredevops" {
  org_service_url       = var.azure_devops_org_url
  personal_access_token = var.git_token
}

provider "azurerm" {
  features {
  }
}
