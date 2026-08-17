data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "security" {

  name =
    "kv-newdam-security"

  location =
    azurerm_resource_group.it.location

  resource_group_name =
    azurerm_resource_group.it.name

  tenant_id =
    data.azurerm_client_config.current.tenant_id

  sku_name =
    "standard"

  soft_delete_retention_days =
    7

  purge_protection_enabled =
    false

  rbac_authorization_enabled =
    true

  tags = {

    Project =
      "Nieuwdam"

    Owner =
      "IT"

    Purpose =
      "Security"

  }

}