
provider "azurerm"{
version = "~> 2.1.0" 
subscription_id = "eab0d7cf-77e5-4718-8777-02786cde6d05"
tenant_id       = "6dbb7218-cbc3-40fb-869f-93c5545c912f"
features {}
}


resource "azurerm_resource_group" "group1" {
  name     = "resourcegrouptemplate1"
  location = "centralindia"
}

resource "azurerm_template_deployment" "template1" {
  name                = "storagetemplate-01"
  resource_group_name = azurerm_resource_group.group1.name

  template_body = <<DEPLOY
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "storageAccountType": {
      "type": "string",
      "defaultValue": "Standard_LRS",
      "allowedValues": [
        "Standard_LRS",
        "Standard_GRS",
        "Standard_ZRS"
      ],
      "metadata": {
        "description": "Storage Account type"
      }
    }
  },
  "variables": {
    "location": "[resourceGroup().location]",
    "storageAccountName": "[concat(uniquestring(resourceGroup().id), 'storage')]",
    "publicIPAddressName": "[concat('myPublicIp', uniquestring(resourceGroup().id))]",
    "publicIPAddressType": "Dynamic",
    "apiVersion": "2015-06-15",
    "dnsLabelPrefix": "terraform-acctest"
  },
  "resources": [
    {
      "type": "Microsoft.Storage/storageAccounts",
      "name": "[variables('storageAccountName')]",
      "apiVersion": "[variables('apiVersion')]",
      "location": "[variables('location')]",
      "properties": {
        "accountType": "[parameters('storageAccountType')]"
      }
    },
    {
      "type": "Microsoft.Network/publicIPAddresses",
      "apiVersion": "[variables('apiVersion')]",
      "name": "[variables('publicIPAddressName')]",
      "location": "[variables('location')]",
      "properties": {
        "publicIPAllocationMethod": "[variables('publicIPAddressType')]",
        "dnsSettings": {
          "domainNameLabel": "[variables('dnsLabelPrefix')]"
        }
      }
    }
  ],
  "outputs": {
    "storageAccountName1": {
      "type": "string",
      "value": "[variables('storageAccountName')]"
    }
  }
}
DEPLOY


  # these key-value pairs are passed into the ARM Template's `parameters` block
  parameters = {
    "storageAccountType" = "Standard_GRS"
  }

  deployment_mode = "Incremental"
}

output "storageAccountName11" {
  value = azurerm_template_deployment.template1.outputs["storageAccountName1"]
}