# Troubleshooting deployment

If you are experiencing an error when deploying this ingestion pipeline using the [deployment steps](../README.md#deploying), this guide will help you troubleshoot common issues.

1. You're attempting to create resources in regions not enabled for Azure OpenAI (e.g. East US 2 instead of East US), or where the model you're trying to use isn't enabled. See [this matrix of model availability](https://aka.ms/oai/models).

1. You've exceeded a quota, most often number of resources per region. See [this article on quotas and limits](https://aka.ms/oai/quotas).

1. You're getting "same resource name not allowed" conflicts. That's likely because you've run the sample multiple times and deleted the resources you've been creating each time, but are forgetting to purge them. Azure keeps resources for 48 hours unless you purge from soft delete. See [this article on purging resources](https://learn.microsoft.com/azure/cognitive-services/manage-resources?tabs=azure-portal#purge-a-deleted-resource).

1. You see `CERTIFICATE_VERIFY_FAILED` when the `prepdocs.py` script runs. That's typically due to incorrect SSL certificates setup on your machine. Try the suggestions in this [StackOverflow answer](https://stackoverflow.com/a/43855394).

1. You see a `RoleAssignmentExists` error (HTTP 409) when re-deploying after switching between local development and CI/CD pipelines (or vice versa). This happens because the role assignment GUID changes when the `principalType` changes between `User` and `ServicePrincipal`. Running `azd up` again should resolve the issue, as the template now generates separate role assignments for each principal type.

1. You see a `Conflict` error (HTTP 409) about Cognitive Services resources when re-deploying after a previous `azd down`. Azure soft-deletes Cognitive Services resources for 48 days, blocking re-creation with the same name. To resolve this, set the `RESTORE_COGNITIVE_SERVICES` environment variable to `true` before re-deploying:

   ```shell
   azd env set RESTORE_COGNITIVE_SERVICES true
   azd up
   ```

   After the resources are restored, set it back to `false` to avoid issues on subsequent deployments:

   ```shell
   azd env set RESTORE_COGNITIVE_SERVICES false
   ```

   Alternatively, you can manually purge the soft-deleted resources via [the Azure CLI](https://learn.microsoft.com/azure/ai-services/manage-resources?tabs=azure-portal#purge-a-deleted-resource) and re-deploy without the flag.
