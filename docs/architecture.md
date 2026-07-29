# Application Architecture

This document provides a detailed architectural overview of this project: an Azure AI Search ingestion pipeline that populates an index for Microsoft Copilot Studio's native "Azure AI Search" knowledge source connector. There is no chat UI or chat backend in this repository — Copilot Studio (or any other querying client) is responsible for the conversational experience and for querying the index directly.

For getting started with the application, see the main [README](../README.md).

## Architecture Diagram

The following diagram illustrates the ingestion pipeline components and how they connect to Azure services, plus how a querying client consumes the resulting index.

A detailed, presentation-ready version is maintained as a draw.io source file: **[docs/diagrams/architecture.drawio](diagrams/architecture.drawio)**. Open it with [diagrams.net](https://app.diagrams.net) or the VS Code *Draw.io Integration* extension. It follows Azure Architecture Center conventions — dashed boundary boxes per platform scope, a numbered dataflow cross-referenced to a panel that states the rationale for each step, and cross-cutting notes on identity, networking and observability. Every service card carries a dashed `LOGO` placeholder sized for the official Azure/Microsoft service icons: select the placeholder, delete it, and paste the real icon in its place.

```mermaid
graph TB
    subgraph "Sources"
        LocalFiles[📁 Local data folder]
        SharePoint[📚 SharePoint Online<br/>optional, via Logic App]
    end

    subgraph "Ingestion"
        PrepDocs[⚙️ prepdocs.py<br/>Local ingestion CLI]
        Indexer[🔁 Azure AI Search Indexer<br/>optional cloud ingestion]
        Functions[⚡ Azure Functions<br/>document_extractor<br/>figure_processor<br/>text_processor]
    end

    subgraph "Azure AI Services"
        OpenAI[🤖 Azure OpenAI / Foundry<br/>Embeddings<br/>Vision-capable model for figure descriptions]
        DocIntel[📄 Azure Document Intelligence<br/>Text/Table/Figure Extraction]
        Vision2[👁️ Azure AI Vision<br/>optional, image embeddings]
        CU[🖼️ Azure Content Understanding<br/>optional, media description]
    end

    subgraph "Storage & Index"
        Blob[💾 Azure Blob Storage<br/>Source Documents]
        Search[🔍 Azure AI Search Index<br/>Vector + Full-text + Semantic]
    end

    subgraph "Platform Services"
        AppInsights[📊 Application Insights<br/>Monitoring, optional]
    end

    subgraph "Consumer"
        Copilot[💬 Microsoft Copilot Studio<br/>Azure AI Search knowledge source]
    end

    LocalFiles --> PrepDocs
    SharePoint -.Logic App sync.-> Blob

    PrepDocs --> Blob
    PrepDocs --> DocIntel
    PrepDocs --> OpenAI
    PrepDocs --> Vision2
    PrepDocs --> CU
    PrepDocs --> Search

    Blob --> Indexer
    Indexer --> Functions
    Functions --> DocIntel
    Functions --> OpenAI
    Functions --> Vision2
    Functions --> CU
    Indexer --> Search

    Functions --> AppInsights
    Search --> AppInsights

    Copilot -->|queries| Search

    classDef sourceLayer fill:#e1f5fe
    classDef ingestLayer fill:#f3e5f5
    classDef azureAI fill:#e8f5e8
    classDef azureStorage fill:#fff3e0
    classDef azurePlatform fill:#fce4ec
    classDef consumer fill:#f1f8e9

    class LocalFiles,SharePoint sourceLayer
    class PrepDocs,Indexer,Functions ingestLayer
    class OpenAI,DocIntel,Vision2,CU azureAI
    class Blob,Search azureStorage
    class AppInsights azurePlatform
    class Copilot consumer
```

## Local Ingestion Flow

The following diagram shows how `prepdocs.py` processes documents from the local `data` folder:

```mermaid
sequenceDiagram
    participant D as data/ folder
    participant P as prepdocs.py
    participant DI as Document Intelligence
    participant O as Azure OpenAI
    participant Bl as Blob Storage
    participant S as Azure AI Search

    D->>P: Read documents
    P->>DI: Extract text, tables, figures
    DI-->>P: Return extracted content
    P->>P: Split into chunks
    P->>O: Generate embeddings (and figure descriptions, if multimodal)
    O-->>P: Return vectors / descriptions
    P->>Bl: Upload source document (and images, if multimodal)
    P->>S: Index documents with embeddings
    S-->>P: Confirm indexing complete
```

## Cloud Ingestion Flow

When `USE_CLOUD_INGESTION` is enabled, an Azure AI Search indexer drives the same processing steps using Azure Functions as custom skills, instead of running `prepdocs.py` locally. See [the data ingestion guide](data_ingestion.md#cloud-ingestion) for the full skillset architecture.

## Key Components

### Ingestion (Python)

- **app/backend/prepdocslib**: Shared parsing, chunking, embedding, and Azure AI Search index/indexer management library, used by both local and cloud ingestion. See [AGENTS.md](../AGENTS.md#overall-code-layout) for a file-by-file breakdown.
- **app/backend/prepdocs.py**: CLI entry point for local ingestion.
- **app/backend/setup_cloud_ingestion.py**: Configures the Azure AI Search indexer/skillset for cloud ingestion.
- **app/functions**: Azure Functions implementing the document-extraction, figure-processing, and text-processing custom skills used by cloud ingestion.

### Azure Services Integration

- **Azure AI Search**: Hosts the index queried by Copilot Studio, and (for cloud ingestion) the indexer and skillset.
- **Azure OpenAI / Foundry**: Provides the embedding model, and a vision-capable model used only for ingestion-time figure descriptions.
- **Azure Document Intelligence**: Extracts text, tables, and figures from PDFs, Office documents, and images.
- **Azure Blob Storage**: Stores the original documents that feed ingestion.
- **Application Insights**: Provides monitoring and telemetry for Azure AI Search operations and (if cloud ingestion is enabled) the Function Apps.

## Optional Features

The architecture supports several optional features that can be enabled. For detailed configuration instructions, see the [optional features guide](deploy_features.md):

- **Multimodal ingestion**: Image embeddings and figure descriptions for image-heavy documents.
- **Cloud ingestion**: Runs ingestion as an Azure AI Search indexer + Azure Functions pipeline instead of a local script.
- **Document-level access control**: Restricts which documents a querying user can see.
- **Private endpoints**: Network isolation for enhanced security.
- **SharePoint sync**: An optional Azure Logic App that syncs documents from SharePoint Online into Blob Storage — see [the Copilot Studio integration guide](copilot_studio_integration.md).
</content>
