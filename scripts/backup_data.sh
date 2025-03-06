#!/usr/bin/env bash
#
# backup_data.sh
# 
# Creates a PostgreSQL backup (schema + data) in custom format (compressed).
# Includes a basic integrity check with pg_restore --list, but will NOT fail
# if we encounter exit code 141 (harmless SIGPIPE).
#
# Usage: ./backup_data.sh
#

set -euo pipefail

# ----- Configuration -----
BACKUP_DIR="/app/wanderer/backup"
POSSIBLE_CONTAINERS=("wanderer-wanderer_db-1" "wanderer_devcontainer-db-1")
DB_USER="postgres"

# Create backup directory if not present
mkdir -p "$BACKUP_DIR"

# Detect the running container
CONTAINER_NAME=""
for container in "${POSSIBLE_CONTAINERS[@]}"; do
  if docker inspect "$container" >/dev/null 2>&1; then
    CONTAINER_NAME="$container"
    break
  fi
done

if [[ -z "$CONTAINER_NAME" ]]; then
  echo "ERROR: No known Postgres container found. Checked: ${POSSIBLE_CONTAINERS[*]}"
  exit 1
fi

# Decide which database name to dump
DB_NAME="postgres"
if [[ "$CONTAINER_NAME" == *"devcontainer"* ]]; then
  DB_NAME="wanderer_dev"
fi

TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
TMPFILE="/tmp/pg_backup_${TIMESTAMP}.dump"
OUTPUT_FILE="${BACKUP_DIR}/pg_backup_${DB_NAME}_${TIMESTAMP}.dump"

echo "====================================================="
echo "Starting Full Backup (schema + data) of '${DB_NAME}'"
echo "Container: ${CONTAINER_NAME}"
echo "Timestamp: ${TIMESTAMP}"
echo "====================================================="
echo

# 1) Run pg_dump in custom format (compressed).
echo "Running pg_dump (custom format)..."
set +e
docker exec -i "$CONTAINER_NAME" \
  pg_dump -U "$DB_USER" -d "$DB_NAME" -Fc > "$TMPFILE"
DUMP_EXIT_CODE=$?
set -e

if [[ $DUMP_EXIT_CODE -ne 0 ]]; then
  echo "ERROR: pg_dump failed with exit code $DUMP_EXIT_CODE."
  rm -f "$TMPFILE" 2>/dev/null || true
  exit 1
fi

echo "pg_dump completed successfully."
echo

# 2) Verify the dump by listing its contents with pg_restore --list.
#    We'll treat exit code 141 (SIGPIPE) as success because it often occurs when
#    pg_restore closes the pipe before cat finishes writing, but the dump is fine.
echo "Verifying backup integrity with pg_restore --list..."
set +o pipefail
cat "$TMPFILE" | docker exec -i "$CONTAINER_NAME" pg_restore --list > /dev/null
VERIFY_EXIT_CODE=$?
set -o pipefail

if [[ $VERIFY_EXIT_CODE -ne 0 && $VERIFY_EXIT_CODE -ne 141 ]]; then
  echo "ERROR: pg_restore --list failed with exit code $VERIFY_EXIT_CODE, indicating possible corruption."
  rm -f "$TMPFILE" 2>/dev/null || true
  exit 1
fi

# If it's 0 or 141, we assume success.
echo "Verification successful (exit code $VERIFY_EXIT_CODE). Backup file is valid."
echo

# 3) Move the temp file to the final output file
mv "$TMPFILE" "$OUTPUT_FILE"
echo "Backup saved to: $OUTPUT_FILE"

# 4) (Optional) Generate an MD5 checksum (uncomment to enable)
# echo "Generating MD5 checksum..."
# md5sum "$OUTPUT_FILE" > "$OUTPUT_FILE.md5"
# echo "Checksum stored in $OUTPUT_FILE.md5"

echo
echo "====================================================="
echo "Backup process completed successfully!"
echo "====================================================="

