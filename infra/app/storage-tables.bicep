targetScope = 'resourceGroup'

@description('Name of existing storage account to add tables to')
param storageAccountName string
@description('List of table names to ensure exist')
param tableNames array

// Existing storage account
resource stg 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

// Existing table service
resource tableService 'Microsoft.Storage/storageAccounts/tableServices@2023-05-01' existing = {
  name: 'default'
  parent: stg
}

// Create each table
resource tables 'Microsoft.Storage/storageAccounts/tableServices/tables@2023-05-01' = [
  for t in tableNames: {
    name: t
    parent: tableService
  }
]
