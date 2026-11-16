#!/bin/sh
# Restores a dump into the database. DESTRUCTIVE: replaces current data.
# Usage (on the server, from the project folder):
#   docker compose -f docker-compose.prod.yml --env-file .env.production stop backend
#   docker compose -f docker-compose.prod.yml --env-file .env.production run --rm \
#     -e CONFIRM_RESTORE=yes backup sh /backup/restore.sh /backups/shirin-YYYYMMDD-HHMM.dump
#   docker compose -f docker-compose.prod.yml --env-file .env.production start backend
set -eu
FILE=${1:?usage: restore.sh /backups/shirin-....dump}
[ -f "$FILE" ] || { echo "No such file: $FILE" >&2; exit 1; }
if [ "${CONFIRM_RESTORE:-}" != "yes" ]; then
  echo "This replaces ALL data in $PGDATABASE with $FILE." >&2
  echo "Stop the backend and rerun with -e CONFIRM_RESTORE=yes" >&2
  exit 1
fi
pg_restore --clean --if-exists --no-owner --single-transaction --dbname="$PGDATABASE" "$FILE"
echo "Restored $FILE into $PGDATABASE"
