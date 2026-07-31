// Consumption Logic App that mirrors documents from a SharePoint Online document library into
// the Blob Storage container used by the cloud-ingestion pipeline (see prepdocslib/cloudingestionstrategy.py),
// so the existing Blob -> indexer -> custom-skill pipeline (document_extractor / figure_processor /
// text_processor) picks them up and indexes them for Copilot Studio, with no changes to that pipeline.
//
// Deliberately built on plain Microsoft Graph / Storage / Search REST calls authenticated with the
// Logic App's own system-assigned managed identity, instead of the SharePoint Online "API connection"
// connector. That keeps the whole workflow expressible as ordinary HTTP actions (reviewable, versionable,
// no per-user OAuth connection to reauthorize), at the cost of one manual one-time step after deploy:
// an admin must grant the Logic App's managed identity the Microsoft Graph application permission
// `Sites.Selected` (least privilege - then grant it access to just this site) or `Sites.Read.All`.
// See docs/copilot_studio_integration.md for that step.

@description('Name of the Logic App workflow')
param logicAppName string

param location string = resourceGroup().location
param tags object = {}

@description('Storage account backing the cloud-ingestion Blob container (see AZURE_CLOUD_INGESTION_STORAGE_ACCOUNT)')
param storageAccountName string
param storageResourceGroupName string = resourceGroup().name
@description('Blob container that the cloud-ingestion indexer reads from (see AZURE_STORAGE_CONTAINER)')
param storageContainerName string

param searchServiceName string
param searchServiceResourceGroupName string = resourceGroup().name
@description('Name of the cloud-ingestion indexer to run after each sync (searchIndexName-cloud-indexer, see cloudingestionstrategy.py)')
param indexerName string

@description('SharePoint Online tenant hostname, e.g. contoso.sharepoint.com')
param sharePointHostname string
@description('Server-relative site path, e.g. /sites/Marketing')
param sharePointSitePath string
@description('Optional folder path within the site drive to restrict syncing to (e.g. /Shared Documents/Policies). Empty means the whole default document library.')
param sharePointFolderPath string = ''

@description('How often to poll SharePoint for changes, in minutes')
@minValue(5)
param recurrenceIntervalMinutes int = 15

@description('Optional webhook URL (Teams incoming webhook or similar) notified on ingestion or indexer-run failures')
@secure()
param notificationWebhookUrl string = ''

@description('Lowercase extensions (with leading dot) that the ingestion pipeline knows how to parse - must match build_file_processors() in prepdocslib/servicesetup.py')
param supportedExtensions array = ['.pdf', '.docx', '.pptx', '.xlsx', '.png', '.jpg', '.jpeg', '.html', '.json', '.csv', '.txt', '.md']

var supportedExtensionsCsv = join(supportedExtensions, ',')
var q = '\'' // single quote, used to build OData literal keys ("PartitionKey='x'") without fighting Bicep's own quoting
var stateTableName = 'sharepointsyncstate'
var errorsTableName = 'sharepointingestionerrors'
var storageSuffix = environment().suffixes.storage
var tableEndpoint = 'https://${storageAccountName}.table.${storageSuffix}'
var blobEndpoint = 'https://${storageAccountName}.blob.${storageSuffix}'
var searchEndpoint = 'https://${searchServiceName}.search.windows.net'
// Folder scoping is a deploy-time choice (the param is known at compile time), so branch here
// rather than with a runtime expression inside the workflow definition.
var initialDeltaUrlSuffix = empty(sharePointFolderPath) ? '/drive/root/delta' : '/drive/root:${sharePointFolderPath}:/delta'

