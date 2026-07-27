// This file is for doing static analysis and contains sensible defaults
// for PSRule to minimise false-positives and provide the best results.

// This file is not intended to be used as a runtime configuration file.

targetScope = 'subscription'

param environmentName string = 'testing'
param location string = 'swedencentral'

module main 'main.bicep' = {
  name: 'main'
  params: {
    environmentName: environmentName
    location: location
    documentIntelligenceResourceGroupLocation: location
    documentIntelligenceSkuName: 'S0'
    openAiHost: 'azure'
    openAiLocation: location
    searchFieldNameEmbedding: 'embedding'
    searchIndexName: 'gptkbindex'
    searchQueryLanguage: 'en-us'
    searchQuerySpeller: 'lexicon'
    searchServiceQueryRewriting: 'none'
    searchServiceSemanticRankerLevel: 'free'
    searchServiceSkuName: 'standard'
    storageSkuName: 'Standard_LRS'
    useApplicationInsights: false
    useVectors: true
    useMultimodal: true

    // Test the secure configuration
    usePrivateEndpoint: true
    publicNetworkAccess: 'Disabled'
  }
}
