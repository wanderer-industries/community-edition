#!/bin/bash
#
# daily_backup.sh
#
# This script performs a daily backup by calling the backup_data.sh script,
# and then deletes any backup files older than 7 days.
#
# Adjust the paths below as necessary.
#

# Directory where your backup files are stored.
# (Ensure this is the same directory where backup_data.sh outputs its pg_backup_*.sql files.)
BACKUP_DIR="/app/wanderer/backup"

# Directory where the backup_data.sh script is located.
SCRIPT_DIR="/app/wanderer/scripts"

# Log file for daily backups.
LOGFILE="${BACKUP_DIR}/daily_backup.log"

# Timestamp for logging.
echo "----- $(date) -----" >> "$LOGFILE"

# Run the backup script.
echo "[INFO] Starting backup..." >> "$LOGFILE"
"${SCRIPT_DIR}/backup_data.sh" >> "$LOGFILE" 2>&1

if [ $? -eq 0 ]; then
  echo "[INFO] Backup completed successfully." >> "$LOGFILE"
else
  echo "[ERROR] Backup encountered errors." >> "$LOGFILE"
fi

# Delete backup files older than 7 days.
echo "[INFO] Deleting backups older than 7 days:" >> "$LOGFILE"
find "$BACKUP_DIR" -maxdepth 1 -name "pg_backup_*.sql" -mtime +7 -type f -print -delete >> "$LOGFILE" 2>&1

echo "[INFO] Daily backup process complete." >> "$LOGFILE"
echo "----- End of backup -----" >> "$LOGFILE"
