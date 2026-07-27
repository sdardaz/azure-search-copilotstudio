<!--
---
name: Document-level access control for the Azure AI Search index
description: This guide demonstrates how to add optional document-level access control to the documents ingested into Azure AI Search, so that querying clients (like Microsoft Copilot Studio) can restrict search results to documents a given user is permitted to see.
languages:
- python
- bicep
- azdeveloper
products:
- azure-cognitive-search
- azure
page_type: sample
urlFragment: azure-search-openai-demo-document-security
---
-->

# Document-level access control for the Azure AI Search index

This project can optionally attach document-level access control metadata to every chunk it indexes in Azure AI Search, using the [built-in document access control from Azure AI Search](https://learn.microsoft.com/azure/search/search-query-access-control-rbac-enforcement). This restricts which documents a given user or group can see when a querying client (such as Microsoft Copilot Studio, or any other app) searches the index with that user's identity.

This document covers how that access-control metadata (`oids` and `groups` fields) gets attached to documents during ingestion. It does **not** cover authenticating end users — this repository has no chat UI or login flow. How a querying client authenticates and supplies the appropriate authorization header when querying Azure AI Search depends on that client; see [the Copilot Studio integration guide](copilot_studio_integration.md) for how Copilot Studio connects to the index.

## Table of Contents

- [Enabling the access control system](#enabling-the-access-control-system)
- [Adding data with document level access control](#adding-data-with-document-level-access-control)
  - [Cloud ingestion with Azure Data Lake Storage Gen2](#cloud-ingestion-with-azure-data-lake-storage-gen2) (Recommended)
    - [Using your own ADLS Gen2 storage account](#using-your-own-adls-gen2-storage-account)
    - [Verifying ACL filtering](#verifying-acl-filtering)
  - [Using the Add Documents API](#using-the-add-documents-api)
    - [Enabling global access on documents without access control](#enabling-global-access-on-documents-without-access-control)
- [Migrate to built-in document access control](#migrate-to-built-in-document-access-control)
- [Environment variables reference](#environment-variables-reference)

## Enabling the access control system

1. **Enable the access control system:**

    ```shell
    azd env set AZURE_USE_AUTHENTICATION true
    ```

1. (Optional) **Enforce access control**
  To ensure that queries against the index are restricted to only documents the querying user has access to, run:

    ```shell
    azd env set AZURE_ENFORCE_ACCESS_CONTROL true
    ```

1. (Optional) **Allow global document access**
  To allow documents that have no document-specific access controls assigned to be treated as globally accessible, run:

    ```shell
    azd env set AZURE_ENABLE_GLOBAL_DOCUMENT_ACCESS true
    ```

1. **Enable access control on your search index (if it already exists)**

    If your search index already exists, you need to enable access control on it:

    ```shell
    python ./scripts/manageacl.py --acl-action enable_acls
    ```

    If your index does not exist yet, access control will be automatically enabled when the index is created during deployment.

1. **Deploy and ingest**
  Run `azd up` to provision/update infrastructure and ingest data with access control metadata attached.

## Adding data with document level access control

The sample supports 2 main strategies for adding data with document level access control.

- [Using cloud ingestion with Azure Data Lake Storage Gen2](#cloud-ingestion-with-azure-data-lake-storage-gen2) (Recommended). Uses Azure Functions and an Azure AI Search indexer to automatically extract ACLs from files stored in Azure Data Lake Storage Gen2 and index them with document-level access control.
- [Using the Add Documents API](#using-the-add-documents-api). Sample scripts are provided which use the Azure AI Search Service Add Documents API to directly manage access control information on _existing documents_ in the index.

### Cloud ingestion with Azure Data Lake Storage Gen2

The recommended approach for document-level access control is to use cloud ingestion with Azure Data Lake Storage Gen2. This approach uses Azure Functions to process documents and an Azure AI Search indexer to automatically extract ACLs from files and index them with document-level access control.

#### How it works

1. Documents are stored in an [Azure Data Lake Storage Gen2](https://learn.microsoft.com/azure/storage/blobs/data-lake-storage-introduction) account with [hierarchical namespace enabled](https://learn.microsoft.com/azure/storage/blobs/data-lake-storage-namespace).
2. [Access Control Lists (ACLs)](https://learn.microsoft.com/azure/storage/blobs/data-lake-storage-access-control) are set on files and folders to control which users and groups can access each document.
3. An Azure AI Search indexer monitors the storage account for new or updated files.
4. When files are detected, custom Azure Function skills process the documents:
   - **Document Extractor**: Downloads and parses the document, extracting ACLs directly from Azure Data Lake Storage Gen2.
   - **Figure Processor**: Processes images and figures in the document.
   - **Text Processor**: Chunks the text and generates embeddings.
5. The extracted ACLs (user IDs and group IDs) are stored in the search index alongside the document content.

#### ACL handling

The document extractor parses the POSIX-style ACL string from ADLS Gen2 (e.g., `user::rwx,user:oid:r--,group::r-x,group:gid:r--,other::---`) and extracts:

- **User IDs (oids)**: User object IDs with read permission (`user:<oid>:r--` or `user:<oid>:r-x`)
- **Group IDs (groups)**: Group object IDs with read permission (`group:<gid>:r--` or `group:<gid>:r-x`)
- **Global access**: If the "other" ACL entry has read permission (`other::r--` or `other::r-x`) **and** `AZURE_ENABLE_GLOBAL_DOCUMENT_ACCESS` is set to `true`, the document is treated as globally accessible and indexed with `oids: ["all"]` and `groups: ["all"]`. This allows any authenticated user to access the document. Both conditions must be met - the ACL permission alone is not sufficient. See [Understanding access control in ADLS Gen2](https://github.com/hurtn/datalake-on-ADLS/blob/master/Understanding%20access%20control%20and%20data%20lake%20configurations%20in%20ADLS%20Gen2.md#option-2-the-other-acl-entry) for more details about the "other" ACL entry.

> **Note:** The document extractor only reads ACLs directly from each file - it does not consider directory-level ACL inheritance or propagation. If a user or group has read permission on the file's ACL, they will be granted access to that document in Azure AI Search. Make sure ACLs are set explicitly on each file, not just on parent directories.

#### Setup

1. **Enable cloud ingestion and ACLs**

   ```shell
   azd env set USE_CLOUD_INGESTION true
   azd env set USE_CLOUD_INGESTION_ACLS true
   azd env set AZURE_USE_AUTHENTICATION true
   azd env set AZURE_ENFORCE_ACCESS_CONTROL true
   ```

2. **Configure the storage account**

   When `USE_CLOUD_INGESTION_ACLS` is enabled, a separate Azure Data Lake Storage Gen2 storage account with hierarchical namespace is automatically provisioned. This is required for ACL support.

3. **Deploy the application**

   ```shell
   azd up
   ```

   This provisions the Azure Functions (document-extractor, figure-processor, text-processor), creates an ADLS Gen2 storage account for documents with ACLs, configures the search indexer with ADLS Gen2 data source type, and sets up managed identity authentication.

4. **Upload documents with ACLs**

   Upload documents to the provisioned ADLS storage account (`AZURE_ADLS_STORAGE_ACCOUNT`) and set ACLs on them.

   You can use the [adlsgen2setup.py](/scripts/adlsgen2setup.py) script to upload sample data with ACLs:

   ```shell
   python scripts/adlsgen2setup.py './data/*' --data-access-control './scripts/sampleacls.json' -v
   ```

   Alternatively, use [Azure Storage Explorer](https://azure.microsoft.com/products/storage/storage-explorer/) or the Azure portal to upload files and manage ACLs.

5. **Trigger ingestion**

   Run the cloud ingestion setup script to trigger the indexer:

   ```shell
   ./scripts/setup_cloud_ingestion.sh
   ```

   Or trigger the indexer directly from the Azure portal.

#### Enabling global access for specific documents

To make specific documents accessible to all authenticated users (global access), you must configure the following:

1. **Set the environment variable**: Enable global document access support:

   ```shell
   azd env set AZURE_ENABLE_GLOBAL_DOCUMENT_ACCESS true
   azd up
   ```

2. **Set the "other" ACL on the file**: In ADLS Gen2, the "other" ACL entry controls access for any authenticated user who doesn't match a specific user or group ACL. Grant read permission to "other" on files that should be globally accessible. See [Set ACLs in Azure Data Lake Storage Gen2](https://learn.microsoft.com/azure/storage/blobs/data-lake-storage-acl-azure-portal) for instructions.

3. **Reset and rerun the indexer**: If documents have already been indexed, reset the indexer to update the permissions on existing documents. Reset the indexer from the Azure portal or by running the setup script again.

When all conditions are met, the document extractor will index the document with `oids: ["all"]` and `groups: ["all"]`, making it accessible in Azure AI Search to any authenticated user. See [Azure AI Search Document-level permissions](https://learn.microsoft.com/azure/search/search-index-access-control-lists-and-rbac-push-api#special-acl-values-all-and-none) for more details about the special `["all"]` value.

#### Using your own ADLS Gen2 storage account

If you already have an Azure Data Lake Storage Gen2 account with documents and ACLs configured, you can use it instead of having the deployment provision a new one.

1. **Enable cloud ingestion with existing ADLS**

   ```shell
   azd env set USE_CLOUD_INGESTION true
   azd env set USE_CLOUD_INGESTION_ACLS true
   azd env set USE_EXISTING_ADLS_STORAGE true
   azd env set AZURE_ADLS_GEN2_STORAGE_ACCOUNT <your-existing-adls-account-name>
   ```

   If your ADLS account is in a different resource group than the one being provisioned, also set:

   ```shell
   azd env set AZURE_ADLS_GEN2_STORAGE_RESOURCE_GROUP <your-adls-resource-group>
   ```

   If not specified, the resource group defaults to the main resource group being provisioned.

2. **Deploy the application**

   ```shell
   azd up
   ```

   The deployment will automatically assign the necessary RBAC roles on your ADLS storage account:
   - **Storage Blob Data Reader**: Granted to Azure AI Search and Azure Functions identities
   - **Storage Blob Data Owner**: Granted to your user account (for managing ACLs)

   The search indexer will be configured to use your existing ADLS account as the data source.

#### Verifying ACL filtering

To verify that ACL filtering is working correctly on your search index, use the [verify_search_index_acls.py](/scripts/verify_search_index_acls.py) script.

This script tests three different search scenarios:

1. **Search without ACL headers/tokens**: Returns only documents accessible without user credentials (documents without ACL restrictions or with global access `["all"]`)
2. **Search with user token**: Uses `x-ms-query-source-authorization` header to filter results based on the current user's permissions
3. **Search with elevated read**: Uses `x-ms-enable-elevated-read` header to bypass ACL filtering and show all documents with their `oids` and `groups` fields (useful for debugging). This step requires the "Search Index Data Contributor" role, which is now automatically assigned to the developer that runs `azd up`.

Run the script after deploying and ingesting documents:

```shell
python scripts/verify_search_index_acls.py
```

Compare the results between the three scenarios to verify that:

- Documents with ACLs are being filtered correctly based on user permissions
- The `oids` and `groups` fields are populated correctly for each document
- Global access documents (with `["all"]` values) are accessible to all authenticated users

### Using the Add Documents API

Manually enable document level access control on a search index and manually set access control values using the [manageacl.py](/scripts/manageacl.py) script.

Prior to running the script:

- Run `azd up` or use `azd env set` to manually set the `AZURE_SEARCH_SERVICE` and `AZURE_SEARCH_INDEX` azd environment variables
- Activate the Python virtual environment for your shell session

The script supports the following commands. All commands support `-v` for verbose logging.

- `python ./scripts/manageacl.py --acl-action enable_acls`: Creates the required `oids` (User ID) and `groups` (Group IDs) [security filter](https://learn.microsoft.com/azure/search/search-security-trimming-for-azure-search) fields for document level access control on your index, as well as the `storageUrl` field for storing the Blob storage URL. Does nothing if these fields already exist.

  Example usage:

  ```shell
  python ./scripts/manageacl.py -v --acl-action enable_acls
  ```

- `python ./scripts/manageacl.py --acl-type [oids or groups]--acl-action view --url [https://url.pdf]`: Prints access control values associated with either User IDs or Group IDs for the document at the specified URL.

  Example to view all Group IDs:

  ```shell
  python ./scripts/manageacl.py -v --acl-type groups --acl-action view --url https://st12345.blob.core.windows.net/content/Benefit_Options.pdf
  ```

- `python ./scripts/manageacl.py --acl-type [oids or groups] --acl-action add --acl [ID of group or user] --url [https://url.pdf]`: Adds an access control value associated with either User IDs or Group IDs for the document at the specified URL.

  Example to add a Group ID:

  ```shell
  python ./scripts/manageacl.py -v --acl-type groups --acl-action add --acl xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx --url https://st12345.blob.core.windows.net/content/Benefit_Options.pdf
  ```

- `python ./scripts/manageacl.py --acl-type [oids or groups]--acl-action remove_all --url [https://url.pdf]`: Removes all access control values associated with either User IDs or Group IDs for a specific document.

  Example to remove all Group IDs:

  ```shell
  python ./scripts/manageacl.py -v --acl-type groups --acl-action remove_all --url https://st12345.blob.core.windows.net/content/Benefit_Options.pdf
  ```

- `python ./scripts/manageacl.py --url [https://url.pdf] --acl-type [oids or groups]--acl-action remove --acl [ID of group or user]`: Removes an access control value associated with either User IDs or Group IDs for a specific document.

  Example to remove a specific User ID:

  ```shell
  python ./scripts/manageacl.py -v --acl-type oids --acl-action remove --acl xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx --url https://st12345.blob.core.windows.net/content/Benefit_Options.pdf
  ```

#### Enabling global access on documents without access control

- `python ./scripts/manageacl.py --acl-action enable_global_access`: Set the special [`["all"]`](https://learn.microsoft.com/azure/search/search-index-access-control-lists-and-rbac-push-api#special-acl-values-all-and-none) on the `oids` (User ID) and `groups` (Group IDs) security filter fields in your index on documents that do not have any existing `oids` or `groups` access control. This will enable any signed-in user to query these documents.

## Migrate to built-in document access control

Previous versions of the sample used [security filters](https://learn.microsoft.com/azure/search/search-security-trimming-for-azure-search) to implement document-level access control.
To support [built-in access control](https://learn.microsoft.com/azure/search/search-query-access-control-rbac-enforcement):

1. [Permission filtering](https://learn.microsoft.com/azure/search/search-index-access-control-lists-and-rbac-push-api#create-an-index-with-permission-filter-fields) is enabled on the index.
2. Whatever client queries the index (e.g. Copilot Studio) is responsible for setting the [x-ms-query-source-authorization](https://learn.microsoft.com/azure/search/search-query-access-control-rbac-enforcement#how-query-time-enforcement-works) header with a token representing the querying user, when `AZURE_ENFORCE_ACCESS_CONTROL` is enabled on the index.

When `AZURE_ENABLE_GLOBAL_DOCUMENT_ACCESS` was enabled, previous versions of the sample interpreted no access control on a document as meaning that the document was globally available. Built-in document access control requires [`["all"]`](https://learn.microsoft.com/azure/search/search-index-access-control-lists-and-rbac-push-api#special-acl-values-all-and-none) to be set for each globally available document. You can run a [one-time migration](#enabling-global-access-on-documents-without-access-control) on your existing index to enable global access for these documents.

## Environment variables reference

The following environment variables are used to setup the optional document level access control system:

- `AZURE_USE_AUTHENTICATION`: Enables document level access control metadata during ingestion. Set to true before running `azd up`.
- `AZURE_ENFORCE_ACCESS_CONTROL`: Enforces access-control filtering fields on the index. Set to true before running `azd up`.
- `AZURE_ENABLE_GLOBAL_DOCUMENT_ACCESS`: Enables prepdocs upload code to support setting user ids and group ids to `["all"]` when uploading documents that have no access control assigned. This will enable the built-in document level access control to return these documents if `AZURE_ENFORCE_ACCESS_CONTROL` is enabled. If you are migrating from a previous version where this was not required, you'll have to perform a [one-time migration](#migrate-to-built-in-document-access-control) to enable global document access.
- `USE_CLOUD_INGESTION_ACLS`: (Optional) Set to `true` to enable automatic ACL extraction from ADLS Gen2 files during cloud ingestion. Requires `USE_CLOUD_INGESTION` to also be set to `true`. Used with [cloud ingestion](#cloud-ingestion-with-azure-data-lake-storage-gen2).
- `USE_EXISTING_ADLS_STORAGE`: (Optional) Set to `true` to use an existing ADLS Gen2 storage account instead of provisioning a new one. Used with [cloud ingestion](#using-your-own-adls-gen2-storage-account).
- `AZURE_ADLS_GEN2_STORAGE_ACCOUNT`: (Optional) Name of existing [Data Lake Storage Gen2 storage account](https://learn.microsoft.com/azure/storage/blobs/data-lake-storage-introduction) for storing sample data with [access control lists](https://learn.microsoft.com/azure/storage/blobs/data-lake-storage-access-control). Required when `USE_EXISTING_ADLS_STORAGE` is `true`. Used with [cloud ingestion](#cloud-ingestion-with-azure-data-lake-storage-gen2).
- `AZURE_ADLS_GEN2_STORAGE_RESOURCE_GROUP`: (Optional) Resource group containing the existing ADLS Gen2 storage account. Defaults to the main resource group if not specified. Used with [cloud ingestion](#using-your-own-adls-gen2-storage-account).
- `AZURE_ADLS_GEN2_FILESYSTEM`: (Optional) Name of existing [Data Lake Storage Gen2 filesystem](https://learn.microsoft.com/azure/storage/blobs/data-lake-storage-introduction) for storing sample data with [access control lists](https://learn.microsoft.com/azure/storage/blobs/data-lake-storage-access-control). Used with [cloud ingestion](#cloud-ingestion-with-azure-data-lake-storage-gen2).
</content>
