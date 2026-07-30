targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
// microsoft.insights/components has restricted regions
@allowed([
  'eastus'
  'southcentralus'
  'northeurope'
  'westeurope'
  'southeastasia'
  'westus2'
  'uksouth'
  'canadacentral'
  'centralindia'
  'japaneast'
  'australiaeast'
  'koreacentral'
  'francecentral'
  'centralus'
  'eastus2'
  'eastasia'
  'westus'
  'southafricanorth'
  'northcentralus'
  'brazilsouth'
  'switzerlandnorth'
  'norwayeast'
  'norwaywest'
  'australiasoutheast'
  'australiacentral2'
  'germanywestcentral'
  'switzerlandwest'
  'uaecentral'
  'ukwest'
  'japanwest'
  'brazilsoutheast'
  'uaenorth'
  'australiacentral'
  'southindia'
  'westus3'
  'koreasouth'
  'swedencentral'
  'canadaeast'
  'jioindiacentral'
  'jioindiawest'
  'qatarcentral'
  'southafricawest'
  'germanynorth'
  'polandcentral'
  'israelcentral'
  'italynorth'
  'mexicocentral'
  'spaincentral'
  'newzealandnorth'
  'chilecentral'
  'indonesiacentral'
  'malaysiawest'
])
@metadata({
  azd: {
    type: 'location'
  }
})
param location string

@description('Short owner/organisation prefix inserted into every resource name, e.g. "sd".')
@minLength(2)
@maxLength(6)
param resourceNamePrefix string = 'sd'

param resourceGroupName string = '' // Set in main.parameters.json

param applicationInsightsDashboardName string = '' // Set in main.parameters.json
param applicationInsightsName string = '' // Set in main.parameters.json
param logAnalyticsName string = '' // Set in main.parameters.json

param searchServiceName string = '' // Set in main.parameters.json
param searchServiceResourceGroupName string = '' // Set in main.parameters.json
param searchServiceLocation string = '' // Set in main.parameters.json
// The free tier does not support managed identity (required) or semantic search (optional)
@allowed(['free', 'basic', 'standard', 'standard2', 'standard3', 'storage_optimized_l1', 'storage_optimized_l2'])
param searchServiceSkuName string // Set in main.parameters.json
param searchIndexName string // Set in main.parameters.json
param searchQueryLanguage string // Set in main.parameters.json
param searchQuerySpeller string // Set in main.parameters.json
param searchServiceSemanticRankerLevel string // Set in main.parameters.json
param searchFieldNameEmbedding string // Set in main.parameters.json
var actualSearchServiceSemanticRankerLevel = (searchServiceSkuName == 'free')
  ? 'disabled'
  : searchServiceSemanticRankerLevel
param searchServiceQueryRewriting string // Set in main.parameters.json
param storageAccountName string = '' // Set in main.parameters.json
param storageResourceGroupName string = '' // Set in main.parameters.json
param storageResourceGroupLocation string = location
param storageContainerName string = '${resourceNamePrefix}-source-documents'
param storageSkuName string // Set in main.parameters.json

param imageStorageContainerName string = '${resourceNamePrefix}-extracted-figures'

@allowed(['azure', 'openai', 'azure_custom'])
param openAiHost string // Set in main.parameters.json
param isAzureOpenAiHost bool = startsWith(openAiHost, 'azure')
param deployAzureOpenAi bool = openAiHost == 'azure'
param azureOpenAiCustomUrl string = ''
@secure()
param azureOpenAiApiKey string = ''
param azureOpenAiDisableKeys bool = true
param openAiServiceName string = ''
param openAiResourceGroupName string = ''

@description('Name of the Microsoft Foundry project to create inside the Foundry account. Leave empty to generate one.')
param foundryProjectName string = ''

param useMultimodal bool = false
param useEval bool = false
param useCloudIngestion bool = false

@description('Sync a SharePoint Online document library into the cloud-ingestion Blob container on a schedule. Requires useCloudIngestion=true.')
param useSharePointLogicApp bool = false
@description('SharePoint Online tenant hostname, e.g. contoso.sharepoint.com. Required when useSharePointLogicApp is true.')
param sharePointHostname string = ''
@description('Server-relative SharePoint site path, e.g. /sites/Marketing. Required when useSharePointLogicApp is true.')
param sharePointSitePath string = ''
@description('Optional folder path within the site drive to restrict syncing to. Empty means the whole default document library.')
param sharePointFolderPath string = ''
@description('How often the SharePoint sync Logic App polls for changes, in minutes')
param sharePointSyncIntervalMinutes int = 15
@description('Optional webhook URL (e.g. a Teams incoming webhook) notified when a SharePoint sync or indexer run fails')
@secure()
param sharePointNotificationWebhookUrl string = ''

// When greater than 0, CSV rows are grouped into pages of up to this many characters
// during ingestion instead of one page per row (avoids out-of-memory on large CSV files).
param csvMaxPageChars int = 0

@description('Restore soft-deleted Cognitive Services accounts instead of creating new ones. Set to true after running azd down.')
param restoreCognitiveServices bool = false
param useCloudIngestionAcls bool = false
@description('Use an existing ADLS Gen2 storage account instead of provisioning a new one')
param useExistingAdlsStorage bool = false
// Must be specified when useExistingAdlsStorage is true. Bicep assert is experimental so we can't validate at compile-time yet.
param adlsStorageAccountName string = ''
param adlsStorageResourceGroupName string = ''

// https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/models-sold-directly-by-azure?tabs=global-standard-aoai%2Cglobal-standard&pivots=azure-openai#models-by-deployment-type
@description('Location for the OpenAI resource group')
@allowed([
  'australiaeast'
  'brazilsouth'
  'canadaeast'
  'eastus'
  'eastus2'
  'francecentral'
  'germanywestcentral'
  'japaneast'
  'koreacentral'
  'northcentralus'
  'norwayeast'
  'polandcentral'
  'southafricanorth'
  'southcentralus'
  'southindia'
  'spaincentral'
  'swedencentral'
  'switzerlandnorth'
  'uaenorth'
  'uksouth'
  'westeurope'
  'westus'
  'westus3'
])
@metadata({
  azd: {
    type: 'location'
  }
})
param openAiLocation string

