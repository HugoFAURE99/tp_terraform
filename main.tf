resource "azurerm_resource_group" "rg-tp-terraform" {
  name     = "${var.prefix}-rg"
  location = var.location
  tags = {
    environment = "tp"
    managed_by  = "terraform"
  }
}

resource "azurerm_virtual_network" "vnet-tp-terraform" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-tp-terraform.name
  tags = {
    environment = "tp"
    managed_by  = "terraform"
  }
}

resource "azurerm_subnet" "subnet-tp-terraform-1" {
  name                 = "${var.prefix}-subnet-1"
  address_prefixes     = ["10.0.0.0/24"]
  resource_group_name  = azurerm_resource_group.rg-tp-terraform.name
  virtual_network_name = azurerm_virtual_network.vnet-tp-terraform.name
}

resource "azurerm_network_security_group" "nsg-tp-terraform" {
  name                 = "${var.prefix}-nsg"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg-tp-terraform.name
  tags = {
    environment = "tp"
    managed_by  = "terraform"
  }
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
} 

resource "azurerm_subnet_network_security_group_association" "subnet-nsg-association-tp-terraform" {
  subnet_id                 = azurerm_subnet.subnet-tp-terraform-1.id
  network_security_group_id = azurerm_network_security_group.nsg-tp-terraform.id
}

#VM1 - Configuration des resources 
resource "azurerm_network_interface" "nic-1-tp-terraform" {
  name                 = "${var.prefix}-nic-1"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg-tp-terraform.name
  tags = {
    environment = "tp"
    managed_by  = "terraform"
  }
  #Configuration IP privée dynamique (pas d'IP publique directe sur la NIC)
  ip_configuration {
    name                          = "${var.prefix}-ip-1"
    subnet_id                     = azurerm_subnet.subnet-tp-terraform-1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = null 
  }
}

resource "azurerm_linux_virtual_machine" "vm-1-tp-terraform" {
  name                 = "${var.prefix}-vm-1"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg-tp-terraform.name
  size                 = "Standard_B1s"
  admin_username       = "azureuser"
  admin_password       = null
  disable_password_authentication = true
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("C:/Users/Utilisateur/.ssh/id_tp_azure.pub")
  }
  network_interface_ids = [azurerm_network_interface.nic-1-tp-terraform.id]
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  os_disk {
    name                 = "${var.prefix}-os-disk-1"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }
  tags = {
    environment = "tp"
    managed_by  = "terraform"
  }
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    echo "<h1>Hello from ${var.prefix}-vm-1</h1>" > /var/www/html/index.html
    systemctl start nginx
    systemctl enable nginx
  EOF
  )
}

#VM2 - Configuration des resources 
resource "azurerm_network_interface" "nic-2-tp-terraform" {
  name                 = "${var.prefix}-nic-2"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg-tp-terraform.name
  tags = {
    environment = "tp"
    managed_by  = "terraform"
  }
  #Configuration IP privée dynamique (pas d'IP publique directe sur la NIC)
  ip_configuration {
    name                          = "${var.prefix}-ip-2"
    subnet_id                     = azurerm_subnet.subnet-tp-terraform-1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = null 
  }
}

resource "azurerm_linux_virtual_machine" "vm-2-tp-terraform" {
  name                 = "${var.prefix}-vm-2"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg-tp-terraform.name
  size                 = "Standard_B1s"
  admin_username       = "azureuser"
  admin_password       = null
  disable_password_authentication = true
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("C:/Users/Utilisateur/.ssh/id_tp_azure.pub")
  }
  network_interface_ids = [azurerm_network_interface.nic-2-tp-terraform.id]
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  os_disk {
    name                 = "${var.prefix}-os-disk-2"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }
  tags = {
    environment = "tp"
    managed_by  = "terraform"
  }
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    echo "<h1>Hello from ${var.prefix}-vm-2</h1>" > /var/www/html/index.html
    systemctl start nginx
    systemctl enable nginx
  EOF
  )
}


#Load Balancer
# 5.1 — IP publique pour le Load Balancer
resource "azurerm_public_ip" "lb_pip" {
  name                = "${var.prefix}-lb-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-tp-terraform.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 5.2 — Le Load Balancer
resource "azurerm_lb" "lb-tp-terraform" {
  name                = "${var.prefix}-lb"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-tp-terraform.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

# 5.3 — Backend Address Pool
resource "azurerm_lb_backend_address_pool" "backend_pool-tp-terraform" {
  loadbalancer_id = azurerm_lb.lb-tp-terraform.id
  name            = "${var.prefix}-backend-pool"
}

# 5.4 — Association des NICs (VM1 et VM2) au Backend Pool
resource "azurerm_network_interface_backend_address_pool_association" "assoc_vm1" {
  network_interface_id    = azurerm_network_interface.nic-1-tp-terraform.id
  ip_configuration_name   = "${var.prefix}-ip-1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool-tp-terraform.id
}

resource "azurerm_network_interface_backend_address_pool_association" "assoc_vm2" {
  network_interface_id    = azurerm_network_interface.nic-2-tp-terraform.id
  ip_configuration_name   = "${var.prefix}-ip-2"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool-tp-terraform.id
}

# 5.5 — Health Probe (Sonde de santé)
resource "azurerm_lb_probe" "http_probe" {
  loadbalancer_id = azurerm_lb.lb-tp-terraform.id
  name            = "${var.prefix}-http-probe"
  protocol        = "Http"
  port            = 80
  request_path    = "/"
}

# 5.6 — Load Balancing Rule
resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.lb-tp-terraform.id
  name                           = "${var.prefix}-http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool-tp-terraform.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
}
