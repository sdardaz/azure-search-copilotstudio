# Using reasoning models

The default chat-completions model deployed by this project is `gpt-5.4-mini`, a reasoning model. This model is used only during ingestion, by the [figure processing stage](data_ingestion.md#figure-processing) (`app/backend/prepdocslib/mediadescriber.py`), to generate text descriptions of images/figures found in documents when the [multimodal feature](multimodal.md) is enabled. It is not used for end-user chat, since this repository has no chat component.

## Supported models

We support the GPT-5 model family, but not the earlier o-series models, due to API incompatibilities. To switch to a different GPT-5 model, follow the steps in [Using different chat models](deploy_features.md#using-different-chat-models).

## Reasoning effort

The figure-description call in `mediadescriber.py` uses the OpenAI Responses API without an explicit `reasoning_effort` parameter, so the model's own default applies. There is currently no azd environment variable to override the reasoning effort used for ingestion-time figure descriptions.
</content>
