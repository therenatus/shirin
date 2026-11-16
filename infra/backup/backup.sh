#!/bin/sh
# One database backup: dump, check it can be read, rotate old ones.
# Env: PGHOST PGUSER PGPASSWORD PGDATABASE, BACKUP_KEEP_DAYS (14),
#      BACKUP_PING_URL (optional), ALERT_TELEGRAM_BOT_TOKEN/CHAT_ID (optional)
set -eu

DIR=/backups
KEEP=${BACKUP_KEEP_DAYS:-14}
STAMP=$(date +%Y%m%d-%H%M)
FILE="$DIR/shirin-$STAMP.dump"

alert() {
  echo "BACKUP FAILED: $1" >&2
  if [ -n "${ALERT_TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${ALERT_TELEGRAM_CHAT_ID:-}" ]; then
    wget -qO- --timeout=10 \
      --header 'Content-Type: application/json' \
      --post-data "{\"chat_id\":\"$ALERT_TELEGRAM_CHAT_ID\",\"text\":\"⚠️ Shirin: бэкап базы не удался: $1\"}" \
      "https://api.telegram.org/bot$ALERT_TELEGRAM_BOT_TOKEN/sendMessage" >/dev/null || true
  fi
  exit 1
}

mkdir -p "$DIR"
# Custom format: compressed, restorable table by table with pg_restore
pg_dump --format=custom --no-owner --file="$FILE.tmp" || alert "pg_dump: код $?"
# A dump that pg_restore can't list is useless: check before keeping it
pg_restore --list "$FILE.tmp" >/dev/null || alert "файл дампа повреждён"
mv "$FILE.tmp" "$FILE"
echo "Backup written: $FILE ($(du -h "$FILE" | cut -f1))"

find "$DIR" -name 'shirin-*.dump' -type f -mtime +"$KEEP" -print -delete
find "$DIR" -name '*.tmp' -type f -mmin +120 -delete

if [ -n "${BACKUP_PING_URL:-}" ]; then
  wget -qO- --timeout=10 "$BACKUP_PING_URL" >/dev/null || echo "Ping failed (backup itself is fine)" >&2
fi
