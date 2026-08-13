# Backup and Restore

RAG data and auth cache live in Postgres. Use your standard Postgres backup strategy:

- `pg_dump` for logical backups
- storage-level snapshots for fast recovery

If using Cloud SQL, enable automated backups and point-in-time recovery.
