# Enabling optional features

This document covers optional features that can be enabled in the deployed Azure resources.
You should typically enable these features before running `azd up`. Once you've set them, return to the [deployment steps](../README.md#deploying).

* [Using different chat-completions models](#using-different-chat-completions-models)
* [Using reasoning models](#using-reasoning-models)
* [Using agentic retrieval](#using-agentic-retrieval)
* [Using different embedding models](#using-different-embedding-models)
* [Enabling multimodal image descriptions and embeddings](#enabling-multimodal-image-descriptions-and-embeddings)
* [Enabling media description with Azure Content Understanding](#enabling-media-description-with-azure-content-understanding)
* [Enabling cloud data ingestion](#enabling-cloud-data-ingestion)
* [Enabling document-level access control](#enabling-document-level-access-control)
* [Enabling query rewriting](#enabling-query-rewriting)
* [Adding an OpenAI load balancer](#adding-an-openai-load-balancer)
* [Deploying with private endpoints](#deploying-with-private-endpoints)
* [Using local parsers](#using-local-parsers)

## Using different chat-completions models

As of June 2026, the default chat-completions model is `gpt-5.4-mini`. This model is used only during ingestion, to generate text descriptions of figures/images (see [the multimodal guide](multimodal.md)) — it is not used for end-user chat, since this repository has no chat component. You can change it to any Azure OpenAI model that's available in your Azure OpenAI resource region by following these steps:

1. To set the name of the deployment, run this command with a unique name in your Azure OpenAI account. You can use any deployment name, as long as it's unique in your Azure OpenAI account. For convenience, many developers use the same deployment name as the model name, but this is not required.

    ```bash
    azd env set AZURE_OPENAI_CHATGPT_DEPLOYMENT <your-deployment-name>
    ```

    For example:

    ```bash
    azd env set AZURE_OPENAI_CHATGPT_DEPLOYMENT gpt-5.4-mini
    ```

1. To set the GPT model to a different [available model](https://learn.microsoft.com/azure/ai-services/openai/concepts/models), run this command with the appropriate model name. A few examples are below.

   For gpt-5.4-mini(default):

   ```shell
   azd env set AZURE_OPENAI_CHATGPT_MODEL gpt-5.4-mini
   ```

   For gpt-5.2:

   ```shell
   azd env set AZURE_OPENAI_CHATGPT_MODEL gpt-5.2
   ```

1. To set the Azure OpenAI model version from the [available versions](https://learn.microsoft.com/azure/ai-services/openai/concepts/models), run this command with the appropriate version string.

   For gpt-5.4-mini (default)

   ```shell
   azd env set AZURE_OPENAI_CHATGPT_DEPLOYMENT_VERSION 2026-03-17
   ```

   For gpt-5.2:

   ```shell
   azd env set AZURE_OPENAI_CHATGPT_DEPLOYMENT_VERSION 2025-12-11
   ```

1. To set the Azure OpenAI deployment SKU name, run this command with [the desired SKU name](https://learn.microsoft.com/azure/ai-foundry/foundry-models/concepts/deployment-types).

    For GlobalStandard (default):

    ```bash
    azd env set AZURE_OPENAI_CHATGPT_DEPLOYMENT_SKU GlobalStandard
    ```

    For Standard:

    ```bash
    azd env set AZURE_OPENAI_CHATGPT_DEPLOYMENT_SKU Standard
    ```

1. To set the Azure OpenAI deployment capacity (TPM, measured in thousands of tokens per minute), run this command with the desired capacity. This is not necessary if you are using the default capacity of 30.

    ```bash
    azd env set AZURE_OPENAI_CHATGPT_DEPLOYMENT_CAPACITY 20
    ```

1. To update the deployment with the new parameters, run this command.

    ```bash
    azd up
    ```

This process does *not* delete your previous model deployment. If you want to delete previous deployments, go to your Azure OpenAI resource in Azure AI Foundry and delete it there.

> [!NOTE]
> To revert back to a previous model, run the same commands with the previous model name and version.

## Using reasoning models

The default model (gpt-5.4-mini) is a reasoning model. See [the reasoning models guide](./reasoning.md) for details on how it's used during ingestion.

## Using agentic retrieval

This project's Bicep templates no longer provision the agentic-retrieval knowledge base parameters (that mechanism was specific to the removed chat backend). See [the agentic retrieval guide](./agentic_retrieval.md) for details and how to re-enable the underlying Azure AI Search feature yourself, if needed.

## Using different embedding models

By default, ingestion uses the `text-embedding-3-large` embedding model. If you want to use a different embedding model, you can do so by following these steps:

1. Run one of the following commands to set the desired model:

    ```shell
    azd env set AZURE_OPENAI_EMB_MODEL_NAME text-embedding-ada-002
    ```

    ```shell
    azd env set AZURE_OPENAI_EMB_MODEL_NAME text-embedding-3-small
    ```

    ```shell
    azd env set AZURE_OPENAI_EMB_MODEL_NAME text-embedding-3-large
    ```

2. Specify the desired dimensions of the model: (from 256-3072, model dependent)

    Default dimensions for text-embedding-ada-002

    ```shell
    azd env set AZURE_OPENAI_EMB_DIMENSIONS 1536
    ```

    Default dimensions for text-embedding-3-small

    ```shell
    azd env set AZURE_OPENAI_EMB_DIMENSIONS 1536
    ```

    Default dimensions for text-embedding-3-large

    ```shell
    azd env set AZURE_OPENAI_EMB_DIMENSIONS 3072
    ```

3. Set the model version, depending on the model you are using:

    For text-embedding-ada-002:

    ```shell
    azd env set AZURE_OPENAI_EMB_DEPLOYMENT_VERSION 2
    ```

    For text-embedding-3-small and text-embedding-3-large:

    ```shell
    azd env set AZURE_OPENAI_EMB_DEPLOYMENT_VERSION 1
    ```

4. To set the embedding model deployment SKU name, run this command with [the desired SKU name](https://learn.microsoft.com/azure/ai-foundry/foundry-models/concepts/deployment-types).

    For GlobalStandard:

    ```bash
    azd env set AZURE_OPENAI_EMB_DEPLOYMENT_SKU GlobalStandard
    ```

    For Standard:

    ```bash
    azd env set AZURE_OPENAI_EMB_DEPLOYMENT_SKU Standard
    ```

5. When prompted during `azd up`, make sure to select a region for the OpenAI resource group location that supports the desired embedding model and deployment SKU. There are [limited regions available](https://learn.microsoft.com/azure/ai-services/openai/concepts/models?tabs=global-standard%2Cstandard-chat-completions#models-by-deployment-type).

If you have already deployed:

* You'll need to change the deployment name by running the appropriate commands for the model above.
* You'll need to create a new index, and re-index all of the data using the new model. You can either delete the current index in the Azure Portal, or create an index with a different name by running `azd env set AZURE_SEARCH_INDEX new-index-name`. When you next run `azd up`, the new index will be created. See the [data ingestion guide](./data_ingestion.md) for more details.

## Enabling multimodal image descriptions and embeddings

When your documents include images, you can optionally enable this feature so that ingestion generates image embeddings and text descriptions for figures found in your documents.

Learn more in the [multimodal guide](./multimodal.md).

## Enabling media description with Azure Content Understanding

⚠️ This feature is compatible with the [multimodal feature](./multimodal.md), but this feature enables only a subset of multimodal capabilities,
so you may want to enable the multimodal feature instead or as well.

By default, if your documents contain image-like figures, the data ingestion process will ignore those figures,
so a querying client will not be able to answer questions about them.

You can optionably enable the description of media content using Azure Content Understanding. When enabled, the data ingestion process will send figures to Azure Content Understanding and replace the figure with the description in the indexed document.

To enable media description with Azure Content Understanding, run:

```shell
azd env set USE_MEDIA_DESCRIBER_AZURE_CU true
```

If you have already run `azd up`, you will need to run `azd provision` to create the new Content Understanding service.
If you have already indexed your documents and want to re-index them with the media descriptions,
first [remove the existing documents](./data_ingestion.md#removing-documents) and then [re-ingest the data](./data_ingestion.md#indexing-additional-documents).

⚠️ This feature does not yet support DOCX, PPTX, or XLSX formats. If you have figures in those formats, they will be ignored.
Convert them first to PDF or image formats to enable media description.

## Enabling cloud data ingestion

By default, this project runs a local script in order to ingest data. Once you move beyond the sample documents, you may want to enable [cloud ingestion](./data_ingestion.md#cloud-ingestion), which uses Azure AI Search indexers and custom Azure AI Search skills based off the same code used by the local ingestion. That approach scales better to larger amounts of data.

Learn more in the [cloud ingestion guide](./data_ingestion.md#cloud-ingestion).

## Enabling document-level access control

By default, the search index has no document-level access restrictions, so any querying client (e.g. Microsoft Copilot Studio) can see all indexed content. You can enable an optional document-level access control system to restrict which documents are returned based on the querying user's identity. Enable it by following [this guide](./login_and_acl.md).

## Enabling query rewriting

By default, the [query rewriting feature](https://learn.microsoft.com/azure/search/semantic-how-to-query-rewrite) from the Azure AI Search service is not enabled. To enable search service query rewriting, set the following environment variables:

1. Check that your Azure AI Search service is using one of the [supported regions](https://learn.microsoft.com/azure/search/semantic-how-to-query-rewrite#prerequisites) for query rewriting.
1. Ensure semantic ranker is enabled. Query rewriting may only be used with semantic ranker. Run `azd env set AZURE_SEARCH_SEMANTIC_RANKER free` or `azd env set AZURE_SEARCH_SEMANTIC_RANKER standard` depending on your desired [semantic ranker tier](https://learn.microsoft.com/azure/search/semantic-how-to-configure).
1. Enable query rewriting. Run `azd env set AZURE_SEARCH_QUERY_REWRITING true`.

## Adding an OpenAI load balancer

As discussed in more details in our [productionizing guide](./productionizing.md), you may want to consider implementing a load balancer between OpenAI instances if you are consistently going over the TPM limit, especially for large ingestion runs.
Fortunately, this repository is designed for easy integration with other repositories that create load balancers for OpenAI instances. For seamless integration instructions, please check:

* [Scale Azure OpenAI for Python with Azure API Management](https://learn.microsoft.com/azure/developer/python/get-started-app-chat-scaling-with-azure-api-management)

## Deploying with private endpoints

It is possible to deploy this pipeline with public access disabled, using Azure private endpoints and private DNS Zones. For more details, read [the private deployment guide](./deploy_private.md). That requires a multi-stage provisioning, so you will need to do more than just `azd up` after setting the environment variables.

## Using local parsers

If you want to decrease the charges by using local parsers instead of Azure Document Intelligence, you can set environment variables before running the [data ingestion script](./data_ingestion.md). Note that local parsers will generally be not as sophisticated.

1. Run `azd env set USE_LOCAL_PDF_PARSER true` to use the local PDF parser.
1. Run `azd env set USE_LOCAL_HTML_PARSER true` to use the local HTML parser.

The local parsers will be used the next time you run the data ingestion script.
</content>
