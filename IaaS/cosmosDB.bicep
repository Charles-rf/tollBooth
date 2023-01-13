@description('Cosmos DB account name, max length 44 characters')
param accountName string = 'sql-${toLower(uniqueString(resourceGroup().id))}'

@description('Location for the Cosmos DB account.')
param location string = resourceGroup().location

@allowed([
  'Eventual'
  'ConsistentPrefix'
  'Session'
  'BoundedStaleness'
  'Strong'
])
@description('The default consistency level of the Cosmos DB account.')
param defaultConsistencyLevel string = 'Session'

@minValue(10)
@maxValue(2147483647)
@description('Max stale requests. Required for BoundedStaleness. Valid ranges, Single Region: 10 to 2147483647. Multi Region: 100000 to 2147483647.')
param maxStalenessPrefix int = 100000

@minValue(5)
@maxValue(86400)
@description('Max lag time (minutes). Required for BoundedStaleness. Valid ranges, Single Region: 5 to 84600. Multi Region: 300 to 86400.')
param maxIntervalInSeconds int = 300

var consistencyPolicy = {
  Eventual: {
    defaultConsistencyLevel: 'Eventual'
  }
  ConsistentPrefix: {
    defaultConsistencyLevel: 'ConsistentPrefix'
  }
  Session: {
    defaultConsistencyLevel: 'Session'
  }
  BoundedStaleness: {
    defaultConsistencyLevel: 'BoundedStaleness'
    maxStalenessPrefix: maxStalenessPrefix
    maxIntervalInSeconds: maxIntervalInSeconds
  }
  Strong: {
    defaultConsistencyLevel: 'Strong'
  }
}

resource account 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' = {
  name: accountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: consistencyPolicy[defaultConsistencyLevel]
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }
}

@description('The name for the SQL API database')
param databaseName string = 'LicensePlates'

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-05-15' = {
  parent: account
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}

@description('Names for the containers')
param container1Name string = 'Processed'
param container2Name string = 'NeedsManualReview'

resource container1 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-08-15'= {
  parent: database
  name: container1Name
  location: location
  properties: {
    resource: {
      id: container1Name
      partitionKey: {
        paths: [
          '/licensePlateText'
        ]
        kind: 'Hash'
      }
    }
  }
}

resource container2 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-08-15'= {
  parent: database
  name: container2Name
  location: location
  properties: {
    resource: {
      id: container2Name
      partitionKey: {
        paths: [
          '/fileName'
        ]
        kind: 'Hash'
      }
    }
  }
}
