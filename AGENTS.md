# Instructions for Coding Agents

This file contains instructions for developers working on this Azure AI Search ingestion pipeline for Microsoft Copilot Studio. It covers the overall code layout, how to add new data, how to add new azd environment variables, and how to add tests for new features.

Always keep this file up to date with any changes to the codebase or development process.
If necessary, edit this file to ensure it accurately reflects the current state of the project.

## Overall code layout

This repository is a pure document-ingestion pipeline that populates an Azure AI Search index for Microsoft Copilot Studio's native "Azure AI Search" knowledge source connector. There is no chat UI and no chat backend — see [docs/copilot_studio_integration.md](docs/copilot_studio_integration.md) for how the resulting index is consumed.

* app: Contains the ingestion application code.
  * app/backend: Contains the Python ingestion code.
    * app/backend/prepdocslib: Contains the document ingestion library used by both local and cloud ingestion
      * app/backend/prepdocslib/blobmanager.py: Manages uploads to Azure Blob Storage
      * app/backend/prepdocslib/cloudingestionstrategy.py: Builds the Azure AI Search indexer and skillset for the cloud ingestion pipeline
      * app/backend/prepdocslib/csvparser.py: Parses CSV files
      * app/backend/prepdocslib/embeddings.py: Generates embeddings for text and images using Azure OpenAI
      * app/backend/prepdocslib/figureprocessor.py: Generates figure descriptions for both local ingestion and the cloud figure-processor skill
      * app/backend/prepdocslib/fileprocessor.py: Orchestrates parsing and chunking of individual files
      * app/backend/prepdocslib/filestrategy.py: Strategy for uploading and indexing files (local ingestion)
      * app/backend/prepdocslib/htmlparser.py: Parses HTML files
      * app/backend/prepdocslib/integratedvectorizerstrategy.py: Strategy using Azure AI Search integrated vectorization
      * app/backend/prepdocslib/jsonparser.py: Parses JSON files
      * app/backend/prepdocslib/listfilestrategy.py: Lists files from local filesystem or Azure Data Lake
      * app/backend/prepdocslib/mediadescriber.py: Interfaces for describing images (Azure OpenAI GPT-4o, Content Understanding)
      * app/backend/prepdocslib/page.py: Data classes for pages, images, and chunks
      * app/backend/prepdocslib/parser.py: Base parser interface
      * app/backend/prepdocslib/pdfparser.py: Parses PDFs using Azure Document Intelligence or local parser
      * app/backend/prepdocslib/searchmanager.py: Manages Azure AI Search index creation and updates
      * app/backend/prepdocslib/servicesetup.py: Shared service setup helpers for OpenAI, embeddings, blob storage, etc.
      * app/backend/prepdocslib/strategy.py: Base strategy interface for document ingestion
      * app/backend/prepdocslib/textparser.py: Parses plain text and markdown files
      * app/backend/prepdocslib/textprocessor.py: Processes text chunks for cloud ingestion (merges figures, generates embeddings)
      * app/backend/prepdocslib/textsplitter.py: Splits text into chunks using different strategies
    * app/backend/prepdocs.py: CLI entry point for local ingestion (uploads/indexes files from disk).
    * app/backend/setup_cloud_ingestion.py: Sets up the Blob → Indexer → Azure Functions skillset cloud ingestion pipeline.
  * app/functions: Azure Functions used for cloud ingestion custom skills (document extraction, figure processing, text processing). Each function bundles a synchronized copy of `prepdocslib`; run `python scripts/copy_prepdocslib.py` to refresh the local copies if you modify the library.
* infra: Contains the Bicep templates for provisioning Azure resources (Azure AI Search, Storage, Azure OpenAI/Foundry, Document Intelligence, Vision, Content Understanding, and the optional cloud-ingestion Function Apps).
* evals: Contains evaluation configs, datasets, and results.
  * evals/results: Contains raw per-run eval output folders. Use descriptive setup-based names for repeated runs, such as `gpt54-low-top5-run1`.
  * evals/results_summaries: Contains derived grouped summaries such as `baseline.json` and `baseline.md`.
  * evals/results_comparisons: Reserved for derived candidate-vs-baseline comparison artifacts.
  * evals/eval_compare.py: Compares eval result folders and reports averages, confidence intervals, and paired significance tests.
* tests: Contains the test code, including e2e tests, app integration tests, and unit tests.

## Adding new data

New files should be added to the `data` folder, and then either run scripts/prepdocs.sh or scripts/prepdocs.ps1 to ingest the data.

## Adding a new azd environment variable

An azd environment variable is stored by the azd CLI for each environment. It is passed to the "azd up" command and can configure both provisioning options and application settings.
When adding new azd environment variables, update:

1. infra/main.parameters.json : Add the new parameter with a Bicep-friendly variable name and map to the new environment variable
1. infra/main.bicep: Add the new Bicep parameter at the top, and add it to the `appEnvVariables` object
1. .azdo/pipelines/azure-dev.yml: Add the new environment variable under `env` section
1. .github/workflows/azure-dev.yml: Add the new environment variable under `env` section

You may also need to update:

1. app/backend/prepdocs.py: If the variable is used in local ingestion, retrieve it from environment variables here. Not always needed.
1. app/backend/setup_cloud_ingestion.py: If the variable is used by cloud ingestion, retrieve it from environment variables here. Not always needed.

## When adding tests for a new feature

All tests are in the `tests` folder and use the pytest framework.
There are three styles of tests:

* e2e tests: These use playwright to run the app in a browser and test the UI end-to-end. They are in e2e.py and they mock the backend using the snapshots from the app tests. (Before running e2e tests, make sure to run `npm run build` in app/frontend first to build the frontend code.)
* app integration tests: Mostly in test_app.py, these test the app's API endpoints and use mocks for services like Azure OpenAI and Azure Search.
* unit tests: The rest of the tests are unit tests that test individual functions and methods. They are in test_*.py files.

When adding a new feature, add tests for it in the appropriate file.
If the feature is a UI element, add an e2e test for it.
If it is an API endpoint, add an app integration test for it.
If it is a function or method, add a unit test for it.
Use mocks from tests/conftest.py to mock external services. Prefer mocking at the HTTP/requests level when possible.

When you're running tests, make sure you activate the .venv virtual environment first:

```shell
source .venv/bin/activate
```

To check for coverage, run the following command:

```shell
pytest --cov --cov-report=annotate:cov_annotate
```

Open the cov_annotate directory to view the annotated source code. There will be one file per source file. If a file has 100% source coverage, it means all lines are covered by tests, so you do not need to open the file.

For each file that has less than 100% test coverage, find the matching file in cov_annotate and review the file.

If a line starts with a ! (exclamation mark), it means that the line is not covered by tests. Add tests to cover the missing lines.

## Sending pull requests

When sending pull requests, make sure to follow the PULL_REQUEST_TEMPLATE.md format.

## Upgrading dependencies

### Python backend dependencies

To upgrade a particular package in the backend, use the following command, replacing `<package-name>` with the name of the package you want to upgrade:

```shell
cd app/backend && uv pip compile requirements.in -o requirements.txt --python-version 3.10 --upgrade-package <package-name>
```

After upgrading, run tests to verify compatibility:

```shell
source .venv/bin/activate
pytest tests/
```

## Checking Python type hints

To check Python type hints, use the following command:

```shell
ty check
```

Note that we do not currently enforce type hints in the tests folder, as it would require adding a lot of `# type: ignore` comments to the existing tests.
We only enforce type hints in the main application code and scripts.

## Python code style

Do not use single underscores in front of "private" methods or variables in Python code. We do not follow that convention in this codebase, since this is an application and not a library.

## Running ingestion locally

There is no server process to start — this repository's only "runtime" is the ingestion scripts, run one-off against the resources provisioned by `azd up`.

* **Local ingestion** (default, `USE_CLOUD_INGESTION` unset or `false`): run `./scripts/prepdocs.sh` (or `scripts/prepdocs.ps1` on Windows), which sets up a Python virtual environment and invokes `app/backend/prepdocs.py` with the current `azd` environment's variables. Extra CLI args pass through, e.g. `scripts/prepdocs.sh --removeall`.
* **Cloud ingestion** (`USE_CLOUD_INGESTION=true`): run `./scripts/setup_cloud_ingestion.sh` (or `.ps1`), which invokes `app/backend/setup_cloud_ingestion.py` to (re)configure the Azure AI Search indexer/skillset and trigger an indexing run. The actual per-document processing happens in the Azure Functions under `app/functions/`, not locally.

Both scripts require `azd up` (or at least `azd provision`) to have been run first, since they read connection info from the current `azd` environment.

To iterate on an individual Azure Function locally (e.g. `document_extractor`), use the standard [Azure Functions Core Tools](https://learn.microsoft.com/azure/azure-functions/functions-run-local) workflow (`func start`) from within `app/functions/<function_name>`.

## Deploying the application

To deploy the application, use the `azd` CLI tool. Make sure you have the latest version of the `azd` CLI installed. Then, run the following command from the root of the repository:

```shell
azd up
```

That command will BOTH provision the Azure resources AND deploy the application code.

If you only changed the Bicep templates and want to re-provision the Azure resources, run:

```shell
azd provision
```

If you only changed the application code and want to re-deploy the code, run:

```shell
azd deploy
```

If you are using cloud ingestion and only want to deploy individual functions, run the necessary deploy commands, for example:

```shell
azd deploy document-extractor
azd deploy figure-processor
azd deploy text-processor
```
