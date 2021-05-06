provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-k8s-resources"
  location = var.location
}

resource "azurerm_user_assigned_identity" "testing" {
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
   name = "testing-api"
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = "${var.prefix}-k8s"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = "${var.prefix}-k8s"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "UserAssigned"
    user_assigned_identity_id = azurerm_user_assigned_identity.testing.id
  }

  addon_profile {
    aci_connector_linux {
      enabled = false
    }

    azure_policy {
      enabled = false
    }

    http_application_routing {
      enabled = false
    }

    kube_dashboard {
      enabled = false
    }

    oms_agent {
      enabled = false
    }
  }
}

resource "helm_release" "pod_identity" {
  name = var.pod_identity_name
  chart = var.pod_identity_chart
  repository = "https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts"
  timeout = 1200

}