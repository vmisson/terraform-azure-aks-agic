resource "azurerm_virtual_network" "spoke" {
  name                = var.virtual_network_spoke_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.virtual_network_address_spoke_prefix]

  tags = var.tags
}

resource "azurerm_subnet" "snet-aks" {
  name                 = var.aks_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.aks_subnet_address_prefix]
}

resource "azurerm_virtual_network_peering" "hub-to-spoke" {
  name                      = "hub-to-spoke"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id
}

resource "azurerm_virtual_network_peering" "spoke-to-hub" {
  name                      = "spoke-to-hub"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
}

resource "azurerm_route_table" "aks-rt" {
  name                = "aks-rt"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_route" "appgw-route" {
  name                   = "route-to-appgw"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.aks-rt.name
  address_prefix         = "10.100.0.0/23"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "10.100.1.4"
}

resource "azurerm_subnet_route_table_association" "aks-rt-association" {
  subnet_id      = azurerm_subnet.snet-aks.id
  route_table_id = azurerm_route_table.aks-rt.id
}

resource "azurerm_kubernetes_cluster" "k8s" {
  name       = var.aks_name
  location   = azurerm_resource_group.rg.location
  dns_prefix = var.aks_dns_prefix

  resource_group_name = azurerm_resource_group.rg.name

  http_application_routing_enabled = false

  linux_profile {
    admin_username = var.vm_user_name

    ssh_key {
      key_data = file(var.public_ssh_key_path)
    }
  }

  default_node_pool {
    name            = "agentpool"
    node_count      = var.aks_agent_count
    vm_size         = var.aks_agent_vm_size
    os_disk_size_gb = var.aks_agent_os_disk_size
    vnet_subnet_id  = azurerm_subnet.snet-aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    dns_service_ip     = var.aks_dns_service_ip
    docker_bridge_cidr = var.aks_docker_bridge_cidr
    service_cidr       = var.aks_service_cidr
  }

  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.application-gateway.id
  }

  tags = var.tags

}
