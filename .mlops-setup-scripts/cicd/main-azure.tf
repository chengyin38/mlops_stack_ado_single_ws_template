resource "databricks_group" "staging_mlops_service_principals" {
  display_name = "staging-mlops-stack-ado-single-workspace-service-principals"
  provider     = databricks.staging
}

resource "databricks_group" "prod_mlops_service_principals" {
  display_name = "prod-mlops-stack-ado-single-workspace-service-principals"
  provider     = databricks.prod
}

// Additional steps to set up in single workspace
module "create_staging_sp" {
  source     = "./modules/azure-create-service-principal"
  providers = {
    databricks         = databricks.staging
    azuread            = azuread
  }
  service_principal_name       = "staging-mlops-stack-ado-single-workspace"
  group_id                     = databricks_group.staging_mlops_service_principals.id
  azure_tenant_id              = var.azure_tenant_id
}

module "create_prod_sp" {
  source     = "./modules/azure-create-service-principal"
  providers = {
    databricks         = databricks.prod
    azuread            = azuread
  }
  service_principal_name       = "prod-mlops-stack-ado-single-workspace"
  group_id                   = databricks_group.prod_mlops_service_principals.id
  azure_tenant_id              = var.azure_tenant_id
}

resource "databricks_directory" "staging_directory" {
  provider = databricks.staging
  path     = "/Shared/mlops-stack-ado-single-workspace/staging"
}

resource "databricks_permissions" "staging_directory_usage" {
  provider       = databricks.staging
  directory_path = databricks_directory.staging_directory.path

  access_control {
    service_principal_name = module.create_staging_sp.service_principal_application_id
    permission_level       = "CAN_MANAGE"
  }
}

resource "databricks_directory" "prod_directory" {
  provider = databricks.prod
  path     = "/Shared/mlops-stack-ado-single-workspace/prod"
}

resource "databricks_permissions" "prod_directory_usage" {
  provider       = databricks.prod
  directory_path = databricks_directory.prod_directory.path

  access_control {
    service_principal_name = module.create_prod_sp.service_principal_application_id
    permission_level       = "CAN_MANAGE"
  }
}
// End of additional for single workspace

data "databricks_current_user" "staging_user" {
  provider = databricks.staging
}

provider "databricks" {
  alias = "staging_sp"
  host  = "https://adb-1352164841139608.8.azuredatabricks.net"
  token =  module.create_staging_sp.service_principal_aad_token
}

provider "databricks" {
  alias = "prod_sp"
  host  = "https://adb-1352164841139608.8.azuredatabricks.net"
  token =  module.create_prod_sp.service_principal_aad_token
}

module "staging_workspace_cicd" {
  source = "./common"
  providers = {
    databricks = databricks.staging_sp
  }
  git_provider = var.git_provider
  git_token    = var.git_token
}

module "prod_workspace_cicd" {
  source = "./common"
  providers = {
    databricks = databricks.prod_sp
  }
  git_provider = var.git_provider
  git_token    = var.git_token
}

// Additional steps for Azure DevOps. Create staging and prod service principals for an enterprise application.
data "azuread_client_config" "current" {}

resource "azuread_application" "mlops_stack_ado-aad" {
  display_name = "mlops_stack_ado"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "staging_service_principal" {
  application_id               = module.create_staging_sp.service_principal_application_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
    feature_tags {
      enterprise = true
      gallery    = true
    }
}

resource "azuread_service_principal" "prod_service_principal" {
  application_id               = module.create_prod_sp.service_principal_application_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
  feature_tags {
      enterprise = true
      gallery    = true
    }
}

// Output values
output "STAGING-AZURE-SP-APPLICATION-ID" {
  value     = module.create_staging_sp.service_principal_application_id
  sensitive = true
}

output "STAGING-AZURE-SP-CLIENT-SECRET" {
  value     = module.create_staging_sp.service_principal_client_secret
  sensitive = true
}

output "STAGING-AZURE-SP-TENANT-ID" {
  value     = var.azure_tenant_id
  sensitive = true
}

output "PROD-AZURE-SP-APPLICATION-ID" {
  value     = module.create_prod_sp.service_principal_application_id
  sensitive = true
}

output "PROD-AZURE-SP-CLIENT-SECRET" {
  value     = module.create_prod_sp.service_principal_client_secret
  sensitive = true
}

output "PROD-AZURE-SP-TENANT-ID" {
  value     = var.azure_tenant_id
  sensitive = true
}