param openAiSkuName string = 'S0'

@secure()
param openAiApiKey string = ''
param openAiApiOrganization string = ''

param documentIntelligenceServiceName string = '' // Set in main.parameters.json
param documentIntelligenceResourceGroupName string = '' // Set in main.parameters.json

// Limited regions for new version:
// https://learn.microsoft.com/azure/ai-services/document-intelligence/concept-layout
@description('Location for the Document Intelligence resource group')
@allowed(['eastus', 'westus2', 'westeurope', 'australiaeast'])
@metadata({
  azd: {
    type: 'location'
  }
})
param documentIntelligenceResourceGroupLocation string

param documentIntelligenceSkuName string // Set in main.parameters.json

param visionServiceName string = '' // Set in main.parameters.json
param visionResourceGroupName string = '' // Set in main.parameters.json
param visionResourceGroupLocation string = '' // Set in main.parameters.json

param contentUnderstandingServiceName string = '' // Set in main.parameters.json
param contentUnderstandingResourceGroupName string = '' // Set in main.parameters.json

param chatGptModelName string = ''
param chatGptDeploymentName string = ''
param chatGptDeploymentVersion string = ''
param chatGptDeploymentSkuName string = ''
param chatGptDeploymentCapacity int = 0

var chatGpt = {
  modelName: !empty(chatGptModelName) ? chatGptModelName : 'gpt-5.4-mini'
  deploymentName: !empty(chatGptDeploymentName) ? chatGptDeploymentName : 'gpt-5.4-mini'
  deploymentVersion: !empty(chatGptDeploymentVersion) ? chatGptDeploymentVersion : '2026-03-17'
  deploymentSkuName: !empty(chatGptDeploymentSkuName) ? chatGptDeploymentSkuName : 'GlobalStandard'
  deploymentCapacity: chatGptDeploymentCapacity != 0 ? chatGptDeploymentCapacity : 30
}

param embeddingModelName string = ''
param embeddingDeploymentName string = ''
param embeddingDeploymentVersion string = ''
param embeddingDeploymentSkuName string = ''
param embeddingDeploymentCapacity int = 0
param embeddingDimensions int = 0
var embedding = {
  modelName: !empty(embeddingModelName) ? embeddingModelName : 'text-embedding-3-large'
  deploymentName: !empty(embeddingDeploymentName) ? embeddingDeploymentName : 'text-embedding-3-large'
  deploymentVersion: !empty(embeddingDeploymentVersion) ? embeddingDeploymentVersion : (embeddingModelName == 'text-embedding-ada-002' ? '2' : '1')
  deploymentSkuName: !empty(embeddingDeploymentSkuName) ? embeddingDeploymentSkuName : (embeddingModelName == 'text-embedding-ada-002' ? 'Standard' : 'GlobalStandard')
  deploymentCapacity: embeddingDeploymentCapacity != 0 ? embeddingDeploymentCapacity : 200
  dimensions: embeddingDimensions != 0 ? embeddingDimensions : 3072
}

param evalModelName string = ''
param evalDeploymentName string = ''
param evalModelVersion string = ''
param evalDeploymentSkuName string = ''
param evalDeploymentCapacity int = 0
var eval = {
  modelName: !empty(evalModelName) ? evalModelName : 'gpt-5.4'
  deploymentName: !empty(evalDeploymentName) ? evalDeploymentName : 'eval'
  deploymentVersion: !empty(evalModelVersion) ? evalModelVersion : '2026-03-05'
  deploymentSkuName: !empty(evalDeploymentSkuName) ? evalDeploymentSkuName : 'GlobalStandard'
  deploymentCapacity: evalDeploymentCapacity != 0 ? evalDeploymentCapacity : 30
}

param tenantId string = tenant().tenantId

// Used for the optional document-level access control system applied during ingestion
param useAuthentication bool = false
param enforceAccessControl bool = false
param enableGlobalDocuments bool = false

@allowed(['None', 'AzureServices'])
@description('If allowedIp is set, whether azure services are allowed to bypass the storage and AI services firewall.')
param bypass string = 'AzureServices'

@description('Public network access value for all deployed resources')
@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string = 'Enabled'

@description('Add a private endpoints for network connectivity')
param usePrivateEndpoint bool = false

@description('Use a P2S VPN Gateway for secure access to the private endpoints')
param useVpnGateway bool = false

@description('Id of the user or app to assign application roles')
param principalId string = ''

@description('Use Application Insights for monitoring and performance tracing')
param useApplicationInsights bool = false

@description('Show options to use vector embeddings for searching in the app UI')
param useVectors bool = false
@description('Use Built-in integrated Vectorization feature of AI Search to vectorize and ingest documents')
param useIntegratedVectorization bool = false

@description('Use media description feature with Azure Content Understanding during ingestion')
param useMediaDescriberAzureCU bool = true

param useLocalPdfParser bool = false
param useLocalHtmlParser bool = false

var abbrs = loadJsonContent('abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Issuer used for the Entra ID app registrations securing the cloud-ingestion custom skill
// endpoints (see infra/app/functions.bicep) - unrelated to any end-user login flow.
var authenticationIssuerUri = '${environment().authentication.loginEndpoint}${tenantId}/v2.0'

@description('Whether the deployment is running on GitHub Actions')
param runningOnGh string = ''

@description('Whether the deployment is running on Azure DevOps Pipeline')
param runningOnAdo string = ''

// Organize resources in a resource group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${resourceNamePrefix}-${environmentName}'
  location: location
  tags: tags
}

