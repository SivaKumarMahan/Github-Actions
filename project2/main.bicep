param storageAccountName string
param location string
param accountType string
param kind string

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: accountType
  }
  kind: kind
  properties: {}
}
