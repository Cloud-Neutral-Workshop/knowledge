# Errors

Common error responses:

- `400 Bad Request`: malformed JSON body.
- `401 Unauthorized`: missing or invalid `Authorization` header.
- `403 Forbidden`: wrong role, missing role header, or invalid `service` claim.
- `409 Conflict`: admin settings version mismatch.
- `500 Internal Server Error`: unhandled server errors.
- `503 Service Unavailable`: service database not initialized or vector store
  unavailable.

All errors are JSON objects with an `error` field:

```json
{ "error": "message" }
```
