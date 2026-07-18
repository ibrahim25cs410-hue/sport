#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

DRY_RUN=false
OUTPUT_DIR="${BACKUP_OUTPUT_DIR:-./backups/mongodb}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"

usage() {
  echo "Usage: $0 [--dry-run] [--output-dir DIR] [--retention-days DAYS]"
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --retention-days) RETENTION_DAYS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ "$RETENTION_DAYS" =~ ^[0-9]+$ ]] || { echo "Retention days must be a non-negative integer." >&2; exit 2; }

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
FINAL_PATH="$OUTPUT_DIR/riyada-mongodb-$STAMP.archive.gz.enc"

if $DRY_RUN; then
  echo "DRY RUN: would create an encrypted MongoDB archive at $FINAL_PATH"
  echo "DRY RUN: would remove encrypted archives older than $RETENTION_DAYS days from $OUTPUT_DIR"
  exit 0
fi

: "${MONGODB_URI:?Set MONGODB_URI in the process environment.}"
: "${BACKUP_ENCRYPTION_KEY:?Set BACKUP_ENCRYPTION_KEY in the process environment.}"
command -v mongodump >/dev/null || { echo "mongodump is required." >&2; exit 1; }
command -v openssl >/dev/null || { echo "openssl is required." >&2; exit 1; }

mkdir -p "$OUTPUT_DIR"
TEMP_PATH="$FINAL_PATH.partial"
trap 'rm -f "$TEMP_PATH"' EXIT

mongodump \
  --uri="$MONGODB_URI" \
  --archive \
  --gzip \
  --quiet |
  openssl enc -aes-256-cbc -salt -pbkdf2 -iter 200000 \
    -pass env:BACKUP_ENCRYPTION_KEY \
    -out "$TEMP_PATH"

test -s "$TEMP_PATH"
mv "$TEMP_PATH" "$FINAL_PATH"
sha256sum "$FINAL_PATH" > "$FINAL_PATH.sha256"

find "$OUTPUT_DIR" -type f \
  \( -name 'riyada-mongodb-*.archive.gz.enc' -o -name 'riyada-mongodb-*.archive.gz.enc.sha256' \) \
  -mtime "+$RETENTION_DAYS" -delete

echo "Encrypted backup created: $FINAL_PATH"
echo "Checksum created: $FINAL_PATH.sha256"