// Name of the resource group hosting each service; falls back to the main resource
// group when the *ResourceGroupName param is empty.
// Kept as plain string vars (used via `scope: az.resourceGroup(<name>)`) rather than
// `existing` resourceGroups resources, which would collide with the main resource group
// under Bicep languageVersion 2.0. See #3146.
var openAiResourceGroupNameActual = !empty(openAiResourceGroupName) ? openAiResourceGroupName : resourceGroup.name
var documentIntelligenceResourceGroupNameActual = !empty(documentIntelligenceResourceGroupName)
  ? documentIntelligenceResourceGroupName
  : resourceGroup.name
var visionResourceGroupNameActual = !empty(visionResourceGroupName) ? visionResourceGroupName : resourceGroup.name
var contentUnderstandingResourceGroupNameActual = !empty(contentUnderstandingResourceGroupName)
  ? contentUnderstandingResourceGroupName
  : resourceGroup.name
var searchServiceResourceGroupNameActual = !empty(searchServiceResourceGroupName)
  ? searchServiceResourceGroupName
  : resourceGroup.name
var storageResourceGroupNameActual = !empty(storageResourceGroupName) ? storageResourceGroupName : resourceGroup.name
// ADLS resource group - defaults to main resource group if not specified
var adlsStorageResourceGroupNameActual = !empty(adlsStorageResourceGroupName)
  ? adlsStorageResourceGroupName
  : resourceGroup.name

// Monitor application with Azure Monitor
module monitoring 'core/monitor/monitoring.bicep' = if (useApplicationInsights) {
  name: 'monitoring'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    applicationInsightsName: !empty(applicationInsightsName)
      ? applicationInsightsName
      : '${abbrs.insightsComponents}${resourceNamePrefix}-ingestion-monitoring-${resourceToken}'
    logAnalyticsName: !empty(logAnalyticsName)
      ? logAnalyticsName
      : '${abbrs.operationalInsightsWorkspaces}${resourceNamePrefix}-ingestion-monitoring-${resourceToken}'
    publicNetworkAccess: publicNetworkAccess
  }
}

module applicationInsightsDashboard 'backend-dashboard.bicep' = if (useApplicationInsights) {
  name: 'application-insights-dashboard'
  scope: resourceGroup
  params: {
    name: !empty(applicationInsightsDashboardName)
      ? applicationInsightsDashboardName
      : '${abbrs.portalDashboards}${resourceNamePrefix}-ingestion-monitoring-${resourceToken}'
    location: location
    applicationInsightsName: useApplicationInsights ? monitoring!.outputs.applicationInsightsName : ''
  }
}

// Determine which ADLS storage account name to use (existing or provisioned)
var adlsStorageAccountNameResolved = useExistingAdlsStorage ? existingAdlsStorage.name : (useCloudIngestionAcls ? adlsStorage!.outputs.name : '')

// For cloud ingestion with ACLs, use the ADLS Gen2 storage account; otherwise use the standard storage account
var cloudIngestionStorageAccount = useCloudIngestionAcls ? adlsStorageAccountNameResolved : storage.outputs.name

// Shared app settings consumed by the cloud-ingestion Function Apps (infra/app/functions.bicep)
var appEnvVariables = {
  AZURE_STORAGE_ACCOUNT: storage.outputs.name
  AZURE_STORAGE_CONTAINER: storageContainerName
  AZURE_STORAGE_RESOURCE_GROUP: storageResourceGroupNameActual
  // Cloud ingestion uses ADLS Gen2 storage when ACLs are enabled for manual ACL extraction
  AZURE_CLOUD_INGESTION_STORAGE_ACCOUNT: cloudIngestionStorageAccount
  USE_CLOUD_INGESTION_ACLS: string(useCloudIngestionAcls)
  AZURE_SUBSCRIPTION_ID: subscription().subscriptionId
  AZURE_SEARCH_INDEX: searchIndexName
  AZURE_SEARCH_SERVICE: searchService.outputs.name
  AZURE_SEARCH_SEMANTIC_RANKER: actualSearchServiceSemanticRankerLevel
  AZURE_SEARCH_QUERY_REWRITING: searchServiceQueryRewriting
  AZURE_VISION_ENDPOINT: useMultimodal ? vision!.outputs.endpoint : ''
  AZURE_SEARCH_QUERY_LANGUAGE: searchQueryLanguage
  AZURE_SEARCH_QUERY_SPELLER: searchQuerySpeller
  AZURE_SEARCH_FIELD_NAME_EMBEDDING: searchFieldNameEmbedding
  APPLICATIONINSIGHTS_CONNECTION_STRING: useApplicationInsights
    ? monitoring!.outputs.applicationInsightsConnectionString
    : ''
  // Shared by all OpenAI deployments
  OPENAI_HOST: openAiHost
  AZURE_OPENAI_EMB_MODEL_NAME: embedding.modelName
  AZURE_OPENAI_EMB_DIMENSIONS: embedding.dimensions
  // Vision-capable model used by the figure-processor skill to describe images/figures during ingestion
  AZURE_OPENAI_CHATGPT_MODEL: chatGpt.modelName
  // Specific to Azure OpenAI
  AZURE_OPENAI_SERVICE: deployFoundryAccount ? foundryAccount!.outputs.name : ''
  AZURE_OPENAI_CHATGPT_DEPLOYMENT: chatGpt.deploymentName
  AZURE_OPENAI_EMB_DEPLOYMENT: embedding.deploymentName
  AZURE_OPENAI_API_KEY_OVERRIDE: azureOpenAiApiKey
  AZURE_OPENAI_CUSTOM_URL: azureOpenAiCustomUrl
  // Used only with non-Azure OpenAI deployments
  OPENAI_API_KEY: openAiApiKey
  OPENAI_ORGANIZATION: openAiApiOrganization
  // Optional document-level access control system applied during ingestion
  AZURE_USE_AUTHENTICATION: useAuthentication
  AZURE_ENFORCE_ACCESS_CONTROL: enforceAccessControl
  AZURE_ENABLE_GLOBAL_DOCUMENT_ACCESS: enableGlobalDocuments
  AZURE_TENANT_ID: tenantId
  USE_VECTORS: useVectors
  USE_MULTIMODAL: useMultimodal
  CSV_MAX_PAGE_CHARS: string(csvMaxPageChars)
  AZURE_IMAGESTORAGE_CONTAINER: useMultimodal ? imageStorageContainerName : ''
  AZURE_DOCUMENTINTELLIGENCE_SERVICE: documentIntelligence.outputs.name
  USE_LOCAL_PDF_PARSER: useLocalPdfParser
  USE_LOCAL_HTML_PARSER: useLocalHtmlParser
  USE_MEDIA_DESCRIBER_AZURE_CU: useMediaDescriberAzureCU
  AZURE_CONTENTUNDERSTANDING_ENDPOINT: useMediaDescriberAzureCU ? contentUnderstanding!.outputs.endpoint : ''
}

