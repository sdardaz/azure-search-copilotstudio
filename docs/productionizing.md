# Productionizing the ingestion pipeline

This sample is designed to be a starting point for your own production application,
but you should do a thorough review of the security and performance before deploying
to production. Here are some things to consider:

* [Azure resource configuration](#azure-resource-configuration)
* [Additional security measures](#additional-security-measures)
* [Evaluation](#evaluation)

## Azure resource configuration

### OpenAI Capacity

The default TPM (tokens per minute) is set to 30K for both the chat-completions deployment (used for ingestion-time figure descriptions) and the embedding deployment (used for both ingestion-time and, if you built one, query-time embeddings).
You can increase the capacity by changing the `chatGptDeploymentCapacity` and `embeddingDeploymentCapacity`
parameters in `infra/main.bicep` to your account's maximum capacity — this matters most for large ingestion runs or [cloud ingestion](data_ingestion.md#cloud-ingestion), where many documents may be processed concurrently.
You can also view the Quotas tab in [Azure OpenAI studio](https://oai.azure.com/)
to understand how much capacity you have.

If the maximum TPM isn't enough for your expected load, you have a few options:

* Use a backoff mechanism to retry the request. This is helpful if you're running into a short-term quota due to bursts of activity but aren't over long-term quota. The [tenacity](https://tenacity.readthedocs.io/en/latest/) library (already used by `prepdocslib/embeddings.py`) is a good option for this.

* If you are consistently going over the TPM, then consider implementing a load balancer between OpenAI instances, e.g. using [Azure API Management](https://learn.microsoft.com/azure/api-management/genai-gateway-capabilities) or a container-based load balancer.

### Azure Storage

The default storage account uses the `Standard_LRS` SKU.
To improve your resiliency, we recommend using `Standard_ZRS` for production deployments,
which you can specify using the `sku` property under the `storage` module in `infra/main.bicep`.

### Azure AI Search

The default search service uses the "Basic" SKU
with the free semantic ranker option, which gives you 1000 free queries a month.
After 1000 queries, you will get an error message about exceeding the semantic ranker free capacity.

* Assuming your app will experience more than 1000 questions per month,
  you should upgrade the semantic ranker SKU from "free" to "standard" SKU:

  ```shell
  azd env set AZURE_SEARCH_SEMANTIC_RANKER standard
  ```

  Or disable semantic search entirely:

  ```shell
  azd env set AZURE_SEARCH_SEMANTIC_RANKER disabled
  ```

* The search service can handle fairly large indexes, but it does have per-SKU limits on storage sizes, maximum vector dimensions, etc. You may want to upgrade the SKU to either a Standard or Storage Optimized SKU, depending on your expected load.
You can [switch between Basic, S1, S2, and S3 tiers](https://learn.microsoft.com/azure/search/search-capacity-planning#change-your-pricing-tier), but you can't switch to or from Free, S3HD, L1, or L2. If you need to change to one of those tiers, you will need to create a new search service and re-index the data or manually copy it over.
You can change the SKU by setting the `AZURE_SEARCH_SERVICE_SKU` azd environment variable to [an allowed SKU](https://learn.microsoft.com/azure/templates/microsoft.search/searchservices?pivots=deployment-language-bicep#sku).

  ```shell
  azd env set AZURE_SEARCH_SERVICE_SKU standard
  ```

  See the [Azure AI Search service limits documentation](https://learn.microsoft.com/azure/search/search-limits-quotas-capacity) for more details.

* If you see errors about search service capacity being exceeded, you may find it helpful to increase
the number of replicas by changing `replicaCount` in `infra/core/search/search-services.bicep`
or manually scaling it from the Azure Portal.

### Azure Functions (cloud ingestion)

If you've enabled [cloud ingestion](data_ingestion.md#cloud-ingestion) (`USE_CLOUD_INGESTION`), the default Function Apps use a Consumption plan. For large or continuously-updated document sets, consider a Premium plan for more predictable performance and to avoid cold starts, and increase the embedding model deployment capacity (`AZURE_OPENAI_EMB_DEPLOYMENT_CAPACITY`) so ingestion isn't rate-limited.

## Additional security measures

* **Access control**: By default, the search index has no document-level access restrictions, meaning any querying client (e.g. Copilot Studio) that can query the index can see all indexed content.
  We recommend enabling [document-level access control](./login_and_acl.md) if different users should see different documents.
* **Networking**: We recommend [deploying inside a Virtual Network](./deploy_private.md). If the index is only for
  internal enterprise use, use a private DNS zone. Also consider using Azure API Management (APIM)
  for firewalls and other forms of protection.
  For more details, read [Azure OpenAI Landing Zone reference architecture](https://techcommunity.microsoft.com/blog/azurearchitectureblog/azure-openai-landing-zone-reference-architecture/3882102).

## Evaluation

Before you connect your index to Copilot Studio (or any other querying client), you'll want to rigorously evaluate retrieval quality. See [the evaluation guide](./evaluation.md) for generating ground truth data from your search index, and consider using tools in [the AI RAG Chat evaluator](https://github.com/Azure-Samples/ai-rag-chat-evaluator) repository if you have a chat client to evaluate end to end.
