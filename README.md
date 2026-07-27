# Azure AI Search ingestion pipeline for Microsoft Copilot Studio (Python)

**Author / maintainer:** Soufyane Dardaz

This solution provisions and populates an Azure AI Search index that [Microsoft Copilot Studio's built-in "Azure AI Search" knowledge source connector](docs/copilot_studio_integration.md) can query directly. It does **not** include a chat UI or chat backend — Copilot Studio is the conversational front end. This repository is responsible only for getting your documents into a well-structured, searchable index: extracting text and figures from PDFs, Office documents, images, HTML, JSON, CSV, and plain text, chunking that content, generating embeddings, and optionally enforcing document-level access control.

The data ingestion pipeline started as a fork of the open-source `azure-search-openai-demo` RAG chat sample; the chat application has since been removed entirely and the project has been repurposed and extended (SharePoint sync, Copilot Studio integration) as its own, independently maintained project. See [LICENSE](LICENSE) for the license and attribution.

[![Open in GitHub Codespaces](https://img.shields.io/static/v1?style=for-the-badge&label=GitHub+Codespaces&message=Open&color=brightgreen&logo=github)](https://codespaces.new/sdardaz/azure-search-copilotstudio)
[![Open in Dev Containers](https://img.shields.io/static/v1?style=for-the-badge&label=Dev%20Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/sdardaz/azure-search-copilotstudio)

## Important Security Notice

This project is built on Microsoft Azure services and tools. As with any sample or starting-point code, don't put it into production without implementing or enabling additional security features. See the [productionizing guide](docs/productionizing.md) for tips, and consult the [Azure OpenAI Landing Zone reference architecture](https://techcommunity.microsoft.com/blog/azurearchitectureblog/azure-openai-landing-zone-reference-architecture/3882102) for more best practices.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Azure account requirements](#azure-account-requirements)
  - [Cost estimation](#cost-estimation)
- [Getting Started](#getting-started)
  - [GitHub Codespaces](#github-codespaces)
  - [VS Code Dev Containers](#vs-code-dev-containers)
  - [Local environment](#local-environment)
- [Deploying](#deploying)
  - [Deploying again](#deploying-again)
- [Connecting Copilot Studio](#connecting-copilot-studio)
- [Ingesting more data locally](#ingesting-more-data-locally)
- [Clean up](#clean-up)
- [Guidance](#guidance)
  - [Resources](#resources)

## Features

- Ingests [many document formats](/docs/data_ingestion.md#supported-document-formats): PDF, Word (DOCX), PowerPoint (PPTX), Excel (XLSX), images (JPG/PNG/BMP/TIFF/HEIF), HTML, JSON, CSV, and plain text/Markdown, using Azure Document Intelligence for the richer formats.
- Optional use of [multimodal models](/docs/multimodal.md) to describe figures/images found in documents (charts, diagrams, photos), so that visual content becomes searchable text alongside image embeddings.
- Splits content into search-optimized chunks and computes vector embeddings with Azure OpenAI.
- Two ingestion modes: a local CLI (`prepdocs.py`) for ingesting files from disk, and an optional [cloud ingestion pipeline](/docs/data_ingestion.md#cloud-ingestion) that runs entirely in Azure using an Azure AI Search indexer and Azure Functions custom skills — useful for larger or continuously-updated document sets.
- Optional [document-level access control](/docs/login_and_acl.md), so that Copilot Studio (or any other querying client) only returns documents a given user is permitted to see.
- Optional Azure Logic App that syncs documents from a SharePoint Online site/library into the Blob Storage container that feeds ingestion — see [Copilot Studio integration guide](docs/copilot_studio_integration.md).
- The resulting Azure AI Search index is designed to be connected directly to Microsoft Copilot Studio via its built-in "Add knowledge > Azure AI Search" connector — no custom API or chat backend is required.

### Architecture

At a high level:

- **Azure AI Search** hosts the index that Copilot Studio queries. It also hosts the (optional) indexer/skillset used by cloud ingestion.
- **Azure Blob Storage** holds the source documents, either uploaded manually, ingested locally via `prepdocs.py`, or synced from SharePoint by the optional Logic App.
- **Azure OpenAI / Microsoft Foundry** provides the embedding model (for vector search) and a vision-capable chat-completions model used only to generate figure/image descriptions during ingestion — it is not used for end-user chat.
- **Azure AI Document Intelligence** extracts text, tables, and figures from PDFs, Office documents, and images.
- **Azure AI Vision** and/or **Azure AI Content Understanding** (optional) provide image embeddings and/or media descriptions for the multimodal ingestion feature.
- **Azure Functions** (optional, `USE_CLOUD_INGESTION`) implement the document-extraction, figure-processing, and text-processing custom skills used by the Azure AI Search indexer for cloud ingestion.
- **Azure Logic App** (optional, added separately, see [Copilot Studio integration guide](docs/copilot_studio_integration.md)) syncs documents from a SharePoint Online site/library into the Blob Storage container above.

See [the architecture guide](docs/architecture.md) for more details.

## Azure account requirements

**IMPORTANT:** In order to deploy and run this example, you'll need:

- **Azure account**. If you're new to Azure, [get an Azure account for free](https://azure.microsoft.com/free/cognitive-search/) and you'll get some free Azure credits to get started. See [guide to deploying with the free trial](docs/deploy_freetrial.md).
- **Azure account permissions**:
  - Your Azure account must have `Microsoft.Authorization/roleAssignments/write` permissions, such as [Role Based Access Control Administrator](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#role-based-access-control-administrator-preview), [User Access Administrator](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#user-access-administrator), or [Owner](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#owner). If you don't have subscription-level permissions, you must be granted [RBAC](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#role-based-access-control-administrator-preview) for an existing resource group and [deploy to that existing group](docs/deploy_existing.md#resource-group).
  - Your Azure account also needs `Microsoft.Resources/deployments/write` permissions on the subscription level.
- A [Microsoft Copilot Studio](https://learn.microsoft.com/microsoft-copilot-studio/) environment, if you want to connect the resulting index to an agent. See [the Copilot Studio integration guide](docs/copilot_studio_integration.md).

### Cost estimation

Pricing varies per region and usage, so it isn't possible to predict exact costs for your usage.
However, you can try the [Azure pricing calculator](https://azure.com/e/e3490de2372a4f9b909b0d032560e41b) for the resources below.

- Azure OpenAI: Standard tier, GPT and embedding models. Pricing per 1K tokens used. [Pricing](https://azure.microsoft.com/pricing/details/cognitive-services/openai-service/)
- Azure AI Document Intelligence: SO (Standard) tier using pre-built layout. Pricing per document page, sample documents have 261 pages total. [Pricing](https://azure.microsoft.com/pricing/details/form-recognizer/)
- Azure AI Search: Basic tier, 1 replica, free level of semantic search. Pricing per hour. [Pricing](https://azure.microsoft.com/pricing/details/search/)
- Azure Blob Storage: Standard tier with ZRS (Zone-redundant storage). Pricing per storage and read operations. [Pricing](https://azure.microsoft.com/pricing/details/storage/blobs/)
- Azure Functions: Only provisioned if you enable [cloud ingestion](docs/data_ingestion.md#cloud-ingestion) (`USE_CLOUD_INGESTION`). Consumption plan, pricing per execution and execution time. [Pricing](https://azure.microsoft.com/pricing/details/functions/)
- Azure AI Vision: Only provisioned if you enabled the [multimodal approach](docs/multimodal.md). Pricing per 1K transactions. [Pricing](https://azure.microsoft.com/pricing/details/cognitive-services/computer-vision/)
- Azure AI Content Understanding: Only provisioned if you enabled [media description](docs/deploy_features.md#enabling-media-description-with-azure-content-understanding). Pricing per 1K images. [Pricing](https://azure.microsoft.com/pricing/details/content-understanding/)
- Azure Monitor: Pay-as-you-go tier. Costs based on data ingested. [Pricing](https://azure.microsoft.com/pricing/details/monitor/)

To reduce costs, you can switch to free SKUs for various services, but those SKUs have limitations.
See this guide on [deploying with minimal costs](docs/deploy_lowcost.md) for more details.

⚠️ To avoid unnecessary costs, remember to take down your deployment if it's no longer in use,
either by deleting the resource group in the Portal or running `azd down`.

## Getting Started

You have a few options for setting up this project.
The easiest way to get started is GitHub Codespaces, since it will setup all the tools for you,
but you can also [set it up locally](#local-environment) if desired.

### GitHub Codespaces

You can run this repo virtually by using GitHub Codespaces, which will open a web-based VS Code in your browser:

[![Open in GitHub Codespaces](https://img.shields.io/static/v1?style=for-the-badge&label=GitHub+Codespaces&message=Open&color=brightgreen&logo=github)](https://codespaces.new/sdardaz/azure-search-copilotstudio)

Once the codespace opens (this may take several minutes), open a terminal window.

### VS Code Dev Containers

A related option is VS Code Dev Containers, which will open the project in your local VS Code using the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers):

1. Start Docker Desktop (install it if not already installed)
2. Open the project:
    [![Open in Dev Containers](https://img.shields.io/static/v1?style=for-the-badge&label=Dev%20Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/sdardaz/azure-search-copilotstudio)

3. In the VS Code window that opens, once the project files show up (this may take several minutes), open a terminal window.

### Local environment

1. Install the required tools:

    - [Azure Developer CLI](https://aka.ms/azure-dev/install)
    - [Python 3.10, 3.11, 3.12, 3.13, or 3.14](https://www.python.org/downloads/)
      - **Important**: Python and the pip package manager must be in the path in Windows for the setup scripts to work.
      - **Important**: Ensure you can run `python --version` from console. On Ubuntu, you might need to run `sudo apt install python-is-python3` to link `python` to `python3`.
    - [Git](https://git-scm.com/downloads)
    - [Powershell 7+ (pwsh)](https://github.com/powershell/powershell) - For Windows users only.
      - **Important**: Ensure you can run `pwsh.exe` from a PowerShell terminal. If this fails, you likely need to upgrade PowerShell.

2. Clone this repository and switch to it in the terminal:

    ```shell
    git clone https://github.com/sdardaz/azure-search-copilotstudio.git
    cd azure-search-copilotstudio
    ```

## Deploying

The steps below will provision the Azure resources (Azure AI Search, Storage, Azure OpenAI/Foundry, Document Intelligence, and optionally Azure Functions) and then run the data ingestion pipeline against the sample documents in the `./data` folder, populating the Azure AI Search index.

1. Login to your Azure account:

    ```shell
    azd auth login
    ```

    For GitHub Codespaces users, if the previous command fails, try:

   ```shell
    azd auth login --use-device-code
    ```

1. Create a new azd environment:

    ```shell
    azd env new
    ```

    Enter a name that will be used for the resource group.
    This will create a new folder in the `.azure` folder, and set it as the active environment for any calls to `azd` going forward.
1. (Optional) This is the point where you can customize the deployment by setting environment variables, in order to [use existing resources](docs/deploy_existing.md), [enable optional features (such as multimodal or cloud ingestion)](docs/deploy_features.md), or [deploy low-cost options](docs/deploy_lowcost.md), or [deploy with the Azure free trial](docs/deploy_freetrial.md).
1. (Optional) To use the [cloud ingestion pipeline](docs/data_ingestion.md#cloud-ingestion) (Azure AI Search indexer + Azure Functions custom skills) instead of the local `prepdocs` script, run:

    ```shell
    azd env set USE_CLOUD_INGESTION true
    ```

1. Run `azd up` - This will provision the Azure resources and, for local ingestion (the default), run `prepdocs` to build the search index from the files found in the `./data` folder. For cloud ingestion, it provisions the Azure Functions and configures the indexer/skillset, then triggers an initial indexing run.
    - **Important**: Beware that the resources created by this command will incur immediate costs, primarily from the AI Search resource. These resources may accrue costs even if you interrupt the command before it is fully executed. You can run `azd down` or delete the resources manually to avoid unnecessary spending.
    - You will be prompted to select two locations, one for the majority of resources and one for the OpenAI resource, which is currently a short list. That location list is based on the [OpenAI model availability table](https://learn.microsoft.com/azure/cognitive-services/openai/concepts/models#model-summary-table-and-region-availability) and may become outdated as availability changes.
1. After `azd up` completes, your Azure AI Search index is populated and ready to be connected to Copilot Studio.

### Deploying again

If you've only changed the data ingestion code in `app/backend` or `app/functions`, you don't necessarily need to re-provision the Azure resources — just re-run the ingestion:

```shell
./scripts/prepdocs.sh   # or scripts/prepdocs.ps1 on Windows
```

If you've changed the infrastructure files (`infra` folder or `azure.yaml`), then you'll need to re-provision the Azure resources. You can do that by running:

```shell
azd up
```

## Connecting Copilot Studio

Once the Azure AI Search index is populated, connect it to your Copilot Studio agent using the built-in "Add knowledge > Azure AI Search" connector. For step-by-step instructions, including the optional SharePoint-to-Blob sync via Azure Logic Apps, see [the Copilot Studio integration guide](docs/copilot_studio_integration.md).

## Ingesting more data locally

You can only run the local ingestion script after having successfully run `azd up` at least once, since it depends on the provisioned resources. To add more documents or re-run ingestion locally:

1. Run `azd auth login` if you have not logged in recently.
2. Add files to the `data` folder (or point at a different folder — see [data ingestion](docs/data_ingestion.md)).
3. Run the ingestion script:

    Windows:

    ```shell
    ./scripts/prepdocs.ps1
    ```

    Linux/Mac:

    ```shell
    ./scripts/prepdocs.sh
    ```

See [the data ingestion guide](docs/data_ingestion.md) for details on supported formats, chunking, and the cloud ingestion pipeline.

## Clean up

To clean up all the resources created by this sample:

1. Run `azd down`
2. When asked if you are sure you want to continue, enter `y`
3. When asked if you want to permanently delete the resources, enter `y`

The resource group and all the resources will be deleted.

## Guidance

You can find extensive documentation in the [docs](docs/README.md) folder:

- [Connecting Copilot Studio (and the optional SharePoint sync)](docs/copilot_studio_integration.md)
- Deploying:
  - [Troubleshooting deployment](docs/deploy_troubleshooting.md)
  - [Deploying with azd: deep dive and CI/CD](docs/azd.md)
  - [Deploying with existing Azure resources](docs/deploy_existing.md)
  - [Deploying from a free account](docs/deploy_lowcost.md)
  - [Enabling optional features](docs/deploy_features.md)
    - [All features](docs/deploy_features.md)
    - [Document-level access control](docs/login_and_acl.md)
    - [Multimodal](docs/multimodal.md)
    - [Private endpoints](docs/deploy_private.md)
    - [Agentic retrieval](docs/agentic_retrieval.md)
  - [Sharing deployment environments](docs/sharing_environments.md)
- [Local development](docs/localdev.md)
- [Customizing the ingestion pipeline](docs/customization.md)
- [App architecture](docs/architecture.md)
- [Data ingestion](docs/data_ingestion.md)
- [Evaluation](docs/evaluation.md)
- [Safety evaluation](docs/safety_evaluation.md)
- [Monitoring with Application Insights](docs/monitoring.md)
- [Productionizing](docs/productionizing.md)
- [Alternative RAG chat samples](docs/other_samples.md)

### Resources

- [📖 Docs: Azure AI Search](https://learn.microsoft.com/azure/search/search-what-is-azure-search)
- [📖 Docs: Add Azure AI Search as a knowledge source in Copilot Studio](https://learn.microsoft.com/microsoft-copilot-studio/knowledge-add-azure-ai-search)
- [📖 Docs: Azure OpenAI Service](https://learn.microsoft.com/azure/cognitive-services/openai/overview)
- [📖 Docs: Comparing Azure OpenAI and OpenAI](https://learn.microsoft.com/azure/cognitive-services/openai/overview#comparing-azure-openai-and-openai/)
- [📖 Blog: Access Control in Generative AI applications with Azure AI Search](https://techcommunity.microsoft.com/blog/azure-ai-services-blog/access-control-in-generative-ai-applications-with-azure-ai-search/3956408)

### Getting help

For help with deploying or using this project, please open a [GitHub issue](/issues) or contact the maintainer, Soufyane Dardaz. This repository is maintained independently and isn't supported by Microsoft.

For general questions about developing AI solutions on Azure, the [Azure AI Foundry Developer Community](https://aka.ms/foundry/discord) is a useful (Microsoft-run) resource.

### Note

>Note: The sample PDF documents in the `data` folder contain information generated using a language model (Azure OpenAI Service). That information is for demonstration purposes only, doesn't reflect the opinions or beliefs of any real organization, and shouldn't be relied on as factual.
</content>
