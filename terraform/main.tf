terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.72.0"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "=0.1.6"
    }
  }
  required_version = ">=1.0.4"
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "k8s4rg"
  location = var.location
}

resource "azurerm_container_registry" "cr" {
  name                = "k8s4cr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Premium"
  admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "kc" {
  name                = "k8s4kc"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "k8s4kc"

  default_node_pool {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

# let kubernetes can pull from acr
resource "azurerm_role_assignment" "ra" {
  scope                = azurerm_container_registry.cr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.kc.kubelet_identity[0].object_id
}

data "azurerm_subscription" "current" {
}

resource "azuredevops_project" "k8s" {
  name = "k8s"
}

resource "azuredevops_serviceendpoint_github" "github" {
  project_id            = azuredevops_project.k8s.id
  service_endpoint_name = "Github"

  auth_personal {
    # Also can be set with AZDO_GITHUB_SERVICE_CONNECTION_PAT environment variable
    personal_access_token = var.github_pat
  }
}

# resource "azuredevops_serviceendpoint_dockerregistry" "acr" {
#     project_id             = azuredevops_project.k8s.id
#     service_endpoint_name  = "Azure Docker Registry"
#     docker_registry      = "https://k8s4cr.azurecr.io/v1"
#     docker_username        = "k8s4cr"
#     docker_password        = "12345"
#     registry_type          = "Others"
# }

resource "azuredevops_serviceendpoint_azurecr" "azurecr" {
  project_id                = azuredevops_project.k8s.id
  service_endpoint_name     = "AzureCR"
  resource_group            = azurerm_resource_group.rg.name
  azurecr_spn_tenantid      = data.azurerm_subscription.current.tenant_id
  azurecr_name              = azurerm_container_registry.cr.name
  azurecr_subscription_id   = data.azurerm_subscription.current.subscription_id
  azurecr_subscription_name = data.azurerm_subscription.current.display_name
}

resource "azuredevops_serviceendpoint_azurerm" "azurerm" {
  project_id                = azuredevops_project.k8s.id
  service_endpoint_name     = "AzureRM"
  description               = "Managed by Terraform"
  azurerm_spn_tenantid      = data.azurerm_subscription.current.tenant_id
  azurerm_subscription_id   = data.azurerm_subscription.current.subscription_id
  azurerm_subscription_name = data.azurerm_subscription.current.display_name
}

resource "azuredevops_build_definition" "adservice" {
  project_id = azuredevops_project.k8s.id
  name       = "adservice"

  ci_trigger {
    use_yaml = true
  }

  repository {
    repo_type             = "GitHub"
    repo_id               = "gaoyuyue/infrastructure"
    branch_name           = "main"
    yml_path              = "src/adservice/.azure-pipelines/cicd.yml"
    service_connection_id = azuredevops_serviceendpoint_github.github.id
  }
}