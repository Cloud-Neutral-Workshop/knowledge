# Testing

## Unit tests

```bash
go test ./...
```

## E2E (optional)

The Makefile includes an integration test target that:

- Starts stunnel
- Initializes the DB
- Runs `rag-cli` to ingest a sample file

```bash
make e2e-integration-test
```
