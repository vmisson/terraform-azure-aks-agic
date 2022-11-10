output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "application_ip_address" {
  value = azurerm_public_ip.app-gw-pip01.ip_address
}