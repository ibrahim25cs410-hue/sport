#!/usr/bin/env bash
set -Eeuo pipefail

EXECUTE=false
DROP=false
BACKUP_FILE=""
SOURCE_DB="${MONGODB_SOURCE_DB:-sports-booking}"
TARGET_DB="${MONGODB_RESTORE_DB:-riyada_restore_drill}"
CONFIRM=""

usage() {
  cat <<'EOF'
Usage: mongodb-restore.sh --backup FILE [options]
  --source-db NAME   Database namespace stored in the archive
  --target-db NAME   Isolated restore target (default: riyada_restore_drill)
  --execute          Perform the restore; otherwise this is a dry-run
  --drop             Drop matching target collections first (requires extra confirmation)
  --confirm TEXT     Required: RESTORE:<target>, or DROP-AND-RESTORE:<target>
EOF
}

while (($#)); do
  case "$1" in
    --backup) BACKUP_FILE="$2"; shift 2 ;;
    --source-db) SOURCE_DB="$2"; shift 2 ;;
    --target-db) TARGET_DB="$2"; shift 2 ;;
    --execute) EXECUTE=true; shift ;;
    --drop) DROP=true; shift ;;
    --confirm) CONFIRM="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$BACKUP_FILE" ]] || { echo "--backup is required." >&2; exit 2; }
[[ "$SOURCE_DB" =~ ^[A-Za-z0-9_-]+$ && "$TARGET_DB" =~ ^[A-Za-z0-9_-]+$ ]] ||
  { echo "Database names may contain letters, numbers, underscore, and hyphen only." >&2; exit 2; }

EXPECTED="RESTORE:$TARGET_DB"
$DROP && EXPECTED="DROP-AND-RESTORE:$TARGET_DB"

if ! $EXECUTE; then
  echo "DRY RUN: would decrypt $BACKUP_FILE and restore $SOURCE_DB.* into $TARGET_DB.*"
  $DROP && echo "DRY RUN: target collections would be dropped before restore"
  echo "To execute, add: --execute --confirm $EXPECTED"
  exit 0
fi

[[ "$CONFIRM" == "$EXPECTED" ]] || { echo "Confirmation must exactly equal $EXPECTED" >&2; exit 2; }
[[ -f "$BACKUP_FILE" ]] || { echo "Backup file does not exist: $BACKUP_FILE" >&2; exit 2; }
: "${MONGODB_RESTORE_URI:?Set MONGODB_RESTORE_URI in the process environment.}"
: "${BACKUP_ENCRYPTION_KEY:?Set BACKUP_ENCRYPTION_KEY in the process environment.}"
command -v mongorestore >/dev/null || { echo "mongorestore is required." >&2; exit 1; }
command -v openssl >/dev/null || { echo "openssl is required." >&2; exit 1; }

RESTORE_ARGS=(
  "--uri=$MONGODB_RESTORE_URI"
  "--archive"
  "--gzip"
  "--nsFrom=$SOURCE_DB.*"
  "--nsTo=$TARGET_DB.*"
)
$DROP && RESTORE_ARGS+=("--drop")

openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 \
  -pass env:BACKUP_ENCRYPTION_KEY \
  -in "$BACKUP_FILE" |
  mongorestore "${RESTORE_ARGS[@]}"

echo "Restore completed into database: $TARGET_DB"
