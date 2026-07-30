resource "azurerm_virtual_network" "main" {

  name                = "vnet-newdam"
  address_space       = ["10.10.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.network.name


}


resource "azurerm_subnet" "servers" {

  name = "subnet-servers"

  resource_group_name = azurerm_resource_group.network.name

  virtual_network_name = azurerm_virtual_network.main.name

  address_prefixes = [
    "10.10.1.0/24"
  ]

}