# Connecting Copilot Studio to this Azure AI Search index

This project provisions and populates an Azure AI Search index (see the [main README](/README.md) and [data ingestion](./data_ingestion.md)). It does not include a chat UI or API - instead, Microsoft Copilot Studio connects directly to the Azure AI Search index as a native knowledge source, and (optionally) a Logic App keeps that index in sync with a SharePoint Online document library.

- [Add the index as a Copilot Studio knowledge source](#add-the-index-as-a-copilot-studio-knowledge-source)
  - [Prerequisites on the index](#prerequisites-on-the-index)
  - [Create the connection](#create-the-connection)
  - [Citations](#citations)
- [Keeping the index in sync with SharePoint](#keeping-the-index-in-sync-with-sharepoint)
  - [Why a Logic App instead of the SharePoint indexer](#why-a-logic-app-instead-of-the-sharepoint-indexer)
  - [Enable it](#enable-it)
  - [One-time permission grant](#one-time-permission-grant)
  - [What it does every run](#what-it-does-every-run)
  - [Error handling](#error-handling)
  - [Monitoring](#monitoring)
  - [Supported file types](#supported-file-types)

## Add the index as a Copilot Studio knowledge source

### Prerequisites on the index

Copilot Studio's Azure AI Search connector expects a plain vector index (not the "agentic knowledge base" feature this repo can also provision - see [agentic_retrieval.md](./agentic_retrieval.md)). The index this project creates already satisfies what Copilot Studio needs:

- A searchable text field (`content`)
- A filterable/retrievable title field
- Integrated vectorization, if `USE_INTEGRATED_VECTORIZATION`/cloud ingestion is enabled, so Copilot Studio can vectorize the incoming prompt with the same embedding model used at ingestion time
- Semantic ranker, if `AZURE_SEARCH_SEMANTIC_RANKER` is not `disabled`
- `metadata_storage_path` (populated for blob-sourced documents), which Copilot Studio reads as the citation URL - see [Citations](#citations)

### Create the connection

1. In [Microsoft Copilot Studio](https://copilotstudio.microsoft.com), open the agent, then **Add knowledge** (from Overview, Knowledge, or a generative answers node's properties) → **Featured** → **Azure AI Search**.
2. **Create new connection**, authentication type **Microsoft Entra ID Integrated** (preferred) or **Access Key**.
   - Only add the connection through this dialog. A manually-constructed endpoint/key connection can leave Copilot Studio with a broken data connection that can't be edited or deleted from the UI - if that happens, reset the agent's external access or recreate the agent.
3. Supply the Azure AI Search endpoint (`https://<AZURE_SEARCH_SERVICE>.search.windows.net`, from the `AZURE_SEARCH_SERVICE` azd output) and, for key-based auth, an admin key.
4. Select the index (`AZURE_SEARCH_INDEX`, default `gptkbindex`) and add it to the agent.
5. Test the knowledge source from the **Knowledge** page once its status changes from *In progress* to *Ready*.

### Citations

Copilot Studio uses `metadata_storage_path` as the citation link when present, or otherwise any field that looks like a full URL. Make sure whoever queries the agent actually has access to what these URLs point to (a blob URL behind a private endpoint, or a SharePoint URL that requires sign-in, won't be openable by every user).

## Keeping the index in sync with SharePoint

If your source documents live in a SharePoint Online document library, this repo deploys a Logic App that mirrors them into the Blob Storage container the [cloud ingestion pipeline](./data_ingestion.md#cloud-ingestion) already reads from - so parsing, chunking, figure description, and embeddings all continue to run through the *existing* Document Intelligence/Functions skillset. The Logic App's only job is getting bytes from SharePoint into that container; it does no parsing of its own.

This requires [cloud ingestion](./data_ingestion.md#enabling-cloud-ingestion) (`USE_CLOUD_INGESTION=true`) to be enabled, since that's what owns the Blob → indexer → skillset pipeline and the indexer this Logic App triggers. Both flags default to `true`, so `azd up` provisions the Logic App out of the box.

### Why a Logic App instead of the SharePoint indexer

Azure AI Search has two other ways to pull from SharePoint: a native [SharePoint Online indexer](https://learn.microsoft.com/azure/search/search-how-to-index-sharepoint-online) (preview) and the [Import Data wizard's Logic Apps connector](https://learn.microsoft.com/azure/search/search-how-to-index-logic-apps). Both are reasonable choices too, but they each bring their own chunking/vectorization pipeline, separate from the multi-format (PDF/DOCX/PPTX/XLSX/images/HTML/JSON/CSV/text), multimodal figure-description pipeline this repo already has. The Logic App here is deliberately "dumb" on purpose - it only moves bytes, so every file lands in the *same* battle-tested ingestion path as manually-uploaded documents.

It's also built on plain Microsoft Graph, Storage, and Azure AI Search REST calls authenticated with the Logic App's own system-assigned managed identity, rather than the SharePoint Online *API connection* connector. That means the workflow is fully expressed in the Bicep template (reviewable, diffable, no per-user OAuth connection for the workflow itself to lose access to) - the trade-off is one manual one-time permission grant, below.

### Enable it

The Logic App is provisioned by every `azd up`, but it is deployed **`Disabled`** until you tell it which site to read. Set these azd environment variables before `azd up` (or `azd env set` + `azd provision`) to have it deployed `Enabled` and start polling:

| Variable | Purpose |
| --- | --- |
| `USE_CLOUD_INGESTION` | Must be `true` (the default) - this Logic App feeds the cloud-ingestion indexer |
| `USE_SHAREPOINT_LOGIC_APP` | `true` (the default) to provision the Logic App; set `false` to skip it entirely |
| `SHAREPOINT_HOSTNAME` | **Required to enable the workflow.** Tenant hostname, e.g. `contoso.sharepoint.com` |
| `SHAREPOINT_SITE_PATH` | **Required to enable the workflow.** Server-relative site path, e.g. `/sites/Marketing` |
| `SHAREPOINT_FOLDER_PATH` | Optional; restrict to a folder within the site's default document library, e.g. `/Shared Documents/Policies` |
| `SHAREPOINT_SYNC_INTERVAL_MINUTES` | Polling interval, default `15` |
| `SHAREPOINT_NOTIFICATION_WEBHOOK_URL` | Optional Teams incoming webhook (or any URL accepting `{"text": "..."}` POSTs), notified on failures |

The Bicep module lives at `infra/app/logicapp-sharepoint-ingestion.bicep`. After deployment, `azd env get-values` reports `SHAREPOINT_LOGIC_APP_NAME` and `SHAREPOINT_LOGIC_APP_STATE` (`Enabled` or `Disabled`) so you can confirm which mode you got.

### One-time permission grant

The Logic App authenticates to Microsoft Graph with its system-assigned managed identity - there's no interactive SharePoint connection to sign in. After `azd provision`, an admin must grant that identity a Graph **application** permission once:

1. Get the Logic App's identity: `azd env get-values | grep SHAREPOINT_LOGIC_APP_NAME`, then find its managed identity's object ID in the Azure Portal (Logic App → Identity).
2. Grant either:
   - **`Sites.Selected`** (recommended, least privilege), then use the [Graph API to grant that identity access to just the one site](https://learn.microsoft.com/sharepoint/dev/solution-guidance/security-apponly-azuread#option-1-access-to-a-specific-site-with-sitesselected) (`POST /sites/{site-id}/permissions`), or
   - **`Sites.Read.All`** (simpler, grants read access to every SharePoint site in the tenant).
3. Grant admin consent for the permission.

Without this, the workflow's first HTTP call (resolving the site) fails with a 403/401 - check the errors table (below) or the Logic App's run history.

### What it does every run

1. Resolve the SharePoint site ID from `SHAREPOINT_HOSTNAME`/`SHAREPOINT_SITE_PATH` via Microsoft Graph.
2. Read the last saved delta link from an `sharepointsyncstate` Azure Table (or start a fresh [delta query](https://learn.microsoft.com/graph/api/driveitem-delta) on first run).
3. Page through the delta results. For each item: download it and upload it to the cloud-ingestion Blob container if it's a file with a supported extension, or delete the corresponding blob if the item was deleted in SharePoint (the existing indexer's soft-delete detection then removes it from the index).
4. Save the new delta link for the next run.
5. Trigger the cloud-ingestion indexer to run immediately, rather than waiting for its own schedule.

### Error handling

- Every file's download/upload runs inside a scope; if it fails, the run continues with the next file instead of aborting, and the failure (file name, URL, error) is logged to a `sharepointingestionerrors` Azure Table in the same storage account.
- Triggering the indexer treats a 409 (already running from a previous cycle) as expected, not an error.
- If `SHAREPOINT_NOTIFICATION_WEBHOOK_URL` is set, both per-file and indexer-run failures also post a short message to that webhook.

### Monitoring

- **Per-file/indexer failures**: query the `sharepointingestionerrors` table (Storage Explorer, Azure Portal, or `az storage entity query`).
- **Whole-run failures** (e.g. the workflow itself timing out or erroring outside the per-file scopes): the Logic App's own run history in the Azure Portal, or an Azure Monitor alert rule on its `RunsFailed` metric.
- **Sync state**: the `sharepointsyncstate` table holds the current delta link and last successful run time; deleting its single row forces a full resync on the next trigger.

### Supported file types

Same list the [cloud ingestion pipeline](./data_ingestion.md#supported-document-formats) already parses: PDF, DOCX, PPTX, XLSX, PNG/JPG, HTML, JSON, CSV, TXT, MD. Anything else is skipped (not logged as an error, since it's an expected, static filter rather than a failure) - update the `supportedExtensions` parameter in `logicapp-sharepoint-ingestion.bicep` if you extend `build_file_processors()` in `prepdocslib/servicesetup.py` to cover more formats.