// Optional Azure Functions for document ingestion and processing
module functions 'app/functions.bicep' = if (useCloudIngestion) {
  name: 'functions'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    resourceNamePrefix: resourceNamePrefix
    applicationInsightsName: useApplicationInsights ? monitoring!.outputs.applicationInsightsName : ''
    storageResourceGroupName: storageResourceGroupNameActual
    searchServiceResourceGroupName: searchServiceResourceGroupNameActual
    openAiResourceGroupName: openAiResourceGroupNameActual
    documentIntelligenceResourceGroupName: documentIntelligenceResourceGroupNameActual
    visionServiceName: useMultimodal ? vision!.outputs.name : ''
    visionResourceGroupName: useMultimodal ? visionResourceGroupNameActual : resourceGroup.name
    contentUnderstandingServiceName: useMediaDescriberAzureCU ? contentUnderstanding!.outputs.name : ''
    contentUnderstandingResourceGroupName: useMediaDescriberAzureCU ? contentUnderstandingResourceGroupNameActual : resourceGroup.name
    documentExtractorName: '${abbrs.webSitesFunctions}${resourceNamePrefix}-document-extractor-${resourceToken}'
    figureProcessorName: '${abbrs.webSitesFunctions}${resourceNamePrefix}-figure-processor-${resourceToken}'
    textProcessorName: '${abbrs.webSitesFunctions}${resourceNamePrefix}-text-processor-${resourceToken}'
    openIdIssuer: authenticationIssuerUri
    appEnvVariables: appEnvVariables
    searchUserAssignedIdentityClientId: searchService.outputs.userAssignedIdentityClientId
  }
}

// Optional Logic App that syncs a SharePoint Online document library into the cloud-ingestion
// Blob container, reusing the functions-based skillset above for parsing/chunking/embeddings.
module sharePointIngestion 'app/logicapp-sharepoint-ingestion.bicep' = if (useSharePointLogicApp && useCloudIngestion) {
  name: 'sharepoint-ingestion'
  scope: resourceGroup
  params: {
    logicAppName: '${abbrs.logicWorkflows}${resourceNamePrefix}-sharepoint-document-sync-${resourceToken}'
    location: location
    tags: tags
    storageAccountName: cloudIngestionStorageAccount
    storageResourceGroupName: storageResourceGroupNameActual
    storageContainerName: storageContainerName
    searchServiceName: searchService.outputs.name
    searchServiceResourceGroupName: searchServiceResourceGroupNameActual
    indexerName: '${searchIndexName}-cloud-indexer'
    sharePointHostname: sharePointHostname
    sharePointSitePath: sharePointSitePath
    sharePointFolderPath: sharePointFolderPath
    recurrenceIntervalMinutes: sharePointSyncIntervalMinutes
    notificationWebhookUrl: sharePointNotificationWebhookUrl
  }
}

var defaultOpenAiDeployments = [
  {
    name: chatGpt.deploymentName
    model: {
      format: 'OpenAI'
      name: chatGpt.modelName
      version: chatGpt.deploymentVersion
    }
    sku: {
      name: chatGpt.deploymentSkuName
      capacity: chatGpt.deploymentCapacity
    }
  }
  {
    name: embedding.deploymentName
    model: {
      format: 'OpenAI'
      name: embedding.modelName
      version: embedding.deploymentVersion
    }
    sku: {
      name: embedding.deploymentSkuName
      capacity: embedding.deploymentCapacity
    }
  }
]

var openAiDeployments = concat(
  defaultOpenAiDeployments,
  useEval
    ? [
      {
        name: eval.deploymentName
        model: {
          format: 'OpenAI'
          name: eval.modelName
          version: eval.deploymentVersion
        }
        sku: {
          name: eval.deploymentSkuName
          capacity: eval.deploymentCapacity
        }
      }
    ] : []
)

// Provision a Foundry account + project only when we own the account (deployFoundryAccount):
//   - openAiHost == 'azure': create a Microsoft Foundry account (AIServices + project
//     management) hosting the models, plus a Foundry project. A set openAiServiceName (reused
//     from a prior output or user-chosen) is reused idempotently so redeploys stay stable.
//   - openAiHost == 'azure_custom' (or non-azure): bring-your-own — account, deployments,
//     project, private endpoint, and role assignments are all skipped; the backend uses
//     AZURE_OPENAI_CUSTOM_URL and you manage everything.
// openAiServiceName can't signal bring-your-own: AZURE_OPENAI_SERVICE is also an output azd
// writes back after every deploy, so it's set on redeploys of our own account too. openAiHost
// is the intent signal.
var deployFoundryAccount = isAzureOpenAiHost && deployAzureOpenAi

