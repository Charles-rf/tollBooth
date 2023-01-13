targetScope = 'subscription'


@description('Name of the resource group')
param resourceGroupName string = 'TEST4_tollBoothApp'

@minLength(1)
@description('Location of the resource group')
param location string


resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
}

param tollBoothApp string = 'tb${uniqueString(resourceGroupName)}'

param storageName string = '${tollBoothApp}storage'
param eventGridTopicName string =  '${tollBoothApp}eventgrid'
param cosmosDBName string = '${tollBoothApp}cosmosdb'
param keyVaultName string = '${tollBoothApp}keyvault'

param funcAppNames array = ['app', 'event']

module functionAppNode 'funcApp.bicep' = [for (name, i) in funcAppNames : {
  scope: resourceGroup
  name: '${tollBoothApp}${funcAppNames[i]}'
  params: {
    appName: '${uniqueString(resourceGroup.id)}${funcAppNames[i]}'
    location: location
  }
}]

module storage 'storageAcc.bicep' = {
  scope: resourceGroup
  name: storageName
  params: {
    storageAccountName: 'storage${uniqueString(resourceGroup.id)}init'
    location: location
  }
}

module eventGridTopic 'eventGridTopic.bicep' = {
  scope: resourceGroup
  name: eventGridTopicName
  params: {
    eventGridTopicName: eventGridTopicName
    location: location
  }
}

module cosmosDB 'cosmosDB.bicep' = {
  scope: resourceGroup
  name: cosmosDBName
  params: {
    location: location
  }
}

module keyVault 'keyVault.bicep' = {
  scope: resourceGroup
  name: keyVaultName
  params: {
    location: location
    vaultName: keyVaultName
  }
}

