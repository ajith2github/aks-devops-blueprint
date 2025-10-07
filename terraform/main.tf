provider "azurerm" {
  features {}
  subscription_id = var.subscription_id 
}

resource "azurerm_resource_group" "main" {
  name     = "ajaks-rg"
  location = "East US"
}

resource "azurerm_management_lock" "rg_lock" {
  name       = "rg-can-not-delete"
  scope      = azurerm_resource_group.main.id
  lock_level = "CanNotDelete" # or "ReadOnly"
  notes      = "Prevent accidental deletion of RG"
}

resource "azurerm_virtual_network" "main" {
  name                = "ajaks-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_network_security_group" "ajaks_nsg" {
  name                = "ajaks-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowInternal"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    source_port_range          = "*"
    destination_port_range     = "*"
    description                = "Allow traffic within virtual network"
  }

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    description                = "Deny all inbound traffic"
  }
}

resource "azurerm_subnet" "ajaks" {
  name                 = "ajaks-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "ajaks_subnet_assoc" {
  subnet_id                 = azurerm_subnet.ajaks.id
  network_security_group_id = azurerm_network_security_group.ajaks_nsg.id
}

resource "random_id" "acr" {
  byte_length = 5
}

resource "azurerm_container_registry" "main" {
  name                  = "ajaksacr${random_id.acr.hex}"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  sku                   = "Standard"
  admin_enabled         = true
}

resource "azurerm_management_lock" "acr_lock" {
  name       = "acr-can-not-delete"
  scope      = azurerm_container_registry.main.id
  lock_level = "CanNotDelete"
  notes      = "Prevent accidental deletion of ACR"
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "ajaks-prod"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "ajaksprod"
  kubernetes_version  = "1.31.8"

  default_node_pool {
    name           = "default"
    node_count     = 2
    vm_size        = "Standard_DS2_v2"
    vnet_subnet_id = azurerm_subnet.ajaks.id
  }

  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

  network_profile {
    network_plugin      = "azure"
    service_cidr        = "10.2.0.0/16"
    dns_service_ip      = "10.2.0.10"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled           = true
    admin_group_object_ids       = [var.admin_group_object_id]
    tenant_id                    = var.tenant_id
  }

  tags = {
    environment = "prod"
  }
}

resource "azurerm_key_vault" "main" {
  name                        = "ajakskv${random_id.acr.hex}"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "ajakslaw${random_id.acr.hex}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "keyvault_diag" {
  name                       = "ajakskv-diag"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "AuditEvent"
    retention_policy {
      enabled = false
      days = 0
    }
  }
}
output "ajaks_kube_config" {
  value     = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive = true
}
