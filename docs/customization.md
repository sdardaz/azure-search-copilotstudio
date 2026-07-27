# Customizing the ingestion pipeline

> **Tip:** We recommend using GitHub Copilot Agent mode when adding new features or making code changes. This project includes an [AGENTS.md](../AGENTS.md) file that guides Copilot to generate code following project conventions.

This guide provides more details for customizing the data ingestion pipeline.

- [Using your own data](#using-your-own-data)
- [Customizing the search index and chunking](#customizing-the-search-index-and-chunking)
- [Improving retrieval quality](#improving-retrieval-quality)
  - [Configuring parameters in the Azure Portal](#configuring-parameters-in-the-azure-portal)
  - [Other approaches to improve search results](#other-approaches-to-improve-search-results)
  - [Evaluating retrieval quality](#evaluating-retrieval-quality)

## Using your own data

This pipeline is designed to work with any supported document format. The sample data is provided to help you get started quickly, but you can easily replace it with your own data. You'll want to first remove all the existing data, then add your own. See the [data ingestion guide](data_ingestion.md) for more details.

## Customizing the search index and chunking

The ingestion code is stored in the `app/backend/prepdocslib` folder (shared by both local ingestion via `prepdocs.py` and cloud ingestion via the Azure Functions in `app/functions`). Two files are the most common customization points:

- [searchmanager.py](https://github.com/sdardaz/azure-search-copilotstudio/blob/main/app/backend/prepdocslib/searchmanager.py): Defines the Azure AI Search index schema, and builds up the `content` field (and other fields) for each indexed chunk.
- [textsplitter.py](https://github.com/sdardaz/azure-search-copilotstudio/blob/main/app/backend/prepdocslib/textsplitter.py): Splits extracted text into chunks. See the [text splitter documentation](textsplitter.md) for a deep dive into the chunking algorithm.

## Improving retrieval quality

Once you've ingested your own data, you'll want to test search quality directly against the Azure AI Search index — either using the Azure Portal's search explorer, or however your querying client (e.g. Microsoft Copilot Studio) surfaces results — and note any queries that return poor results.

Generally, the best results are found with hybrid search (text + vectors) plus the additional semantic re-ranking step, and that's what's enabled by default. There may be some domains where that combination isn't optimal, however. Check out this blog post which [evaluates AI search strategies](https://techcommunity.microsoft.com/blog/azure-ai-services-blog/azure-ai-search-outperforming-vector-search-with-hybrid-retrieval-and-ranking-ca/3929167) for a better understanding of the differences, or watch this [RAG Deep Dive video on AI Search](https://www.youtube.com/watch?v=ugJy9QkgLYg).

### Configuring parameters in the Azure Portal

You may find it easiest to experiment with search options using the index explorer in the Azure Portal.
Open up the Azure AI Search resource, select the Indexes tab, and select the index there.

Then use the JSON view of the search explorer, and make sure you specify the same options your querying client would use. For example, this query represents a search with semantic ranker configured:

```json
{
  "search": "eye exams",
  "queryType": "semantic",
  "semanticConfiguration": "default",
  "queryLanguage": "en-us",
  "speller": "lexicon",
  "top": 3
}
```

You can also use the `highlight` parameter to see what text is being matched in the `content` field in the search results.

```json
{
    "search": "eye exams",
    "highlight": "content"
    ...
}
```

The search explorer works well for testing text, but is harder to use with vectors, since you'd also need to compute the vector embedding and send it in.

### Other approaches to improve search results

Here are additional ways for improving the search results:

- Adding additional metadata to the "content" field, like the document title, so that it can be matched in the search results. Modify [searchmanager.py](https://github.com/sdardaz/azure-search-copilotstudio/blob/main/app/backend/prepdocslib/searchmanager.py) to include more text in the `content` field.
- Making additional fields searchable by the full text search step. For example, the "sourcepage" field is not currently searchable, but you could make that into a `SearchableField` with `searchable=True` in [searchmanager.py](https://github.com/sdardaz/azure-search-copilotstudio/blob/main/app/backend/prepdocslib/searchmanager.py). A change like that requires [re-building the index](https://learn.microsoft.com/azure/search/search-howto-reindex#change-an-index-schema).
- Using a different splitting strategy for the documents, or modifying the existing ones, to improve the chunks that are indexed. You can find the currently available splitters in [textsplitter.py](https://github.com/sdardaz/azure-search-copilotstudio/blob/main/app/backend/prepdocslib/textsplitter.py).

### Evaluating retrieval quality

Once you've made changes to the index schema or chunking, you'll want to rigorously evaluate the results to see if they've improved. Follow the [evaluation guide](./evaluation.md) to learn how to generate ground truth question/answer pairs from your search index.
</content>
