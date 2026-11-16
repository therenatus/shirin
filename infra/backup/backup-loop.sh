#!/bin/sh
# Runs backup.sh every day at BACKUP_HOUR (local time from TZ).
set -u
HOUR=${BACKUP_HOUR:-3}

echo "Backups daily at ${HOUR}:00 ($TZ), keeping ${BACKUP_KEEP_DAYS:-14} days"
while true; do
  now=$(date +%s)
  target=$(date -d "$(date +%Y-%m-%d) ${HOUR}:00:00" +%s 2>/dev/null \
    || date -D '%Y-%m-%d %H:%M:%S' -d "$(date +%Y-%m-%d) ${HOUR}:00:00" +%s)
  [ "$target" -le "$now" ] && target=$((target + 86400))
  sleep $((target - now))
  sh /backup/backup.sh || true   # failures are alerted inside; keep the loop alive
done
