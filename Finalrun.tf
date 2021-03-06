
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
        "appName": {
            "type": "string",
            "minLength": 2,
            "maxLength": 6,
            "metadata": {
                "description": "Specifies the name for the app."
            }
        }
    },
    "variables": {
        "appStorageAccountName": "[toLower(concat(parameters('appName'),uniqueString(subscription().subscriptionId, resourceGroup().id)))]",
        "appStorageAccountId": "[concat(resourceGroup().id,'/providers/','Microsoft.Storage/storageAccounts/', variables('appStorageAccountName'))]",
        "dataStorageAccountName": "[toLower(concat(parameters('appName'),'data',uniqueString(subscription().subscriptionId, resourceGroup().id)))]",
        "dataStorageAccountId": "[concat(resourceGroup().id,'/providers/','Microsoft.Storage/storageAccounts/', variables('dataStorageAccountName'))]",
        "hostingPlanName": "[parameters('appName')]",
        "functionAppName": "[concat(parameters('appName'),'-fn')]",
        "serviceBusNamespace": "[toLower(concat(parameters('appName'),'sb',uniqueString(subscription().subscriptionId, resourceGroup().id)))]"
    },
    "resources": [
        {
            "name": "[variables('serviceBusNamespace')]",
            "type": "Microsoft.ServiceBus/namespaces",
            "apiVersion": "2018-01-01-preview",
            "location": "[resourceGroup().location]",
            "sku": {
              "name": "Basic",
              "tier": "Basic"
            },
            "properties": { },
            "resources": [
                {
                    "name": "outqueue",
                    "type": "queues",
                    "apiVersion": "2018-01-01-preview",
                    "dependsOn": [
                        "[variables('serviceBusNamespace')]"
                    ],
                    "properties": {
                      "DefaultMessageTimeToLive": "P14D"
                    }
                  }
            ]
        },
        {
            "name": "[variables('appStorageAccountName')]",
            "type": "Microsoft.Storage/storageAccounts",
            "apiVersion": "2020-08-01-preview",
            "sku": {
              "name": "Standard_RAGRS"
            },
            "kind": "StorageV2",
            "location": "[resourceGroup().location]",
            "properties": {},
            "resources": []
          },
          {
            "name": "[variables('dataStorageAccountName')]",
            "type": "Microsoft.Storage/storageAccounts",
            "apiVersion": "2020-08-01-preview",
            "sku": {
              "name": "Standard_RAGRS"
            },
            "kind": "StorageV2",
            "location": "[resourceGroup().location]",
            "properties": {},
            "resources": [
                {
                    "name": "default/data",
                    "type": "blobServices/containers",
                    "apiVersion": "2020-08-01-preview",
                    "dependsOn": [
                        "[variables('dataStorageAccountName')]"
                    ]
                }                
            ]
          },

          {
            "type": "Microsoft.Web/serverfarms",
            "apiVersion": "2018-02-01",
            "name": "[variables('hostingPlanName')]",
            "location": "[resourceGroup().location]",
            "sku": {
              "name": "Y1",
              "tier": "Dynamic"
            },
            "properties": {
              "name": "[variables('hostingPlanName')]",
              "computeMode": "Dynamic"
            }
          },
          {
            "apiVersion": "2018-11-01",
            "type": "Microsoft.Web/sites",
            "name": "[variables('functionAppName')]",
            "location": "[resourceGroup().location]",
            "kind": "functionapp",
            "dependsOn": [
              "[resourceId('Microsoft.Web/serverfarms', variables('hostingPlanName'))]",
              "[resourceId('Microsoft.Storage/storageAccounts', variables('appStorageAccountName'))]",
              "[resourceId('Microsoft.Storage/storageAccounts', variables('dataStorageAccountName'))]",
              "[resourceId('Microsoft.ServiceBus/namespaces', variables('serviceBusNamespace'))]"
            ],
            "properties": {
              "serverFarmId": "[resourceId('Microsoft.Web/serverfarms', variables('hostingPlanName'))]",
              "siteConfig": {
                "appSettings": [
                  {
                    "name": "AzureWebJobsDashboard",
                    "value": "[concat('DefaultEndpointsProtocol=https;AccountName=', variables('appStorageAccountName'), ';AccountKey=', listKeys(variables('appStorageAccountId'),'2015-05-01-preview').key1)]"
                  },
                  {
                    "name": "AzureWebJobsStorage",
                    "value": "[concat('DefaultEndpointsProtocol=https;AccountName=', variables('appStorageAccountName'), ';AccountKey=', listKeys(variables('appStorageAccountId'),'2015-05-01-preview').key1)]"
                  },
                  {
                    "name": "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING",
                    "value": "[concat('DefaultEndpointsProtocol=https;AccountName=', variables('appStorageAccountName'), ';AccountKey=', listKeys(variables('appStorageAccountId'),'2015-05-01-preview').key1)]"
                  },
                  {
                    "name": "WEBSITE_CONTENTSHARE",
                    "value": "[toLower(variables('functionAppName'))]"
                  },
                  {
                    "name": "FUNCTIONS_EXTENSION_VERSION",
                    "value": "~3"
                  },
                  {
                    "name": "WEBSITE_NODE_DEFAULT_VERSION",
                    "value": "8.11.1"
                  },
                  {
                    "name": "FUNCTIONS_WORKER_RUNTIME",
                    "value": "dotnet"
                  },
                  {
                      "name": "ServiceBusConnectionAppSetting",
                      "value": "[listKeys(resourceId(concat('Microsoft.ServiceBus/namespaces/AuthorizationRules'),variables('serviceBusNamespace'),'RootManageSharedAccessKey'),'2015-08-01').primaryConnectionString]"
                  },
                  {
                      "name": "StorageConnectionAppSetting",
                      "value": "[concat('DefaultEndpointsProtocol=https;AccountName=', variables('dataStorageAccountName'), ';AccountKey=', listKeys(variables('dataStorageAccountId'),'2015-05-01-preview').key1)]"
                  }
                ]
              }
            }
          }
        ],
    "outputs": {}
}
DEPLOY


  # these key-value pairs are passed into the ARM Template's `parameters` block
  parameters = {
    "appName" = "testap"
  }

  deployment_mode = "Incremental"
}

