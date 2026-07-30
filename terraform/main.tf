resource "azurerm_resource_group" "it" {

  name     = "rg-newdam-it"
  location = var.location


  tags = {

    Project = "Nieuwdam"
    Owner   = "IT"

  }

}


resource "azurerm_resource_group" "network" {

  name     = "rg-newdam-network"
  location = var.location


  tags = {

    Project = "Nieuwdam"

  }

}