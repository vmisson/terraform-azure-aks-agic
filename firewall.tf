# resource "azurerm_marketplace_agreement" "paloaltonetworks" {
#   publisher = "paloaltonetworks"
#   offer     = "vmseries-flex"
#   plan      = "byol"
# }

#######################################################
#######################################################
#######################################################

locals {
  bootstrap_file = "${path.module}/files/bootstrap.tftpl"
  init-cfg_file  = "${path.module}/files/init-cfg.tftpl"
}

# Create public IPs for the Internet-facing data interfaces so they could talk outbound.
resource "azurerm_public_ip" "fw-public" {
  name                = "${var.firewall_vm_name}-public"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "fw-mgmt" {
  name                = "${var.firewall_vm_name}-mgmt"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${var.firewall_vm_name}-mgmt"
}

resource "azurerm_network_security_group" "nsg-mgmt" {
  name                = "sg-mgmt"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_group" "nsg-public" {
  name                = "sg-public"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Allow inbound access to Management subnet.
resource "azurerm_network_security_rule" "mgmt" {
  name                        = "vmseries-mgmt-allow-inbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg-mgmt.name
  access                      = "Allow"
  direction                   = "Inbound"
  priority                    = 1000
  protocol                    = "*"
  source_port_range           = "*"
  source_address_prefixes     = var.allow_inbound_mgmt_ips
  destination_address_prefix  = "*"
  destination_port_range      = "*"
}

resource "azurerm_subnet_network_security_group_association" "network_security_group_association-mgmt" {
  subnet_id                 = azurerm_subnet.snet-firewall-management.id
  network_security_group_id = azurerm_network_security_group.nsg-mgmt.id
}

resource "azurerm_subnet_network_security_group_association" "network_security_group_association_public" {
  subnet_id                 = azurerm_subnet.snet-firewall-trust.id
  network_security_group_id = azurerm_network_security_group.nsg-public.id
}

# The storage account for VM-Series initialization.
resource "random_integer" "id" {
  min = 100
  max = 999
}

module "bootstrap" {
  source = "./modules/paloalto/bootstrap"

  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_name = "${var.firewall_vm_name}bootstrap${random_integer.id.result}"
  storage_share_name   = "${var.firewall_vm_name}sharebootstrap${random_integer.id.result}"
  files = {
    "templates/init-cfg.txt"  = "config/init-cfg.txt"
    "templates/bootstrap.xml" = "config/bootstrap.xml"
  }
}

module "paloalto_vmseries" {
  source              = "./modules/paloalto/vmseries"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  name                = var.firewall_vm_name
  username            = var.username
  password            = var.password
  img_version         = var.common_vmseries_version
  img_sku             = var.common_vmseries_sku
  enable_zones        = var.enable_zones
  bootstrap_options = (join(",",
    [
      "storage-account=${module.bootstrap.storage_account.name}",
      "access-key=${module.bootstrap.storage_account.primary_access_key}",
      "file-share=${module.bootstrap.storage_share.name}",
      "share-directory=None"
    ]
  ))
  interfaces = [
    {
      name                 = "${var.firewall_vm_name}-mgmt"
      subnet_id            = azurerm_subnet.snet-firewall-management.id
      public_ip_address_id = azurerm_public_ip.fw-mgmt.id
    },
    {
      name                 = "${var.firewall_vm_name}-public"
      subnet_id            = azurerm_subnet.snet-firewall-untrust.id
      public_ip_address_id = azurerm_public_ip.fw-public.id
    },
    {
      name      = "${var.firewall_vm_name}-private"
      subnet_id = azurerm_subnet.snet-firewall-trust.id
    },
  ]
  depends_on = [module.bootstrap]
}
