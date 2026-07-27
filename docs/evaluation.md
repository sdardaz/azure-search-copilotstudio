# Evaluation: generating ground truth data

This repository has no chat backend to evaluate end-to-end answers from, so the evaluation flow here is limited to generating ground truth question/answer pairs from your Azure AI Search index. If you have a separate chat client (e.g. Microsoft Copilot Studio, or your own app) querying the index, you can use these ground truth pairs with a tool like [the AI RAG Chat evaluator](https://github.com/Azure-Samples/ai-rag-chat-evaluator) to evaluate that client's answer quality end to end.

* [Deploy an evaluation model](#deploy-an-evaluation-model)
* [Setup the evaluation environment](#setup-the-evaluation-environment)
* [Generate ground truth data](#generate-ground-truth-data)

## Deploy an evaluation model

1. Run this command to tell `azd` to deploy a reasoning model for evaluation:

    ```shell
    azd env set USE_EVAL true
    ```

2. Set the evaluation model capacity to the highest possible value to ensure that ground truth generation runs relatively quickly, since it can be rate limited during a bulk run.

    ```shell
    azd env set AZURE_OPENAI_EVAL_DEPLOYMENT_CAPACITY 100
    ```

    By default, the evaluation deployment uses `gpt-5.4` version `2026-03-05`. To change those settings, set the azd environment variables `AZURE_OPENAI_EVAL_MODEL` and `AZURE_OPENAI_EVAL_MODEL_VERSION` to the desired values.

3. Then, run the following command to provision the model:

    ```shell
    azd provision
    ```

## Setup the evaluation environment

Make a new Python virtual environment and activate it. This is currently required due to incompatibilities between the dependencies of the evaluation script and the main project.

```bash
python -m venv .evalenv
```

```bash
source .evalenv/bin/activate
```

Install all the dependencies for the evaluation script by running the following command:

```bash
pip install -r evals/requirements.txt
```

## Generate ground truth data

Generate ground truth data by running the following command:

```bash
python evals/generate_ground_truth.py --numquestions=200 --numsearchdocs=1000
```

The options are:

* `numquestions`: The number of questions to generate. We suggest at least 200.
* `numsearchdocs`: The number of documents (chunks) to retrieve from your search index. You can leave off the option to fetch all documents, but that will significantly increase time it takes to generate ground truth data. You may want to at least start with a subset.
* `kgfile`: An existing RAGAS knowledge base JSON file, which is usually `ground_truth_kg.json`. You may want to specify this if you already created a knowledge base and just want to tweak the question generation steps.
* `groundtruthfile`: The file to write the generated ground truth answwers. By default, this is `evals/ground_truth.jsonl`.

🕰️ This may take a long time, possibly several hours, depending on the size of the search index.

Review the generated data in `evals/ground_truth.jsonl` after running that script, removing any question/answer pairs that don't seem like realistic user input.

These ground truth question/answer pairs, generated directly from your Azure AI Search index content, can then be used with a bulk-evaluation tool of your choice (such as [the AI RAG Chat evaluator](https://github.com/Azure-Samples/ai-rag-chat-evaluator)) against whatever chat client queries your index.