// Microsoft Foundry account (AIServices) with project management enabled, so the model
// deployments are hosted on the account and a Foundry project can be created inside it.
module foundryAccount 'br/public:avm/res/cognitive-services/account:0.15.0' = if (deployFoundryAccount) {
  name: 'foundry-account'
  scope: az.resourceGroup(openAiResourceGroupNameActual)
  params: {
    name: !empty(openAiServiceName) ? openAiServiceName : '${abbrs.cognitiveServicesAccounts}${resourceNamePrefix}-embeddings-and-vision-${resourceToken}'
    location: openAiLocation
    tags: tags
    kind: 'AIServices'
    allowProjectManagement: true
    customSubDomainName: !empty(openAiServiceName) ? openAiServiceName : '${abbrs.cognitiveServicesAccounts}${resourceNamePrefix}-embeddings-and-vision-${resourceToken}'
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      defaultAction: 'Allow'
      bypass: bypass
    }
    sku: openAiSkuName
    deployments: openAiDeployments
    disableLocalAuth: azureOpenAiDisableKeys
    restore: restoreCognitiveServices
  }
}

// Microsoft Foundry project, hosted inside the Foundry (AIServices) account above.
// A project is required to open the account in the Microsoft Foundry portal and to use
// the Foundry / Agents SDKs against FOUNDRY_PROJECT_ENDPOINT.
var foundryProjectNameResolved = !empty(foundryProjectName) ? foundryProjectName : 'proj-${resourceToken}'

var foundryProjectRoleAssignments = empty(principalId)
  ? []
  : [
      {
        principalId: principalId
        roleDefinitionId: 'eadc314b-1a2d-4efa-be10-5d325db5065e' // Azure AI Project Manager
        principalType: principalType
      }
    ]

module foundryProject 'core/ai/ai-foundry-project.bicep' = if (deployFoundryAccount) {
  name: 'foundry-project'
  scope: az.resourceGroup(openAiResourceGroupNameActual)
  params: {
    accountName: foundryAccount!.outputs.name
    projectName: foundryProjectNameResolved
    location: openAiLocation
    tags: tags
    roleAssignments: foundryProjectRoleAssignments
  }
}
// Formerly known as Form Recognizer
// Does not support bypass
module documentIntelligence 'br/public:avm/res/cognitive-services/account:0.7.2' = {
  name: 'documentintelligence'
  scope: az.resourceGroup(documentIntelligenceResourceGroupNameActual)
  params: {
    name: !empty(documentIntelligenceServiceName)
      ? documentIntelligenceServiceName
      : '${abbrs.cognitiveServicesDocumentIntelligence}${resourceNamePrefix}-document-layout-${resourceToken}'
    kind: 'FormRecognizer'
    customSubDomainName: !empty(documentIntelligenceServiceName)
      ? documentIntelligenceServiceName
      : '${abbrs.cognitiveServicesDocumentIntelligence}${resourceNamePrefix}-document-layout-${resourceToken}'
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      defaultAction: 'Allow'
    }
    location: documentIntelligenceResourceGroupLocation
    disableLocalAuth: true
    tags: tags
    sku: documentIntelligenceSkuName
    restore: restoreCognitiveServices
  }
}

module vision 'br/public:avm/res/cognitive-services/account:0.7.2' = if (useMultimodal) {
  name: 'vision'
  scope: az.resourceGroup(visionResourceGroupNameActual)
  params: {
    name: !empty(visionServiceName)
      ? visionServiceName
      : '${abbrs.cognitiveServicesVision}${resourceNamePrefix}-image-embeddings-${resourceToken}'
    kind: 'CognitiveServices'
    networkAcls: {
      defaultAction: 'Allow'
    }
    customSubDomainName: !empty(visionServiceName)
      ? visionServiceName
      : '${abbrs.cognitiveServicesVision}${resourceNamePrefix}-image-embeddings-${resourceToken}'
    location: visionResourceGroupLocation
    tags: tags
    sku: 'S0'
    restore: restoreCognitiveServices
  }
}


module contentUnderstanding 'br/public:avm/res/cognitive-services/account:0.7.2' = if (useMediaDescriberAzureCU) {
  name: 'content-understanding'
  scope: az.resourceGroup(contentUnderstandingResourceGroupNameActual)
  params: {
    name: !empty(contentUnderstandingServiceName)
      ? contentUnderstandingServiceName
      : '${abbrs.cognitiveServicesContentUnderstanding}${resourceNamePrefix}-media-description-${resourceToken}'
    kind: 'AIServices'
    networkAcls: {
      defaultAction: 'Allow'
    }
    customSubDomainName: !empty(contentUnderstandingServiceName)
      ? contentUnderstandingServiceName
      : '${abbrs.cognitiveServicesContentUnderstanding}${resourceNamePrefix}-media-description-${resourceToken}'
    // Hard-coding to westus for now, due to limited availability and no overlap with Document Intelligence
    location: 'westus'
    tags: tags
    sku: 'S0'
    restore: restoreCognitiveServices
  }
}

module searchService 'core/search/search-services.bicep' = {
  name: 'search-service'
  scope: az.resourceGroup(searchServiceResourceGroupNameActual)
  params: {
    name: !empty(searchServiceName)
      ? searchServiceName
      : 'srch-${resourceNamePrefix}-document-search-${resourceToken}'
    location: !empty(searchServiceLocation) ? searchServiceLocation : location
    tags: tags
    disableLocalAuth: true
    sku: {
      name: searchServiceSkuName
    }
    semanticSearch: actualSearchServiceSemanticRankerLevel
    publicNetworkAccess: publicNetworkAccess == 'Enabled'
      ? 'enabled'
      : (publicNetworkAccess == 'Disabled' ? 'disabled' : null)
    sharedPrivateLinkStorageAccounts: (usePrivateEndpoint && useIntegratedVectorization) ? [storage.outputs.id] : []
  }
}

module searchDiagnostics 'core/search/search-diagnostics.bicep' = if (useApplicationInsights) {
  name: 'search-diagnostics'
  scope: az.resourceGroup(searchServiceResourceGroupNameActual)
  params: {
    searchServiceName: searchService.outputs.name
    workspaceId: useApplicationInsights ? monitoring!.outputs.logAnalyticsWorkspaceId : ''
  }
}

