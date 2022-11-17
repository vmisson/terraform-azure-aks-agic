variable "resource_group_name" {
  default     = "poc-appgw-aks-rg"
  description = "Ressource Group Name"
}

variable "resource_group_location" {
  default     = "northeurope"
  description = "Location of the resource group."
}

variable "tags" {
  type = map(string)

  default = {
    source = "terraform"
  }
}

# Hub
variable "virtual_network_hub_name" {
  description = "Virtual network name"
  default     = "hubVirtualNetwork"
}

variable "virtual_network_address_hub_prefix" {
  description = "Hub VNet address prefix"
  default     = "10.100.0.0/23"
}

variable "app_gateway_subnet_name" {
  description = "Subnet name for Application Gateway"
  default     = "snet-applicationgateway"
}

variable "app_gateway_subnet_address_prefix" {
  description = "Subnet server IP address."
  default     = "10.100.0.0/24"
}

variable "fw_trust_subnet_address_prefix" {
  description = "Subnet server IP address."
  default     = "10.100.1.0/26"
}

variable "fw_untrust_subnet_address_prefix" {
  description = "Subnet server IP address."
  default     = "10.100.1.64/26"
}

variable "fw_management_subnet_address_prefix" {
  description = "Subnet server IP address."
  default     = "10.100.1.128/26"
}

# Application Gateway
variable "app_gateway_name" {
  description = "Name of the Application Gateway"
  default     = "app-gw1"
}

variable "app_gateway_sku" {
  description = "Name of the Application Gateway SKU"
  default     = "WAF_v2"
}

variable "app_gateway_tier" {
  description = "Tier of the Application Gateway tier"
  default     = "Standard_v2"
}

#############################################################################

variable "firewall_vm_name" {
  type    = string
  default = "firewall"
}

variable "allow_inbound_mgmt_ips" {
  default = ["2.3.186.236"]
  type    = list(string)

  validation {
    condition     = length(var.allow_inbound_mgmt_ips) > 0
    error_message = "At least one address has to be specified."
  }
}

variable "common_vmseries_sku" {
  description = "VM-Series SKU - list available with `az vm image list -o table --all --publisher paloaltonetworks`"
  default     = "byol"
  type        = string
}

variable "common_vmseries_version" {
  description = "VM-Series PAN-OS version - list available with `az vm image list -o table --all --publisher paloaltonetworks`"
  default     = "latest"
  #default     = "9.1.10"
  type = string
}

variable "common_vmseries_vm_size" {
  description = "Azure VM size (type) to be created. Consult the *VM-Series Deployment Guide* as only a few selected sizes are supported."
  default     = "Standard_D3_v2"
  type        = string
}

variable "username" {
  description = "Initial administrative username to use for all systems."
  default     = "panadmin"
  type        = string
}

variable "password" {
  description = "Initial administrative password to use for all systems. Set to null for an auto-generated password."
  default     = "ARandomPassword=1"
  type        = string
}

variable "avzones" {
  type    = list(string)
  default = ["1", "2", "3"]
}

variable "enable_zones" {
  type = bool
  default = true
}

##########################################################################################
# Spoke
variable "virtual_network_spoke_name" {
  description = "Virtual network name"
  default     = "aksVirtualNetwork"
}

variable "virtual_network_address_spoke_prefix" {
  description = "Spoke VNet address prefix"
  default     = "10.200.0.0/16"
}

variable "aks_subnet_name" {
  description = "Subnet Name."
  default     = "kubesubnet"
}

variable "aks_subnet_address_prefix" {
  description = "Subnet address prefix."
  default     = "10.200.0.0/16"
}

# AKS
variable "aks_name" {
  description = "AKS cluster name"
  default     = "aks-cluster1"
}
variable "aks_dns_prefix" {
  description = "Optional DNS prefix to use with hosted Kubernetes API server FQDN."
  default     = "poc-aks"
}

variable "aks_agent_os_disk_size" {
  description = "Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 applies the default disk size for that agentVMSize."
  default     = 40
}

variable "aks_agent_count" {
  description = "The number of agent nodes for the cluster."
  default     = 4
}

variable "aks_agent_vm_size" {
  description = "VM size"
  default     = "Standard_D3_v2"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  default     = "1.11.5"
}

variable "aks_service_cidr" {
  description = "CIDR notation IP range from which to assign service cluster IPs"
  default     = "10.201.0.0/16"
}

variable "aks_dns_service_ip" {
  description = "DNS server IP address"
  default     = "10.201.0.10"
}

variable "aks_docker_bridge_cidr" {
  description = "CIDR notation IP for Docker bridge."
  default     = "172.17.0.1/16"
}

variable "aks_enable_rbac" {
  description = "Enable RBAC on the AKS cluster. Defaults to false."
  default     = "false"
}

variable "vm_user_name" {
  description = "User name for the VM"
  default     = "vmuser1"
}

variable "public_ssh_key_path" {
  description = "Public key path for SSH."
  default     = "~/.ssh/id_rsa.pub"
}

