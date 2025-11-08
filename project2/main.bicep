resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'storagegithubaction'
  location: 'Central India'
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {}
}