module storage 'core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: az.resourceGroup(storageResourceGroupNameActual)
  params: {
    name: !empty(storageAccountName)
      ? storageAccountName
      : '${abbrs.storageStorageAccounts}${resourceNamePrefix}content${take(resourceToken, 12)}'
    location: storageResourceGroupLocation
    tags: tags
    publicNetworkAccess: publicNetworkAccess
    bypass: bypass
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    sku: {
      name: storageSkuName
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 2
    }
    containers: [
      {
        name: storageContainerName
        publicAccess: 'None'
      }
      {
        name: imageStorageContainerName
        publicAccess: 'None'
      }
    ]
  }
}

// Reference existing ADLS Gen2 storage account when bringing your own
resource existingAdlsStorage 'Microsoft.Storage/storageAccounts@2023-05-01' existing = if (useExistingAdlsStorage && !empty(adlsStorageAccountName)) {
  name: adlsStorageAccountName
  scope: az.resourceGroup(adlsStorageResourceGroupNameActual)
}

// ADLS Gen2 storage account for cloud ingestion with ACL support
// Only provision if using cloud ingestion ACLs AND not using an existing ADLS account
module adlsStorage 'core/storage/storage-account.bicep' = if (useCloudIngestionAcls && !useExistingAdlsStorage) {
  name: 'adls-storage'
  scope: az.resourceGroup(storageResourceGroupNameActual)
  params: {
    name: '${abbrs.storageStorageAccounts}${resourceNamePrefix}aclcontent${take(resourceToken, 9)}'
    location: storageResourceGroupLocation
    tags: tags
    publicNetworkAccess: publicNetworkAccess
    bypass: bypass
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    isHnsEnabled: true
    sku: {
      name: storageSkuName
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 2
    }
    containers: [
      {
        name: storageContainerName
        publicAccess: 'None'
      }
    ]
  }
}

// USER ROLES
var principalType = empty(runningOnGh) && empty(runningOnAdo) ? 'User' : 'ServicePrincipal'

module openAiRoleUser 'core/security/role.bicep' = if (isAzureOpenAiHost && deployAzureOpenAi) {
  scope: az.resourceGroup(openAiResourceGroupNameActual)
  name: 'openai-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: principalType
  }
}

// For both Document Intelligence and AI vision
module cognitiveServicesRoleUser 'core/security/role.bicep' = {
  scope: resourceGroup
  name: 'cognitiveservices-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: 'a97b65f3-24c7-4388-baec-2e87135dc908'
    principalType: principalType
  }
}

module storageRoleUser 'core/security/role.bicep' = {
  scope: az.resourceGroup(storageResourceGroupNameActual)
  name: 'storage-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1' // Storage Blob Data Reader
    principalType: principalType
  }
}

module storageContribRoleUser 'core/security/role.bicep' = {
  scope: az.resourceGroup(storageResourceGroupNameActual)
  name: 'storage-contrib-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
    principalType: principalType
  }
}

module searchRoleUser 'core/security/role.bicep' = {
  scope: az.resourceGroup(searchServiceResourceGroupNameActual)
  name: 'search-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '1407120a-92aa-4202-b7e9-c0e197c71c8f' // Search Index Data Reader
    principalType: principalType
  }
}

module searchContribRoleUser 'core/security/role.bicep' = {
  scope: az.resourceGroup(searchServiceResourceGroupNameActual)
  name: 'search-contrib-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '8ebe5a00-799e-43f5-93ac-243d3dce84a7' // Search Index Data Contributor
    principalType: principalType
  }
}

module searchSvcContribRoleUser 'core/security/role.bicep' = {
  scope: az.resourceGroup(searchServiceResourceGroupNameActual)
  name: 'search-svccontrib-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '7ca78c08-252a-4471-8644-bb5ff32d4ba0' // Search Service Contributor
    principalType: principalType
  }
}

module openAiRoleSearchService 'core/security/role.bicep' = if (isAzureOpenAiHost && deployAzureOpenAi && searchServiceSkuName != 'free') {
  scope: az.resourceGroup(openAiResourceGroupNameActual)
  name: 'openai-role-searchservice'
  params: {
    principalId: searchService.outputs.systemAssignedPrincipalId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: 'ServicePrincipal'
  }
}

module visionRoleSearchService 'core/security/role.bicep' = if (useMultimodal && searchServiceSkuName != 'free') {
  scope: az.resourceGroup(visionResourceGroupNameActual)
  name: 'vision-role-searchservice'
  params: {
    principalId: searchService.outputs.systemAssignedPrincipalId
    roleDefinitionId: 'a97b65f3-24c7-4388-baec-2e87135dc908'
    principalType: 'ServicePrincipal'
  }
}

// Search service needs blob read access for both integrated vectorization and cloud ingestion indexer data source
module storageRoleSearchService 'core/security/role.bicep' = if ((useIntegratedVectorization || useCloudIngestion) && searchServiceSkuName != 'free') {
  scope: az.resourceGroup(storageResourceGroupNameActual)
  name: 'storage-role-searchservice'
  params: {
    principalId: searchService.outputs.systemAssignedPrincipalId
    roleDefinitionId: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1' // Storage Blob Data Reader
    principalType: 'ServicePrincipal'
  }
}

module storageRoleContributorSearchService 'core/security/role.bicep' = if ((useIntegratedVectorization && useMultimodal) && searchServiceSkuName != 'free') {
  scope: az.resourceGroup(storageResourceGroupNameActual)
  name: 'storage-role-contributor-searchservice'
  params: {
    principalId: searchService.outputs.systemAssignedPrincipalId
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
    principalType: 'ServicePrincipal'
  }
}

