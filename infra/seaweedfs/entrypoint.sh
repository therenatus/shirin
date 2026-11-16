#!/bin/sh
# Starts SeaweedFS (master + volume + filer + S3 gateway) in a single container.
#
# The S3 identities file is generated from environment variables so that
# credentials never live in the repository:
#   S3_ACCESS_KEY / S3_SECRET_KEY  - credentials used by the backend
#   S3_BUCKET                      - bucket that is publicly readable (product images)
set -eu

: "${S3_ACCESS_KEY:?S3_ACCESS_KEY is required}"
: "${S3_SECRET_KEY:?S3_SECRET_KEY is required}"
: "${S3_BUCKET:=shirin}"

CONFIG=/tmp/s3.json

cat > "$CONFIG" <<EOF
{
  "identities": [
    {
      "name": "shirin-backend",
      "credentials": [
        { "accessKey": "${S3_ACCESS_KEY}", "secretKey": "${S3_SECRET_KEY}" }
      ],
      "actions": ["Admin", "Read", "List", "Tagging", "Write"]
    },
    {
      "name": "anonymous",
      "actions": ["Read:${S3_BUCKET}"]
    }
  ]
}
EOF
chmod 644 "$CONFIG"

exec /entrypoint.sh server \
  -dir=/data \
  -ip.bind=0.0.0.0 \
  -volume.max=0 \
  -master.telemetry=false \
  -s3 \
  -s3.port=8333 \
  -s3.config="$CONFIG"
