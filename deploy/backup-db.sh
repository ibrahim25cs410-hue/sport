#!/usr/bin/env bash
# Daily database backup — PostgreSQL (pg_dump) or SQLite fallback.
set -euo pipefail

BACKUP_DIR="${RIYADA_BACKUP_DIR:-/var/backups/riyada}"
RETENTION_DAYS="${RIYADA_BACKUP_RETENTION_DAYS:-14}"
STAMP="$(date +%Y%m%d_%H%M%S)"

mkdir -p "$BACKUP_DIR"

# PostgreSQL when env vars are set
if [[ -n "${RIYADA_PG_DB:-}" && -n "${RIYADA_PG_USER:-}" ]]; then
  export PGPASSWORD="${RIYADA_PG_PASSWORD:-}"
  pg_dump -h "${RIYADA_PG_HOST:-127.0.0.1}" -p "${RIYADA_PG_PORT:-5432}" \
    -U "$RIYADA_PG_USER" -Fc "$RIYADA_PG_DB" \
    -f "${BACKUP_DIR}/riyada_${STAMP}.dump"
  gzip -f "${BACKUP_DIR}/riyada_${STAMP}.dump"
  find "$BACKUP_DIR" -name 'riyada_*.dump.gz' -mtime +"$RETENTION_DAYS" -delete
  echo "PostgreSQL backup: ${BACKUP_DIR}/riyada_${STAMP}.dump.gz"
  exit 0
fi

# SQLite fallback
DB_PATH="${RIYADA_DB_PATH:-/var/lib/riyada/sports.db}"
if [[ ! -f "$DB_PATH" ]]; then
  echo "No database found (set RIYADA_PG_* or RIYADA_DB_PATH)"
  exit 1
fi

sqlite3 "$DB_PATH" ".backup '${BACKUP_DIR}/sports_${STAMP}.db'"
gzip -f "${BACKUP_DIR}/sports_${STAMP}.db"
find "$BACKUP_DIR" -name 'sports_*.db.gz' -mtime +"$RETENTION_DAYS" -delete
echo "SQLite backup: ${BACKUP_DIR}/sports_${STAMP}.db.gz"
