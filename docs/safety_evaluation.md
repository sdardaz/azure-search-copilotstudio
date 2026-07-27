# Evaluating RAG answer safety

The `evals/safety_evaluation.py` script in this repository simulates adversarial users and evaluates the safety of answers returned by a running chat endpoint (by default, `http://localhost:50505/chat`). Since this repository no longer includes a chat backend — it's an ingestion-only pipeline for Microsoft Copilot Studio — that flow is not applicable here.

If you have a separate chat client (e.g. Microsoft Copilot Studio, or your own app) querying the Azure AI Search index populated by this pipeline, you can still run `evals/safety_evaluation.py` against that client's endpoint by passing `--target_url` to point at it. See the script's `--help` output for the current options.

For generating ground truth question/answer pairs from your search index (independent of any chat endpoint), see [the evaluation guide](evaluation.md).

## Resources

To learn more about the Azure AI services used by the adversarial simulator and safety evaluators:

* [Generate simulated data for evaluation](https://learn.microsoft.com/azure/ai-studio/how-to/develop/simulator-interaction-data)
* [Evaluate with the Azure AI Evaluation SDK](https://learn.microsoft.com/azure/ai-studio/how-to/develop/evaluate-sdk)
</content>
