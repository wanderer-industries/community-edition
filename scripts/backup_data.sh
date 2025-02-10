#!/bin/bash
# backup_all.sh
#
# This script backs up all tables from a Postgres database running in a Docker container.
#
# It supports two possible container names:
#   - For production: wanderer-wanderer_db-1 (target database: postgres)
#   - For development: wanderer_devcontainer-db-1 (target database: wanderer_dev)
#
# The script performs the following steps:
#   1. Auto-detects the running database container from a list of possible container names.
#   2. Automatically determines the target database name based on the container name.
#   3. Runs pg_dump with --data-only (backing up all tables) and writes to a timestamped SQL file.
#   4. After a successful backup, scans the generated SQL file to summarize the number
#      of rows backed up for each table by parsing the COPY commands.
#
# Database credentials (per your Docker Compose configuration):
#   - User: postgres
#   - Password: (set in the container)
#
# Note: This script backs up data only; it assumes that the schema is managed via migrations.

set -e  # Exit immediately on error

# Define colors for pretty logging
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"  # No Color

# Set backup directory (use an absolute path)
BACKUP_DIR="/home/youruser/backups"   # <<<--- Adjust this to your desired backup folder
mkdir -p "$BACKUP_DIR"   # Ensure the directory exists

# Log file path (absolute)
LOGFILE="${BACKUP_DIR}/daily_backup.log"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Starting Data Backup Process (All Tables)${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# List of possible Postgres container names (order does not matter)
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
  echo -e "${RED}[ERROR] No known Postgres container found. Checked: ${POSSIBLE_CONTAINERS[*]}${NC}"
  exit 1
fi

echo -e "${YELLOW}[INFO]${NC} Using database container: ${CONTAINER_NAME}"
echo ""

# Database configuration
DB_USER="postgres"
if [[ "$CONTAINER_NAME" == *"devcontainer"* ]]; then
  DB_NAME="wanderer_dev"
else
  DB_NAME="postgres"
fi

echo -e "${YELLOW}[INFO]${NC} Target database: ${DB_NAME}"
echo ""

# Define output file name with a timestamp (using an absolute path)
OUTPUT_FILE="${BACKUP_DIR}/pg_backup_all_$(date +'%Y%m%d_%H%M%S').sql"
echo -e "${YELLOW}[INFO]${NC} Output file: ${OUTPUT_FILE}"
echo -e "${GREEN}[INFO] Starting backup...${NC}"
echo ""

# Run pg_dump (data-only) for the entire database.
docker exec -i "$CONTAINER_NAME" \
  pg_dump -U "$DB_USER" -d "$DB_NAME" --data-only > "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
  echo -e "${GREEN}[INFO] Backup successful. Output file: ${OUTPUT_FILE}${NC}"
else
  echo -e "${RED}[ERROR] Backup failed.${NC}"
  exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Backup Summary (Rows per table)${NC}"
echo -e "${GREEN}========================================${NC}"

# Parse the backup file to count rows per table.
# This awk script does the following:
#   - When a line starts with "COPY", it extracts the table name and resets the counter.
#   - For subsequent lines (data rows), it increments the counter.
#   - When the terminator "\." is encountered, it prints the table name and row count.
awk '
BEGIN { OFS=": "; current_table=""; row_count=0; }
/^COPY[[:space:]]+/ {
  if (current_table != "") {
    print "Table", current_table, "->", row_count, "row(s) backed up";
  }
  match($0, /^COPY[[:space:]]+([^[:space:]]+)/, arr);
  current_table = arr[1];
  row_count = 0;
  next;
}
/^\\\./ {
  if (current_table != "") {
    print "Table", current_table, "->", row_count, "row(s) backed up";
    current_table = "";
  }
  next;
}
{
  if (current_table != "") {
    row_count++;
  }
}
' "$OUTPUT_FILE"

echo ""
echo -e "${GREEN}[INFO] Backup process complete.${NC}"
