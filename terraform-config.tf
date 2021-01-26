variable "storage_account_name" {
    type=string
    default="storagenative"
}
 
variable "resource_group_name" {
    type=string
    default="resourcegroupnative"
}

variable "location_name" {
    type=string
    default="CentralIndia"
}
 
provider "azurerm"{
version = "= 2.0" 
subscription_id = "eab0d7cf-77e5-4718-8777-02786cde6d05"
tenant_id       = "6dbb7218-cbc3-40fb-869f-93c5545c912f"
features {}
}
 
resource "azurerm_resource_group" "grp" {
  name     = var.resource_group_name
  location = var.location_name
}
 
resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.grp.name
  location                 = azurerm_resource_group.grp.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}