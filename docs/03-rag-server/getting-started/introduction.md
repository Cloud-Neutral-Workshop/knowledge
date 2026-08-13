# Introduction

**rag-server** is a Go-based backend for Retrieval-Augmented Generation (RAG). It provides APIs to ingest documents, perform hybrid retrieval (vector + full-text), and optionally call a chat-completion model to answer questions.

Key capabilities from the current codebase:

- **RAG retrieval**: Vector similarity via pgvector plus full-text ranking via PostgreSQL `tsvector` and `zhparser`.
- **Ingestion pipeline**: Sync markdown content from Git repositories, chunk it, embed it, and upsert into Postgres.
- **Model-agnostic**: Uses OpenAI-compatible HTTP APIs for embeddings and chat completions (also supports Ollama/Chutes providers).
- **Operationally simple**: Single stateless service with Postgres as the only required backend.
- **Auth middleware**: Optional JWT validation with cached token lookups in Postgres.

This repository ships two main binaries:

- `rag-server`: The HTTP API service.
- `rag-cli`: A CLI for syncing and ingesting markdown content into the server.

Related tools (optional): `ingest` (batch ingestion) and `ragbench` (benchmark runner).
