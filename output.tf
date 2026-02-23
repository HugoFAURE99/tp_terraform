output "resource_group_id" {
  description = "ID du Resource Group créé"
  value       = azurerm_resource_group.rg-tp-terraform.id
}

output "resource_group_location" {
  description = "Région du Resource Group"
  value       = azurerm_resource_group.rg-tp-terraform.location
}

output "virtual_network_name" {
  description = "Nom du Virtual Network"
  value       = azurerm_virtual_network.vnet-tp-terraform.name
}

output "subnet_id" {
  description = "ID du Subnet"
  value       = azurerm_subnet.subnet-tp-terraform-1.id
}

output "load_balancer_public_ip" {
  description = "IP publique du Load Balancer pour tester l'accès Nginx"
  value       = azurerm_public_ip.lb_pip.ip_address
}