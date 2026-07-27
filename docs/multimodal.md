# Support for multimodal documents

This repository includes an optional feature that uses multimodal embedding models and a multimodal LLM
to better handle documents that contain images, such as financial reports with charts and graphs.

With this feature enabled, the data ingestion process will extract images from your documents
using Document Intelligence, store the images in Azure Blob Storage, vectorize the images using the Azure AI Vision service, generate a text description of each image/figure using a vision-capable Azure OpenAI model (or Azure AI Content Understanding), and store the image embeddings and descriptions in the Azure AI Search index.

With this feature enabled, the following changes are made during ingestion:

* **Search index**: We add a new field "images" to the Azure AI Search index to store information about the images associated with a chunk. The field is a complex field that contains the embedding returned by the multimodal Azure AI Vision API, the bounding box, and the URL of the image in Azure Blob Storage.
* **Data ingestion**: In addition to the usual data ingestion flow, the document extraction process extracts images from the documents using Document Intelligence, stores the images in Azure Blob Storage with a citation at the top border, generates a text description of each figure (see the [figure processing stage](data_ingestion.md#figure-processing)), and vectorizes the images using the Azure AI Vision service.

The generated figure descriptions are merged into the chunk's text content, so a querying client (such as Microsoft Copilot Studio) can answer questions about figures using text search alone, even without using the image embeddings.

## Prerequisites

* The use of a vision-capable model for figure descriptions. The default model for the repository is currently `gpt-5.4-mini`, which supports multimodal inputs. This model is used only during ingestion, to describe figures — not for end-user chat, since this repository has no chat component.

## Deployment

1. **Enable multimodal capabilities**

   Set the azd environment variable to enable the multimodal feature:

   ```shell
   azd env set USE_MULTIMODAL true
   ```

2. **Provision the multimodal resources**

   Either run `azd up` if you haven't run it before, or run `azd provision` to provision the multimodal resources. This will create a new Azure AI Vision account and update the Azure AI Search index to include the new image embedding field.

3. **Re-index the data:**

   If you have already indexed data, you will need to re-index it to include the new image embeddings.
   We recommend creating a new Azure AI Search index to avoid conflicts with the existing index.

   ```shell
   azd env set AZURE_SEARCH_INDEX multimodal-index
   ```

   Then delete the `.md5` hash files in the data folder(s) and run the data ingestion process again to re-index the data:

   Linux/Mac:

   ```shell
   ./scripts/prepdocs.sh
   ```

   Windows:

   ```shell
   .\scripts\prepdocs.ps1
   ```

## Compatibility

* This feature can be combined with [media description via Azure Content Understanding](deploy_features.md#enabling-media-description-with-azure-content-understanding), which enables only a subset of these capabilities (description only, no image embeddings).
</content>
