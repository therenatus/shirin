#!/bin/sh
# Proves the latest backup can be restored: restores it into a temporary
# database next to the real one, prints row counts, drops it. Read-only for
# the real data. Run monthly:
#   docker compose -f docker-compose.prod.yml --env-file .env.production run --rm backup sh /backup/verify-restore.sh
set -eu
LATEST=$(ls -1t /backups/shirin-*.dump 2>/dev/null | head -1)
[ -n "$LATEST" ] || { echo "No backups in /backups" >&2; exit 1; }
CHECK_DB=shirin_restore_check

echo "Checking $LATEST"
psql -q -d postgres -c "DROP DATABASE IF EXISTS $CHECK_DB" -c "CREATE DATABASE $CHECK_DB"
trap 'psql -q -d postgres -c "DROP DATABASE IF EXISTS $CHECK_DB"' EXIT
pg_restore --no-owner --single-transaction --dbname="$CHECK_DB" "$LATEST"

psql -d "$CHECK_DB" -At -F ' ' -c "
  SELECT 'users', count(*) FROM users UNION ALL
  SELECT 'orders', count(*) FROM orders UNION ALL
  SELECT 'loyalty_transactions', count(*) FROM loyalty_transactions UNION ALL
  SELECT 'migrations', count(*) FROM _prisma_migrations"
echo "Restore check passed"