// The sync-state and error tables live in the ingestion storage account, which may sit in a
// different resource group. Child resources can't be declared under a cross-scope `existing`
// parent (BCP165), so they are created through a module targeting that resource group.
module storageTables 'storage-tables.bicep' = {
  name: 'sp-logicapp-tables-${uniqueString(logicAppName)}'
  scope: resourceGroup(storageResourceGroupName)
  params: {
    storageAccountName: storageAccountName
    tableNames: [stateTableName, errorsTableName]
  }
}

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // Deploy the workflow disabled until a SharePoint site is configured, so `azd up` always
    // provisions the resource without ever running it against an invalid Graph URL. Set
    // SHAREPOINT_HOSTNAME and SHAREPOINT_SITE_PATH and re-run azd up to enable it.
    state: (empty(sharePointHostname) || empty(sharePointSitePath)) ? 'Disabled' : 'Enabled'
    // The webhook URL is a @secure() param - it's threaded through as a workflow parameter (set in
    // `parameters` below, referenced via @parameters('notificationWebhookUrl')) rather than baked
    // as a literal into `definition`, so it never lands in the plain-text workflow definition JSON.
    parameters: {
      notificationWebhookUrl: {
        value: notificationWebhookUrl
      }
    }
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        notificationWebhookUrl: {
          type: 'securestring'
          defaultValue: ''
        }
      }
      triggers: {
        Recurrence: {
          type: 'Recurrence'
          recurrence: {
            frequency: 'Minute'
            interval: recurrenceIntervalMinutes
          }
        }
      }
      actions: {
        // Resolve the Graph site id every run (cheap) instead of asking the user for an opaque id up front.
        Resolve_site_id: {
          type: 'Http'
          runAfter: {}
          inputs: {
            method: 'GET'
            uri: 'https://graph.microsoft.com/v1.0/sites/${sharePointHostname}:${sharePointSitePath}'
            authentication: {
              type: 'ManagedServiceIdentity'
              audience: 'https://graph.microsoft.com/'
            }
          }
        }
        Get_last_sync_state: {
          type: 'Http'
          runAfter: {
            Resolve_site_id: ['Succeeded']
          }
          inputs: {
            method: 'GET'
            uri: '${tableEndpoint}/${stateTableName}(PartitionKey=${q}sync${q},RowKey=${q}state${q})'
            headers: {
              Accept: 'application/json;odata=nometadata'
              'x-ms-version': '2019-02-02'
            }
            authentication: {
              type: 'ManagedServiceIdentity'
              audience: 'https://storage.azure.com/'
            }
          }
        }
        // First run (or after the stored state row was deleted) has no prior delta link, so fall back
        // to a fresh delta query rooted at the configured folder (or the whole default document library).
        Compose_initial_delta_url: {
          type: 'Compose'
          runAfter: {
            Get_last_sync_state: ['Succeeded', 'Failed']
          }
          inputs: '@{concat(\'https://graph.microsoft.com/v1.0/sites/\', body(\'Resolve_site_id\')?[\'id\'], \'${initialDeltaUrlSuffix}\')}'
        }
        Initialize_current_url: {
          type: 'InitializeVariable'
          runAfter: {
            Compose_initial_delta_url: ['Succeeded']
          }
          inputs: {
            variables: [
              {
                name: 'currentUrl'
                type: 'string'
                value: '@if(equals(outputs(\'Get_last_sync_state\')?[\'statusCode\'], 200), coalesce(body(\'Get_last_sync_state\')?[\'DeltaLink\'], outputs(\'Compose_initial_delta_url\')), outputs(\'Compose_initial_delta_url\'))'
              }
            ]
          }
        }
        Initialize_done: {
          type: 'InitializeVariable'
          runAfter: {
            Initialize_current_url: ['Succeeded']
          }
          inputs: {
            variables: [
              {
                name: 'done'
                type: 'boolean'
                value: false
              }
            ]
          }
        }
        Initialize_final_delta_link: {
          type: 'InitializeVariable'
          runAfter: {
            Initialize_done: ['Succeeded']
          }
          inputs: {
            variables: [
              {
                name: 'finalDeltaLink'
                type: 'string'
                value: ''
              }
            ]
          }
        }
        Sync_pages: {
          type: 'Until'
          runAfter: {
            Initialize_final_delta_link: ['Succeeded']
          }
          expression: '@equals(variables(\'done\'), true)'
          limit: {
            count: 200
            timeout: 'PT1H'
          }
          actions: {
            Get_delta_page: {
              type: 'Http'
              runAfter: {}
              inputs: {
                method: 'GET'
                uri: '@{variables(\'currentUrl\')}'
                authentication: {
                  type: 'ManagedServiceIdentity'
                  audience: 'https://graph.microsoft.com/'
                }
              }
            }
            For_each_drive_item: {
              type: 'Foreach'
              runAfter: {
                Get_delta_page: ['Succeeded']
              }
              foreach: '@body(\'Get_delta_page\')?[\'value\']'
              runtimeConfiguration: {
                concurrency: {
                  repetitions: 5
                }
              }
              actions: {
                Item_is_deleted: {
                  type: 'If'
                  expression: {
                    and: [
                      {
                        not: {
                          equals: ['@item()?[\'deleted\']', null]
                        }
                      }
                    ]
                  }
                  actions: {
                    Try_delete_blob: {
                      type: 'Scope'
                      actions: {
                        Delete_blob: {
                          type: 'Http'
                          runAfter: {}
                          inputs: {
                            method: 'DELETE'
                            uri: '${blobEndpoint}/${storageContainerName}/@{encodeURIComponent(item()?[\'id\'])}@{if(empty(item()?[\'name\']), \'\', concat(\'.\', toLower(last(split(item()?[\'name\'], \'.\')))))}'
                            authentication: {
                              type: 'ManagedServiceIdentity'
                              audience: 'https://storage.azure.com/'
                            }
                          }
                        }
                      }
                    }
                  }
                  else: {
                    actions: {
                      Item_is_supported_file: {
                        type: 'If'
                        expression: {
                          and: [
                            {
                              not: {
                                equals: ['@item()?[\'file\']', null]
                              }
                            }
                            {
                              not: {
                                equals: [
                                  '@indexOf(\'${supportedExtensionsCsv}\', concat(\'.\', toLower(last(split(item()?[\'name\'], \'.\')))))'
                                  -1
                                ]
                              }
                            }
                          ]
                        }
                        actions: {
                          Try_ingest_file: {
                            type: 'Scope'
                            actions: {
                              // Microsoft Graph `delta` responses do not carry the
                              // `@microsoft.graph.downloadUrl` instance annotation, so fetch the item's
                              // metadata (which does include it) to get a short-lived, pre-authenticated
                              // download URL before streaming the content.
                              Get_item_download_url: {
                                type: 'Http'
                                runAfter: {}
                                inputs: {
                                  method: 'GET'
                                  uri: 'https://graph.microsoft.com/v1.0/drives/@{item()?[\'parentReference\']?[\'driveId\']}/items/@{item()?[\'id\']}'
                                  authentication: {
                                    type: 'ManagedServiceIdentity'
                                    audience: 'https://graph.microsoft.com/'
                                  }
                                }
                              }
                              Download_file_content: {
                                type: 'Http'
                                runAfter: {
                                  Get_item_download_url: ['Succeeded']
                                }
                                inputs: {
                                  method: 'GET'
                                  uri: '@{body(\'Get_item_download_url\')?[\'@microsoft.graph.downloadUrl\']}'
                                }
                              }
                              Upload_blob: {
                                type: 'Http'
                                runAfter: {
                                  Download_file_content: ['Succeeded']
                                }
                                inputs: {
                                  method: 'PUT'
                                  uri: '${blobEndpoint}/${storageContainerName}/@{encodeURIComponent(item()?[\'id\'])}@{if(empty(item()?[\'name\']), \'\', concat(\'.\', toLower(last(split(item()?[\'name\'], \'.\')))))}'
                                  headers: {
                                    'x-ms-blob-type': 'BlockBlob'
                                    'x-ms-version': '2020-10-02'
                                    'x-ms-meta-sp_item_id': '@{item()?[\'id\']}'
                                    'x-ms-meta-sp_name': '@{item()?[\'name\']}'
                                    'x-ms-meta-sp_web_url': '@{item()?[\'webUrl\']}'
                                    'x-ms-meta-sp_last_modified': '@{item()?[\'lastModifiedDateTime\']}'
                                  }
                                  body: '@body(\'Download_file_content\')'
                                  authentication: {
                                    type: 'ManagedServiceIdentity'
                                    audience: 'https://storage.azure.com/'
                                  }
                                }
                              }
                            }
                          }
                          Catch_ingest_error: {
                            type: 'Scope'
                            runAfter: {
                              Try_ingest_file: ['Failed', 'TimedOut', 'Skipped']
                            }
                            actions: {
                              Log_ingest_error: {
                                type: 'Http'
                                runAfter: {}
                                inputs: {
                                  method: 'POST'
                                  uri: '${tableEndpoint}/${errorsTableName}'
                                  headers: {
                                    Accept: 'application/json;odata=nometadata'
                                    'Content-Type': 'application/json'
                                    'x-ms-version': '2019-02-02'
                                  }
                                  body: {
                                    PartitionKey: '@{formatDateTime(utcNow(), \'yyyy-MM-dd\')}'
                                    RowKey: '@{guid()}'
                                    fileName: '@{item()?[\'name\']}'
                                    fileWebUrl: '@{item()?[\'webUrl\']}'
                                    timestamp: '@{utcNow()}'
                                    error: '@{string(actions(\'Try_ingest_file\'))}'
                                  }
                                  authentication: {
                                    type: 'ManagedServiceIdentity'
                                    audience: 'https://storage.azure.com/'
                                  }
                                }
                              }
                              Notify_ingest_failure: {
                                type: 'If'
                                runAfter: {
                                  Log_ingest_error: ['Succeeded', 'Failed', 'Skipped']
                                }
                                expression: {
                                  not: {
                                    equals: ['@empty(parameters(\'notificationWebhookUrl\'))', true]
                                  }
                                }
                                actions: {
                                  Post_ingest_failure_webhook: {
                                    type: 'Http'
                                    runAfter: {}
                                    inputs: {
                                      method: 'POST'
                                      uri: '@parameters(\'notificationWebhookUrl\')'
                                      headers: {
                                        'Content-Type': 'application/json'
                                      }
                                      body: {
                                        text: 'SharePoint ingestion failed for "@{item()?[\'name\']}" (@{item()?[\'webUrl\']}). See the ${errorsTableName} table for details.'
                                      }
                                    }
                                  }
                                }
                                else: {
                                  actions: {}
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
            Has_more_pages: {
              type: 'If'
              runAfter: {
                For_each_drive_item: ['Succeeded']
              }
              expression: {
                not: {
                  equals: ['@body(\'Get_delta_page\')?[\'@odata.nextLink\']', null]
                }
              }
              actions: {
                Set_current_url_to_next_page: {
                  type: 'SetVariable'
                  runAfter: {}
                  inputs: {
                    name: 'currentUrl'
                    value: '@body(\'Get_delta_page\')?[\'@odata.nextLink\']'
                  }
                }
              }
              else: {
                actions: {
                  Set_final_delta_link: {
                    type: 'SetVariable'
                    runAfter: {}
                    inputs: {
                      name: 'finalDeltaLink'
                      value: '@body(\'Get_delta_page\')?[\'@odata.deltaLink\']'
                    }
                  }
                  Set_done: {
                    type: 'SetVariable'
                    runAfter: {
                      Set_final_delta_link: ['Succeeded']
                    }
                    inputs: {
                      name: 'done'
                      value: true
                    }
                  }
                }
              }
            }
          }
        }
        Save_sync_state: {
          type: 'Http'
          runAfter: {
            Sync_pages: ['Succeeded']
          }
          inputs: {
            method: 'PUT'
            uri: '${tableEndpoint}/${stateTableName}(PartitionKey=${q}sync${q},RowKey=${q}state${q})'
            headers: {
              Accept: 'application/json;odata=nometadata'
              'Content-Type': 'application/json'
              'x-ms-version': '2019-02-02'
            }
            body: {
              PartitionKey: 'sync'
              RowKey: 'state'
              DeltaLink: '@{variables(\'finalDeltaLink\')}'
              lastRunUtc: '@{utcNow()}'
            }
            authentication: {
              type: 'ManagedServiceIdentity'
              audience: 'https://storage.azure.com/'
            }
          }
        }
        Try_run_indexer: {
          type: 'Scope'
          runAfter: {
            Save_sync_state: ['Succeeded', 'Failed', 'Skipped']
          }
          actions: {
            Run_indexer: {
              type: 'Http'
              runAfter: {}
              inputs: {
                method: 'POST'
                uri: '${searchEndpoint}/indexers(${q}${indexerName}${q})/search.run?api-version=2024-07-01'
                authentication: {
                  type: 'ManagedServiceIdentity'
                  audience: 'https://search.azure.com/'
                }
              }
            }
          }
        }
        Catch_run_indexer_error: {
          type: 'Scope'
          runAfter: {
            Try_run_indexer: ['Failed', 'TimedOut']
          }
          // A 409 (indexer already running from the previous cycle) is not a real failure - only
          // log/notify when the run genuinely could not be started.
          actions: {
            Indexer_run_really_failed: {
              type: 'If'
              runAfter: {}
              expression: {
                not: {
                  equals: ['@outputs(\'Run_indexer\')?[\'statusCode\']', 409]
                }
              }
              actions: {
                Log_indexer_error: {
                  type: 'Http'
                  runAfter: {}
                  inputs: {
                    method: 'POST'
                    uri: '${tableEndpoint}/${errorsTableName}'
                    headers: {
                      Accept: 'application/json;odata=nometadata'
                      'Content-Type': 'application/json'
                      'x-ms-version': '2019-02-02'
                    }
                    body: {
                      PartitionKey: '@{formatDateTime(utcNow(), \'yyyy-MM-dd\')}'
                      RowKey: '@{guid()}'
                      fileName: '(indexer run)'
                      fileWebUrl: ''
                      timestamp: '@{utcNow()}'
                      error: '@{string(outputs(\'Run_indexer\'))}'
                    }
                    authentication: {
                      type: 'ManagedServiceIdentity'
                      audience: 'https://storage.azure.com/'
                    }
                  }
                }
                Notify_indexer_failure: {
                  type: 'If'
                  runAfter: {
                    Log_indexer_error: ['Succeeded', 'Failed', 'Skipped']
                  }
                  expression: {
                    not: {
                      equals: ['@empty(parameters(\'notificationWebhookUrl\'))', true]
                    }
                  }
                  actions: {
                    Post_indexer_failure_webhook: {
                      type: 'Http'
                      runAfter: {}
                      inputs: {
                        method: 'POST'
                        uri: '@parameters(\'notificationWebhookUrl\')'
                        headers: {
                          'Content-Type': 'application/json'
                        }
                        body: {
                          text: 'Azure AI Search indexer "${indexerName}" failed to start after the SharePoint sync. See the ${errorsTableName} table for details.'
                        }
                      }
                    }
                  }
                  else: {
                    actions: {}
                  }
                }
              }
            }
          }
        }
      }
      outputs: {}
    }
  }
}

module storageBlobContributorRole '../core/security/role.bicep' = {
  name: 'sp-logicapp-storage-blob-${uniqueString(logicAppName)}'
  scope: resourceGroup(storageResourceGroupName)
  params: {
    principalId: logicApp.identity.principalId
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
    principalType: 'ServicePrincipal'
  }
}

module storageTableContributorRole '../core/security/role.bicep' = {
  name: 'sp-logicapp-storage-table-${uniqueString(logicAppName)}'
  scope: resourceGroup(storageResourceGroupName)
  params: {
    principalId: logicApp.identity.principalId
    roleDefinitionId: '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3' // Storage Table Data Contributor
    principalType: 'ServicePrincipal'
  }
}

module searchServiceContributorRole '../core/security/role.bicep' = {
  name: 'sp-logicapp-search-${uniqueString(logicAppName)}'
  scope: resourceGroup(searchServiceResourceGroupName)
  params: {
    principalId: logicApp.identity.principalId
    roleDefinitionId: '7ca78c08-252a-4471-8644-bb5ff32d4ba0' // Search Service Contributor (needed to trigger indexer runs)
    principalType: 'ServicePrincipal'
  }
}

output logicAppName string = logicApp.name
output logicAppId string = logicApp.id
output principalId string = logicApp.identity.principalId
output state string = logicApp.properties.state
