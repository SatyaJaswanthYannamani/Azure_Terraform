provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "cloudiq_rg" {
  name     = "CloudIQ-Resource-Group1"
  location = "East US"
}

resource "azurerm_virtual_network" "cloudiq_vnet" {
  name                = "CloudIQ-Sample-VPC"
  address_space       = ["172.0.0.0/16"]
  location            = azurerm_resource_group.cloudiq_rg.location
  resource_group_name = azurerm_resource_group.cloudiq_rg.name
}

resource "azurerm_subnet" "cloudiq_subnet" {
  count                     = 4
  name                      = count.index < 2 ? "CloudIQ-Private-Subnet-${count.index + 1}" : "CloudIQ-Public-Subnet-${count.index - 1}"
  resource_group_name       = azurerm_resource_group.cloudiq_rg.name
  virtual_network_name      = azurerm_virtual_network.cloudiq_vnet.name
  address_prefixes          = ["172.0.${count.index}.0/24"]
}

resource "azurerm_network_interface" "cloudiq_nic" {
  count               = 4
  name                = "cloudiq-nic-${count.index}"
  location            = azurerm_resource_group.cloudiq_rg.location
  resource_group_name = azurerm_resource_group.cloudiq_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.cloudiq_subnet[count.index].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "cloudiq_vm" {
  count                 = 4
  name                  = "cloudiq-vm-${count.index}"
  resource_group_name   = azurerm_resource_group.cloudiq_rg.name
  location              = azurerm_resource_group.cloudiq_rg.location
  size                  = "Standard_DS1_v2"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.cloudiq_nic[count.index].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub") 
  }
}

