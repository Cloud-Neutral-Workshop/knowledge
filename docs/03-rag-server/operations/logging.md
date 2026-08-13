# Logging

The server uses Go's `slog` with text output.

## Levels

- `debug`, `info`, `warn`, `error`

Configure with:

- `log.level` in the config file, or
- `--log-level` flag on `rag-server`