// ADLS Gen2 storage role assignments for cloud ingestion with ACLs
// These are scoped to the ADLS storage account itself, so they work for both
// provisioned and bring-your-own (BYO) ADLS storage accounts
module adlsStorageRoleSearchService 'core/security/storage-role.bicep' = if (useCloudIngestionAcls && searchServiceSkuName != 'free') {
  scope: az.resourceGroup(adlsStorageResourceGroupNameActual)
  name: 'adls-storage-role-searchservice'
  params: {
    storageAccountName: adlsStorageAccountNameResolved
    principalId: searchService.outputs.systemAssignedPrincipalId
    roleDefinitionId: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1' // Storage Blob Data Reader
    principalType: 'ServicePrincipal'
  }
}

// Storage Blob Data Owner on ADLS storage for user to manage ACLs
module adlsStorageOwnerRoleUser 'core/security/storage-role.bicep' = if (useCloudIngestionAcls) {
  scope: az.resourceGroup(adlsStorageResourceGroupNameActual)
  name: 'adls-storage-owner-role-user'
  params: {
    storageAccountName: adlsStorageAccountNameResolved
    principalId: principalId
    roleDefinitionId: 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b' // Storage Blob Data Owner
    principalType: principalType
  }
}

// Storage Blob Data Reader on ADLS storage for Azure Functions to read during cloud ingestion
// Note: This module requires useCloudIngestion=true because it references functions!.outputs.principalId.
// If useCloudIngestionAcls=true but useCloudIngestion=false, deployment will fail.
// Documentation states USE_CLOUD_INGESTION_ACLS requires USE_CLOUD_INGESTION to be true.
module adlsStorageRoleFunctions 'core/security/storage-role.bicep' = if (useCloudIngestionAcls && useCloudIngestion) {
  scope: az.resourceGroup(adlsStorageResourceGroupNameActual)
  name: 'adls-storage-role-functions'
  params: {
    storageAccountName: adlsStorageAccountNameResolved
    principalId: functions!.outputs.principalId
    roleDefinitionId: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1' // Storage Blob Data Reader
    principalType: 'ServicePrincipal'
  }
}

module isolation 'network-isolation.bicep' = if (usePrivateEndpoint) {
  name: 'networks'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    vnetName: '${abbrs.virtualNetworks}${resourceNamePrefix}-ingestion-${resourceToken}'
    useVpnGateway: useVpnGateway
    vpnGatewayName: useVpnGateway ? '${abbrs.networkVpnGateways}${resourceNamePrefix}-ingestion-${resourceToken}' : ''
    dnsResolverName: useVpnGateway ? '${abbrs.privateDnsResolver}${resourceNamePrefix}-ingestion-${resourceToken}' : ''
  }
}

var environmentData = environment()

var openAiPrivateEndpointConnection = (usePrivateEndpoint && deployFoundryAccount)
  ? [
      {
        groupId: 'account'
        // Microsoft Foundry (AIServices) accounts resolve the services.ai.azure.com zone in
        // addition to openai.azure.com and cognitiveservices.azure.com.
        // https://learn.microsoft.com/azure/private-link/private-endpoint-dns#ai--machine-learning
        dnsZoneNames: [
          'privatelink.services.ai.azure.com'
          'privatelink.openai.azure.com'
          'privatelink.cognitiveservices.azure.com'
        ]
        resourceIds: [foundryAccount!.outputs.resourceId]
      }
    ]
  : []

var cognitiveServicesPrivateEndpointConnection = (usePrivateEndpoint && (!useLocalPdfParser || useMultimodal || useMediaDescriberAzureCU))
  ? [
      {
        groupId: 'account'
        dnsZoneNames: ['privatelink.cognitiveservices.azure.com']
        // Only include generic Cognitive Services-based resources (Form Recognizer / Vision / Content Understanding)
        // Azure OpenAI uses its own privatelink.openai.azure.com zone and already has a separate private endpoint above.
        resourceIds: concat(
          !useLocalPdfParser ? [documentIntelligence.outputs.resourceId] : [],
          useMultimodal ? [vision!.outputs.resourceId] : [],
          useMediaDescriberAzureCU ? [contentUnderstanding!.outputs.resourceId] : []
        )
      }
    ]
  : []

var otherPrivateEndpointConnections = (usePrivateEndpoint)
  ? [
      {
        groupId: 'blob'
        dnsZoneNames: ['privatelink.blob.${environmentData.suffixes.storage}']
        resourceIds: [storage.outputs.id]
      }
      {
        groupId: 'searchService'
        dnsZoneNames: ['privatelink.search.windows.net']
        resourceIds: [searchService.outputs.id]
      }
    ]
  : []

var privateEndpointConnections = concat(otherPrivateEndpointConnections, openAiPrivateEndpointConnection, cognitiveServicesPrivateEndpointConnection)

module privateEndpoints 'private-endpoints.bicep' = if (usePrivateEndpoint) {
  name: 'privateEndpoints'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    resourceToken: resourceToken
    privateEndpointConnections: privateEndpointConnections
    applicationInsightsId: useApplicationInsights ? monitoring!.outputs.applicationInsightsId : ''
    logAnalyticsWorkspaceId: useApplicationInsights ? monitoring!.outputs.logAnalyticsWorkspaceId : ''
    vnetName: isolation!.outputs.vnetName
    vnetPeSubnetId: isolation!.outputs.backendSubnetId
  }
  // Wait for the Foundry project to be created before creating the account private endpoint.
  // The account PUT returns before it is fully provisioned; project creation is the convergence
  // point that avoids AccountProvisioningStateInvalid errors on the private endpoint.
  dependsOn: [foundryProject]
}

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenantId
output AZURE_RESOURCE_GROUP string = resourceGroup.name

// Shared by all OpenAI deployments
output OPENAI_HOST string = openAiHost
output AZURE_OPENAI_EMB_MODEL_NAME string = embedding.modelName
output AZURE_OPENAI_EMB_DIMENSIONS int = embedding.dimensions
output AZURE_OPENAI_CHATGPT_MODEL string = chatGpt.modelName

