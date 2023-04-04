terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.48.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
}

resource "azurerm_resource_group" "devops1" {
  name     = "devops1"
  location = "UK South"
}

resource "azurerm_virtual_network" "devops1net" {
  name                = "devops1net"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.devops1.location
  resource_group_name = azurerm_resource_group.devops1.name
}

resource "azurerm_subnet" "devops1sub" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.devops1.name
  virtual_network_name = azurerm_virtual_network.devops1net.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "devops1nic" {
  name                = "devops1nic"
  location            = azurerm_resource_group.devops1.location
  resource_group_name = azurerm_resource_group.devops1.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.devops1sub.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "devops1vm" {
  name                = "devops1vm"
  resource_group_name = azurerm_resource_group.devops1.name
  location            = azurerm_resource_group.devops1.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.devops1nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/tf-key.pub" )
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}