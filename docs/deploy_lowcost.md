# Deploying with minimal costs

This Azure AI Search ingestion pipeline is designed to be easily deployed using the Azure Developer CLI, which provisions the infrastructure according to the Bicep files in the `infra` folder. Those files describe each of the Azure resources needed, and configures their SKU (pricing tier) and other parameters. Many Azure services offer a free tier, but the infrastructure files in this project do *not* default to the free tier as there are often limitations in that tier.

However, if your goal is to minimize costs while prototyping your application, follow the steps below *before* running `azd up`. Once you've gone through these steps, return to the [deployment steps](../README.md#deploying).

[📺 Live stream: Deploying from a free account](https://www.youtube.com/watch?v=nlIyos0RXHw)

1. Log in to your Azure account using the Azure Developer CLI:

    ```shell
    azd auth login
    ```

1. Create a new azd environment for the free resource group:

    ```shell
    azd env new
    ```

    Enter a name that will be used for the resource group.
    This will create a new folder in the `.azure` folder, and set it as the active environment for any calls to `azd` going forward.

1. Use the free tier of Azure AI Search:

    ```shell
    azd env set AZURE_SEARCH_SERVICE_SKU free
    ```

    Limitations:
    1. You are only allowed one free search service across all regions.
    If you have one already, either delete that service or follow instructions to
    reuse your [existing search service](deploy_existing.md#azure-ai-search-resource).
    2. The free tier does not support semantic ranker. Note that will generally result in [decreased search relevance](https://techcommunity.microsoft.com/blog/azure-ai-services-blog/azure-ai-search-outperforming-vector-search-with-hybrid-retrieval-and-ranking-ca/3929167).
    3. The free tier does not support managed identities. As a result, cloud ingestion and multimodal/vector features that require role assignments to the search service principal will have those role assignments skipped during provisioning. If you need those permissions, use a non-free tier (for example, `Basic`/`B1` or `Standard`).

1. Use the free tier of Azure Document Intelligence (used in analyzing files):

    ```shell
    azd env set AZURE_DOCUMENTINTELLIGENCE_SKU F0
    ```

    **Limitation for PDF files:**

      The free tier will only scan the first two pages of each PDF.
      In our sample documents, those first two pages are just title pages,
      so you won't be able to get answers from the documents.
      You can either use your own documents that are only 2-pages long,
      or you can use a local Python package for PDF parsing by setting:

      ```shell
      azd env set USE_LOCAL_PDF_PARSER true
      ```

    **Limitation for HTML files:**

      The free tier will only scan the first two pages of each HTML file.
      So, you might not get very accurate answers from the files.
      You can either use your own files that are only 2-pages long,
      or you can use a local Python package for HTML parsing by setting:

      ```shell
      azd env set USE_LOCAL_HTML_PARSER true
      ```

1. Turn off Azure Monitor (Application Insights):

    ```shell
    azd env set AZURE_USE_APPLICATION_INSIGHTS false
    ```

    Application Insights is quite inexpensive already, so turning this off may not be worth the costs saved,
    but it is an option for those who want to minimize costs.

1. Use OpenAI.com instead of Azure OpenAI: This should not be necessary, as the costs are same for both services, but you may need this step if your account does not have access to Azure OpenAI for some reason.

    ```shell
    azd env set OPENAI_HOST openai
    azd env set OPENAI_ORGANIZATION {Your OpenAI organization}
    azd env set OPENAI_API_KEY {Your OpenAI API key}
    ```

    Both Azure OpenAI and openai.com OpenAI accounts will incur costs, based on tokens used,
    but the costs are fairly low for the amount of sample data (less than $10).

1. Disable vector search:

    ```shell
    azd env set USE_VECTORS false
    ```

    By default, ingestion computes vector embeddings for documents during the data ingestion phase.
    Those computations require an embedding model, which incurs costs per tokens used. The costs are fairly low,
    so the benefits of vector search would typically outweigh the costs, but it is possible to disable vector support.
    If you do so, the index will fall back to a keyword search, which is less accurate.

1. Once you've made the desired customizations, follow the steps in the README [to run `azd up`](../README.md#deploying). We recommend using "eastus" as the region, for availability reasons.

## Reducing costs locally

To save costs for local development, you could use an OpenAI-compatible model.
Follow steps in [local development guide](localdev.md#using-a-local-openai-compatible-api).