// Specific to Azure OpenAI
output AZURE_OPENAI_SERVICE string = deployFoundryAccount ? foundryAccount!.outputs.name : ''
output AZURE_OPENAI_ENDPOINT string = deployFoundryAccount ? foundryAccount!.outputs.endpoint : ''
output AZURE_OPENAI_RESOURCE_GROUP string = isAzureOpenAiHost ? openAiResourceGroupNameActual : ''

// Microsoft Foundry project hosted inside the Foundry (AIServices) account above.
output FOUNDRY_PROJECT_NAME string = deployFoundryAccount ? foundryProject!.outputs.name : ''
output FOUNDRY_PROJECT_ENDPOINT string = deployFoundryAccount ? foundryProject!.outputs.endpoint : ''

output AZURE_OPENAI_CHATGPT_DEPLOYMENT string = isAzureOpenAiHost ? chatGpt.deploymentName : ''
output AZURE_OPENAI_CHATGPT_DEPLOYMENT_VERSION string = isAzureOpenAiHost ? chatGpt.deploymentVersion : ''
output AZURE_OPENAI_CHATGPT_DEPLOYMENT_SKU string = isAzureOpenAiHost ? chatGpt.deploymentSkuName : ''
output AZURE_OPENAI_EMB_DEPLOYMENT string = isAzureOpenAiHost ? embedding.deploymentName : ''
output AZURE_OPENAI_EMB_DEPLOYMENT_VERSION string = isAzureOpenAiHost ? embedding.deploymentVersion : ''
output AZURE_OPENAI_EMB_DEPLOYMENT_SKU string = isAzureOpenAiHost ? embedding.deploymentSkuName : ''
output AZURE_OPENAI_EVAL_DEPLOYMENT string = isAzureOpenAiHost && useEval ? eval.deploymentName : ''
output AZURE_OPENAI_EVAL_DEPLOYMENT_SKU string = isAzureOpenAiHost && useEval ? eval.deploymentSkuName : ''
output AZURE_OPENAI_EVAL_MODEL string = isAzureOpenAiHost && useEval ? eval.modelName : ''

output AZURE_VISION_ENDPOINT string = useMultimodal ? vision!.outputs.endpoint : ''
output AZURE_CONTENTUNDERSTANDING_ENDPOINT string = useMediaDescriberAzureCU ? contentUnderstanding!.outputs.endpoint : ''

output AZURE_DOCUMENTINTELLIGENCE_SERVICE string = documentIntelligence.outputs.name
output AZURE_DOCUMENTINTELLIGENCE_RESOURCE_GROUP string = documentIntelligenceResourceGroupNameActual

output AZURE_SEARCH_INDEX string = searchIndexName
output AZURE_SEARCH_SERVICE string = searchService.outputs.name
output AZURE_SEARCH_SERVICE_RESOURCE_GROUP string = searchServiceResourceGroupNameActual
output AZURE_SEARCH_SEMANTIC_RANKER string = actualSearchServiceSemanticRankerLevel
output AZURE_SEARCH_FIELD_NAME_EMBEDDING string = searchFieldNameEmbedding
output AZURE_SEARCH_USER_ASSIGNED_IDENTITY_RESOURCE_ID string = searchService.outputs.userAssignedIdentityResourceId

output AZURE_STORAGE_ACCOUNT string = storage.outputs.name
output AZURE_STORAGE_CONTAINER string = storageContainerName
output AZURE_STORAGE_RESOURCE_GROUP string = storageResourceGroupNameActual

output AZURE_ADLS_STORAGE_ACCOUNT string = useCloudIngestionAcls ? adlsStorageAccountNameResolved : ''
output AZURE_CLOUD_INGESTION_STORAGE_ACCOUNT string = useCloudIngestionAcls ? adlsStorageAccountNameResolved : storage.outputs.name
output AZURE_CLOUD_INGESTION_STORAGE_RESOURCE_GROUP string = useCloudIngestionAcls ? adlsStorageResourceGroupNameActual : storageResourceGroupNameActual
output USE_CLOUD_INGESTION_ACLS bool = useCloudIngestionAcls

output AZURE_IMAGESTORAGE_CONTAINER string = useMultimodal ? imageStorageContainerName : ''

// Cloud ingestion function skill endpoints & resource IDs
output DOCUMENT_EXTRACTOR_SKILL_ENDPOINT string = useCloudIngestion ? 'https://${functions!.outputs.documentExtractorUrl}/api/extract' : ''
output FIGURE_PROCESSOR_SKILL_ENDPOINT string = useCloudIngestion ? 'https://${functions!.outputs.figureProcessorUrl}/api/process' : ''
output TEXT_PROCESSOR_SKILL_ENDPOINT string = useCloudIngestion ? 'https://${functions!.outputs.textProcessorUrl}/api/process' : ''
// Identifier URI used as authResourceId for all custom skill endpoints
output DOCUMENT_EXTRACTOR_SKILL_AUTH_RESOURCE_ID string = useCloudIngestion ? functions!.outputs.documentExtractorAuthIdentifierUri : ''
output FIGURE_PROCESSOR_SKILL_AUTH_RESOURCE_ID string = useCloudIngestion ? functions!.outputs.figureProcessorAuthIdentifierUri : ''
output TEXT_PROCESSOR_SKILL_AUTH_RESOURCE_ID string = useCloudIngestion ? functions!.outputs.textProcessorAuthIdentifierUri : ''

output AZURE_USE_AUTHENTICATION bool = useAuthentication

output SHAREPOINT_LOGIC_APP_NAME string = (useSharePointLogicApp && useCloudIngestion) ? sharePointIngestion!.outputs.logicAppName : ''

output AZURE_VPN_CONFIG_DOWNLOAD_LINK string = useVpnGateway ? 'https://portal.azure.com/#@${tenant().tenantId}/resource${isolation!.outputs.virtualNetworkGatewayId}/pointtositeconfiguration' : ''
