# Deploying with the Azure Developer CLI

This guide includes advanced topics that are not necessary for a basic deployment. If you are new to the project, please consult the main [README](../README.md#deploying) for steps on deploying the project.

* [How does `azd up` work?](#how-does-azd-up-work)
* [Configuring continuous deployment](#configuring-continuous-deployment)
  * [GitHub actions](#github-actions)
  * [Azure DevOps](#azure-devops)

## How does `azd up` work?

The `azd up` command comes from the [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/overview), and takes care of both provisioning the Azure resources and deploying code (in this project, only the cloud-ingestion Azure Functions have deployable code — there is no web app).

The `azd up` command uses the `azure.yaml` file combined with the infrastructure-as-code `.bicep` files in the `infra/` folder. First, it provisions the resources based on `main.bicep` and `main.parameters.json`. At that point, since there is no default value for the OpenAI resource location, it asks you to pick a location from a short list of available regions. Then it will send requests to Azure to provision every resource in the architecture: Azure AI Search, Storage, Azure OpenAI/Foundry, Document Intelligence, the three Function Apps (`USE_CLOUD_INGESTION`, on by default), and the SharePoint sync Logic App (`USE_SHAREPOINT_LOGIC_APP`, on by default).

The Logic App is always provisioned, but it is deployed in a `Disabled` state whenever `SHAREPOINT_HOSTNAME` or `SHAREPOINT_SITE_PATH` is unset, so `azd up` never leaves a workflow polling an invalid Microsoft Graph URL. Set both values and re-run `azd up` to have it deployed `Enabled`. The `SHAREPOINT_LOGIC_APP_NAME` and `SHAREPOINT_LOGIC_APP_STATE` outputs report what was deployed.

With everything provisioned, `azd up` runs the `postprovision` hook (`scripts/prepdocs.sh`/`.ps1`). With cloud ingestion enabled (the default) that script exits immediately with a message to use cloud ingestion instead; if you set `USE_CLOUD_INGESTION=false`, it runs local ingestion to build the Azure AI Search index from the `data` folder.

With cloud ingestion enabled, `azd up` also packages and deploys the `document-extractor`, `figure-processor`, and `text-processor` Function Apps (declared as `services` in `azure.yaml`, each conditioned on `USE_CLOUD_INGESTION`), then runs the `postdeploy` hook (`scripts/setup_cloud_ingestion.sh`/`.ps1`) to configure the Azure AI Search indexer/skillset and trigger an initial indexing run.

Related commands are `azd provision` for just provisioning (if infra files change) and `azd deploy` for just deploying updated Function App code.

## Configuring continuous deployment

This repository includes both a GitHub Actions workflow and an Azure DevOps pipeline for continuous deployment with every push to `main`. The GitHub Actions workflow is the default, but you can switch to Azure DevOps if you prefer.

More details are available in [Learn.com: Configure a pipeline and push updates](https://learn.microsoft.com/azure/developer/azure-developer-cli/configure-devops-pipeline?tabs=GitHub)

### GitHub actions

After you have deployed the app once with `azd up`, you can enable continuous deployment with GitHub Actions.

Run this command to set up a Service Principal account for CI deployment and to store your `azd` environment variables in GitHub Actions secrets:

```shell
azd pipeline config
```

You can trigger the "Deploy" workflow manually from your GitHub actions, or wait for the next push to main.

If you change your `azd` environment variables at any time (via `azd env set` or as a result of provisioning), re-run that command in order to update the GitHub Actions secrets.

### Azure DevOps

After you have deployed the app once with `azd up`, you can enable continuous deployment with Azure DevOps.

Run this command to set up a Service Principal account for CI deployment and to store your `azd` environment variables in GitHub Actions secrets:

```shell
azd pipeline config --provider azdo
```

If you change your `azd` environment variables at any time (via `azd env set` or as a result of provisioning), re-run that command in order to update the GitHub Actions secrets.
