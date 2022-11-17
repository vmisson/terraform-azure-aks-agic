# Locals block for hardcoded names
locals {
  backend_address_pool_name      = "${azurerm_virtual_network.spoke.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.spoke.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.spoke.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.spoke.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.spoke.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.spoke.name}-rqrt"
  app_gateway_subnet_name        = "appgwsubnet"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

# Network
resource "azurerm_virtual_network" "hub" {
  name                = var.virtual_network_hub_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.virtual_network_address_hub_prefix]

  tags = var.tags
}

resource "azurerm_subnet" "snet-appgw" {
  name                 = var.app_gateway_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.app_gateway_subnet_address_prefix]
}

resource "azurerm_subnet" "snet-firewall-trust" {
  name                 = "snet-firewall-trust"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.fw_trust_subnet_address_prefix]
}

resource "azurerm_subnet" "snet-firewall-untrust" {
  name                 = "snet-firewall-untrust"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.fw_untrust_subnet_address_prefix]
}

resource "azurerm_subnet" "snet-firewall-management" {
  name                 = "snet-firewall-management"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.fw_management_subnet_address_prefix]
}

resource "azurerm_route_table" "appgw-rt" {
  name                = "appgw-rt"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_route" "aks-route" {
  name                = "route-to-aks"
  resource_group_name = azurerm_resource_group.rg.name
  route_table_name    = azurerm_route_table.appgw-rt.name
  address_prefix      = var.virtual_network_address_spoke_prefix
  next_hop_type       = "VirtualAppliance"
  next_hop_in_ip_address = "10.100.1.68"
}

resource "azurerm_subnet_route_table_association" "appgw-rt-association" {
  subnet_id      = azurerm_subnet.snet-appgw.id
  route_table_id = azurerm_route_table.appgw-rt.id
}

# Public Ip 
resource "azurerm_public_ip" "app-gw-pip01" {
  name                = "app-gw-pip01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "akscluster"

  tags = var.tags
}

resource "azurerm_role_assignment" "aks-agic-id-rg-contrib" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         =  azurerm_kubernetes_cluster.k8s.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
}

resource "azurerm_application_gateway" "application-gateway" {
  name                = var.app_gateway_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = var.app_gateway_sku
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "app-gw-pip01"
    subnet_id = azurerm_subnet.snet-appgw.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_port {
    name = "httpsPort"
    port = 443
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.app-gw-pip01.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority = 1
  }

  rewrite_rule_set {
    name = "add-default-header"
    rewrite_rule {
      name          = "add-header-MyHeader"
      rule_sequence = 100
      request_header_configuration {
          header_name  = "MyHeader"
          header_value = "Test"
      }
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      frontend_port,
      http_listener,
      probe,
      redirect_configuration,
      request_routing_rule,
      ssl_certificate,
      tags,
      url_path_map,
    ]
  }  
}

