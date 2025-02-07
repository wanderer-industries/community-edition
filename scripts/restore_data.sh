#!/bin/bash
# restore_data.sh
#
# This script restores data from a backup SQL file to a Postgres database running
# in a Docker container.
#
# It supports two possible container names:
#   - For production: wanderer-wanderer_db-1 (target database: postgres)
#   - For development: wanderer_devcontainer-db-1 (target database: wanderer_dev)
#
# Usage:
#   ./restore_data.sh backup_file.sql
#
# The script first lists the table names (by scanning for COPY commands)
# in the backup file, then runs the restore and processes the output
# to report, for each table, how many rows were inserted.
#
# Note: Since the backup was created with --data-only, the target database must
# already have the correct schema.
#
# Improved logging is provided below.

set -e  # Exit immediately on error

# Define colors for pretty logging
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"  # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Starting Data Restore Process${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check for exactly one argument (the backup file)
if [ "$#" -ne 1 ]; then
  echo -e "${RED}Usage: $0 backup_file.sql${NC}"
  exit 1
fi

BACKUP_FILE="$1"

# Verify that the backup file exists.
if [ ! -f "$BACKUP_FILE" ]; then
  echo -e "${RED}Error: Backup file '$BACKUP_FILE' does not exist.${NC}"
  exit 1
fi

echo -e "${YELLOW}[INFO]${NC} Backup file to restore: ${BACKUP_FILE}"
echo ""

# Extract an ordered list of table names from the backup file for reference.
# We assume that each table's data is restored with a line starting with "COPY <table_name> ..."
mapfile -t TABLES_FROM_BACKUP < <(grep -oE '^COPY\s+[^[:space:]]+' "$BACKUP_FILE" | sed -E 's/^COPY\s+//')
if [ ${#TABLES_FROM_BACKUP[@]} -eq 0 ]; then
  echo -e "${RED}[ERROR]${NC} No table COPY commands found in the backup file. Is this a valid pg_dump --data-only file?"
  exit 1
fi

echo -e "${YELLOW}[INFO]${NC} Detected tables in backup (in order):"
for tbl in "${TABLES_FROM_BACKUP[@]}"; do
  echo -e "         ${tbl}"
done
echo ""

# List of possible Postgres container names
POSSIBLE_CONTAINERS=("wanderer-wanderer_db-1" "wanderer_devcontainer-db-1")
CONTAINER_NAME=""

echo -e "${YELLOW}[INFO]${NC} Detecting running Postgres container..."
for container in "${POSSIBLE_CONTAINERS[@]}"; do
  if docker inspect "$container" > /dev/null 2>&1; then
    CONTAINER_NAME="$container"
    break
  fi
done

if [ -z "$CONTAINER_NAME" ]; then
  echo -e "${RED}[ERROR]${NC} No known Postgres container found. Checked: ${POSSIBLE_CONTAINERS[*]}"
  exit 1
fi

echo -e "${YELLOW}[INFO]${NC} Using database container: ${CONTAINER_NAME}"
echo ""

# Database configuration
DB_USER="postgres"
# Automatically determine the target database based on the container name.
if [[ "$CONTAINER_NAME" == *"devcontainer"* ]]; then
  DB_NAME="wanderer_dev"
else
  DB_NAME="postgres"
fi

echo -e "${YELLOW}[INFO]${NC} Target database: ${DB_NAME}"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Starting Restore... Please Wait${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Run the restore command using psql.
# Capture the full output (including errors) into a variable.
OUTPUT=$(docker exec -i "$CONTAINER_NAME" \
  psql -U "$DB_USER" -d "$DB_NAME" -e < "$BACKUP_FILE" 2>&1)
EXIT_CODE=${PIPESTATUS[0]}

# Process the output line-by-line.
# We use a state variable to track the current table.
current_table=""
echo "$OUTPUT" | while IFS= read -r line; do
  # If the line is a COPY command that includes the table name, extract it.
  if [[ "$line" =~ ^COPY[[:space:]]+([^[:space:]]+)[[:space:]]+\(.*FROM[[:space:]]+stdin\; ]]; then
    current_table="${BASH_REMATCH[1]}"
    # (Optionally, you can log that the restore for this table has started.)
    echo -e "${YELLOW}[RESTORE]${NC} Starting restore for table '${current_table}'..."
  # If the line is a COPY summary line with just a number, log it.
  elif [[ "$line" =~ ^COPY[[:space:]]+([0-9]+)[[:space:]]*$ ]]; then
    rows="${BASH_REMATCH[1]}"
    if [ -n "$current_table" ]; then
      echo -e "${YELLOW}[RESTORE]${NC} Table '${current_table}': ${rows} row(s) inserted."
      current_table=""  # Reset after processing a table's summary
    else
      echo -e "${YELLOW}[RESTORE]${NC} (Unknown table): ${rows} row(s) inserted."
    fi
  else
    # Filter out SET and other non-informative lines.
    if [[ "$line" =~ ^(SET|set_config|\\\.) ]]; then
      continue
    fi
    # Otherwise, print the line as-is.
    echo -e "${YELLOW}[RESTORE]${NC} $line"
  fi
done

echo ""
if [ $EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}Restore successful.${NC}"
  echo -e "${GREEN}========================================${NC}"
else
  echo -e "${RED}========================================${NC}"
  echo -e "${RED}Restore failed with exit code $EXIT_CODE.${NC}"
  echo -e "${RED}========================================${NC}"
  exit $EXIT_CODE
fi
