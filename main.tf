terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.72.0"
    }
  }
  required_version = "=1.0.4"
  backend "azurerm" {
    resource_group_name  = "tf4rg"
    storage_account_name = "tf4sa"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
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