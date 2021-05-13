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

resource "azurerm_key_vault" "example" {
  name                        = "podkeyvault"
  location                    =  var.location
  resource_group_name         = azurerm_resource_group.example.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "list"
    ]

    secret_permissions = [
      "Get","list"
    ]

    storage_permissions = [
      "Get","list"
    ]
  }
}

##azure sql

resource "azurerm_mysql_server" "basic_cluster" {
  name                = "basic-mysqlserver"
  location            = var.location
  resource_group_name = azurerm_resource_group.example.name

  administrator_login          = var.mysql_server_user
  administrator_login_password = var.mysql_server_pwd

  sku_name   = "B_Gen5_2"
  storage_mb = 5120
  version    = "8"

  auto_grow_enabled                 = true
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = true
  infrastructure_encryption_enabled = true
  public_network_access_enabled     = false
  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"
}

resource "azurerm_mysql_database" "example" {
  name                = "apidb"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_mysql_server.basic_cluster.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}