data "azuread_group" "it_support" {

  display_name = "SG_IT_Support"

}


resource "azurerm_role_assignment" "it_support_vm" {


  scope = azurerm_resource_group.it.id


  role_definition_name = "Virtual Machine Contributor"


  principal_id = data.azuread_group.it_support.object_id


}