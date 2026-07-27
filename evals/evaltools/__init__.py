"""Vendored subset of the ai-rag-chat-evaluator (`evaltools`) package.

Only the pieces this repo needs are included: the markdown summary/diff
reviewers used to compare historical evaluation result folders. The
evaluation runner (which POSTed questions to a live chat endpoint), its
metrics, service setup helpers, the synthetic-data generation module, and the
Textual TUI reviewers are omitted, since this repo no longer runs a chat
backend to evaluate against.

Upstream: https://github.com/Azure-Samples/ai-rag-chat-evaluator (MIT License,
Microsoft Corporation).
"""
