#!/bin/bash
# full_backup.sh
#
# This script performs a full backup (schema and data) of the production database from a Dockerized
# Postgres instance.
#
# It checks for the production container ("wanderer-wanderer_db-1"). If not found, it falls back
# to the development container ("wanderer_devcontainer-db-1"). For the production container, the target
# database is assumed to be "postgres". For the dev container, the target database is "wanderer_dev".
#
# Usage:
#   ./full_backup.sh
#
# IMPORTANT: If the production container is not available, you will be backing up your development
# database instead.
#

set -e  # Exit immediately if any command fails

# Define container names.
PROD_CONTAINER="wanderer-wanderer_db-1"
DEV_CONTAINER="wanderer_devcontainer-db-1"

# First try to use the production container.
if docker inspect "$PROD_CONTAINER" > /dev/null 2>&1; then
    CONTAINER_NAME="$PROD_CONTAINER"
    TARGET_ENV="production"
else
    if docker inspect "$DEV_CONTAINER" > /dev/null 2>&1; then
        CONTAINER_NAME="$DEV_CONTAINER"
        TARGET_ENV="development"
    else
        echo "Error: No known Postgres container found. Checked: $PROD_CONTAINER and $DEV_CONTAINER"
        exit 1
    fi
fi

echo "Using container: $CONTAINER_NAME ($TARGET_ENV)"

# Set database user.
DB_USER="postgres"

# Determine target database based on environment.
if [ "$TARGET_ENV" = "production" ]; then
    DB_NAME="postgres"
else
    DB_NAME="wanderer_dev"
fi

echo "Target database: $DB_NAME"

# Define output file name with a timestamp.
OUTPUT_FILE="full_backup_$(date +'%Y%m%d_%H%M%S').sql"
echo "Output file: $OUTPUT_FILE"

# Run pg_dump (full backup, including schema and data) inside the container.
docker exec -i "$CONTAINER_NAME" pg_dump -U "$DB_USER" -d "$DB_NAME" > "$OUTPUT_FILE"

echo "Full backup complete. Output written to $OUTPUT_FILE".
