#!/usr/bin/env bash
#
# restore_data.sh
#
# Restores a PostgreSQL database from a custom-format dump (schema + data).
# This script will:
#   1. Detect the database container
#   2. Drop and recreate the public schema (or optionally drop the entire DB if desired)
#   3. Use pg_restore to load all data + schema from the dump into the target DB
#
# Usage: ./restore_data.sh path/to/backup.dump
#

set -euo pipefail

# ----- Configuration -----
POSSIBLE_CONTAINERS=("wanderer-wanderer_db-1" "wanderer_devcontainer-db-1")
DB_USER="postgres"

# Check args
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 backup_file.dump"
  exit 1
fi

BACKUP_FILE="$1"
if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "ERROR: Backup file '$BACKUP_FILE' not found."
  exit 1
fi

# Detect container
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

# Determine target database name
DB_NAME="postgres"
if [[ "$CONTAINER_NAME" == *"devcontainer"* ]]; then
  DB_NAME="wanderer_dev"
fi

echo "====================================================="
echo "Restoring backup into '${DB_NAME}'"
echo "Container: ${CONTAINER_NAME}"
echo "Backup file: ${BACKUP_FILE}"
echo "====================================================="
echo

# 1) Drop and recreate the public schema to wipe out existing data/schema objects.
#    Alternatively, you could drop/recreate the entire DB, but that requires either
#    connecting to a different DB or including CREATE DATABASE in the dump.
echo "Dropping and recreating public schema..."
docker exec -i "$CONTAINER_NAME" \
  psql -U "$DB_USER" -d "$DB_NAME" \
  -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

echo

# 2) Restore from the custom-format dump using pg_restore.
#    We pass the dump via stdin to avoid copying the file into the container.
echo "Starting restore with pg_restore..."
set +e
cat "$BACKUP_FILE" | docker exec -i "$CONTAINER_NAME" \
  pg_restore -U "$DB_USER" -d "$DB_NAME" --format=custom
RESTORE_EXIT_CODE=$?
set -e

if [[ $RESTORE_EXIT_CODE -ne 0 ]]; then
  echo "ERROR: pg_restore failed with exit code $RESTORE_EXIT_CODE"
  exit 1
fi

echo
echo "====================================================="
echo "Restore completed successfully!"
echo "====================================================="

