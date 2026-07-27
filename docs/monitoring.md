# Monitoring with Application Insights

By default (`AZURE_USE_APPLICATION_INSIGHTS`, enabled by default), Azure Monitor / Application Insights is provisioned and wired up to the resources in this pipeline that emit telemetry:

- **Azure AI Search**: `OperationLogs` and metrics are streamed to the Log Analytics workspace via `infra/core/search/search-diagnostics.bicep`. This is useful for monitoring indexer runs and skillset executions when using [cloud ingestion](data_ingestion.md#cloud-ingestion).
- **Azure Functions** (only if `USE_CLOUD_INGESTION` is enabled): the document-extractor, figure-processor, and text-processor function apps are automatically instrumented via the `APPLICATIONINSIGHTS_CONNECTION_STRING` app setting, using the Azure Functions runtime's built-in Application Insights integration.

* [Investigating indexer and function runs](#investigating-indexer-and-function-runs)
* [Dashboard](#dashboard)

## Investigating indexer and function runs

To see cloud-ingestion Function App executions, go to the Application Insights resource in your resource group and use the "Investigate -> Performance" and "Investigate -> Failures" blades to inspect function invocations and exceptions.

To see Azure AI Search indexer status and errors, use the "Indexers" tab on the Azure AI Search resource in the Azure Portal, or query the Log Analytics workspace for `OperationLogs` from the search service.

## Dashboard

You can see chart summaries on a dashboard by running the following command:

```shell
azd monitor
```

You can modify the contents of that dashboard by updating `infra/backend-dashboard.bicep`, which is a Bicep file that defines the dashboard contents and layout.
</content>
