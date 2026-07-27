# Local development of the ingestion pipeline

After deploying the infrastructure with `azd up`, you can continue to develop and re-run ingestion locally. This guide explains how to run ingestion locally, including using a local OpenAI-compatible model to save costs.

* [Running ingestion from the command line](#running-ingestion-from-the-command-line)
* [Using a local OpenAI-compatible API](#using-a-local-openai-compatible-api)
  * [Using Ollama server](#using-ollama-server)
  * [Using llamafile server](#using-llamafile-server)

## Running ingestion from the command line

You can only run ingestion locally **after** having successfully run the `azd up` command at least once, since it depends on the provisioned resources. If you haven't yet, follow the steps in [Deploying](../README.md#deploying) above.

1. Run `azd auth login` if you have not logged in recently.
2. Run the ingestion script:

    Windows:

    ```shell
    ./scripts/prepdocs.ps1
    ```

    Linux/Mac:

    ```shell
    ./scripts/prepdocs.sh
    ```

See [AGENTS.md](../AGENTS.md#running-ingestion-locally) for how to iterate on cloud ingestion (`setup_cloud_ingestion.py`) or an individual Azure Function.

## Using a local OpenAI-compatible API

You may want to save costs by running ingestion against a local LLM server, such as
[llamafile](https://github.com/Mozilla-Ocho/llamafile/), instead of Azure OpenAI. Note that a local LLM
will generally be slower and not as sophisticated, which matters most for the figure-description step of [multimodal ingestion](multimodal.md).

Once the local LLM server is running and serving an OpenAI-compatible endpoint, set these environment variables:

```shell
azd env set USE_VECTORS false
azd env set OPENAI_HOST local
azd env set OPENAI_BASE_URL <your local endpoint>
azd env set AZURE_OPENAI_CHATGPT_MODEL local-model-name
```

Then re-run the ingestion script.

⚠️ Limitations:

* Your search index must be text only (no vectors), since the index would otherwise be populated with OpenAI-generated embeddings and a local OpenAI host can't generate those in a compatible way.
* If multimodal ingestion is enabled, figure descriptions will only work if the local model supports vision inputs.

> [!NOTE]
> You must set `OPENAI_HOST` back to a non-local value ("azure", "azure_custom", or "openai")
> before running `azd up` or `azd provision`, since cloud ingestion (if enabled) can't access your local server.

### Using Ollama server

For example, to point at a local Ollama server running the `llama3.1:8b` model:

```shell
azd env set OPENAI_HOST local
azd env set OPENAI_BASE_URL http://localhost:11434/v1
azd env set AZURE_OPENAI_CHATGPT_MODEL llama3.1:8b
azd env set USE_VECTORS false
```

If you're running the app inside a VS Code Dev Container, use this local URL instead:

```shell
azd env set OPENAI_BASE_URL http://host.docker.internal:11434/v1
```

### Using llamafile server

To point at a local llamafile server running on its default port:

```shell
azd env set OPENAI_HOST local
azd env set OPENAI_BASE_URL http://localhost:8080/v1
azd env set USE_VECTORS false
```

Llamafile does *not* require a model name to be specified.

If you're running the app inside a VS Code Dev Container, use this local URL instead:

```shell
azd env set OPENAI_BASE_URL http://host.docker.internal:8080/v1
```
</content>
