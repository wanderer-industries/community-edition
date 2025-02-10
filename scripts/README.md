# Wanderer PostgreSQL Backup and Restore Scripts

Use these scripts at your own risk, no support is provided as issues will be very environment dependent, and  they may behave unexpectedly if there are schema changes between your backup and the current version of wanderer.  This repository contains several Bash scripts for managing PostgreSQL backups and restores in a Dockerized environment. These scripts are designed to work with two different container configurations:

- **Production:** Container named `wanderer-wanderer_db-1` (target database: `postgres`)
- **Development:** Container named `wanderer_devcontainer-db-1` (target database: `wanderer_dev`)

> **Note:** Adjust container names, database names, if needed

## Contents

- **[backup_data.sh](backup_data.sh):**
  Performs a data-only backup of all tables from the PostgreSQL database running in Docker. This script:
  - Auto-detects the running container.
  - Determines the target database (production or development).
  - Runs `pg_dump` with the `--data-only` flag to create a timestamped SQL backup file.
  - Provides a summary of the number of rows backed up per table.

- **[daily_backup.sh](daily_backup.sh):**
  Automates the daily backup process by:
  - Logging the backup process to `daily_backup.log`.
  - Calling `backup_data.sh` to perform the backup.
  - Deleting backup files older than 7 days.

- **[full_backup.sh](full_backup.sh):**
  Creates a full backup (schema and data) of the PostgreSQL database. This script:
  - Checks for the production container first, and falls back to the development container if necessary.
  - Runs `pg_dump` without the `--data-only` flag.
  - Creates a timestamped SQL backup file.

- **[restore_data.sh](restore_data.sh):**
  Restores data from a backup SQL file into the appropriate PostgreSQL Docker container. This script:
  - Extracts the table names from the backup file.
  - Uses `psql` to restore the data.
  - Logs the number of rows inserted per table.

## Prerequisites

- **Docker:** Ensure Docker is installed and running.
- **Docker Containers:**
  The scripts expect the following container names:
  - Production: `wanderer-wanderer_db-1`
  - Development: `wanderer_devcontainer-db-1`
- **Database Setup:**
  - Production database should be named `postgres`.
  - Development database should be named `wanderer_dev`.
- **Permissions:**
  Make sure the scripts are executable:
  ```bash
  chmod +x backup_data.sh daily_backup.sh full_backup.sh restore_data.sh
  ```

## Setup and Configuration

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/wanderer-industries/community-edition
   cd community-edition/scripts
   ```

2. **Adjust File Paths:**
   - In `backup_data.sh`, update the `BACKUP_DIR` variable to the desired backup folder (e.g., `/home/youruser/backups`).
   - In `daily_backup.sh`, verify that the `BACKUP_DIR` and `SCRIPT_DIR` variables are set correctly.

## Usage Instructions

### Data-Only Backup

Run the `backup_data.sh` script to perform a data-only backup:
```bash
./backup_data.sh
```
This will create a timestamped SQL file (e.g., `pg_backup_all_YYYYMMDD_HHMMSS.sql`) and output a summary of row counts per table.

### Full Backup

Run the `full_backup.sh` script to create a full backup (schema and data):
```bash
./full_backup.sh
```
A timestamped SQL file (e.g., `full_backup_YYYYMMDD_HHMMSS.sql`) will be generated.

### Daily Backup

Run the `daily_backup.sh` script to perform a daily backup:
```bash
./daily_backup.sh
```
This script:
- Calls `backup_data.sh`
- Logs the backup process to `daily_backup.log`
- Deletes backup files older than 7 days

### Data Restore

To restore data from a backup file, use the `restore_data.sh` script:
```bash
./restore_data.sh path/to/your_backup_file.sql
```
The script will detect the tables in the backup and restore the data, logging the number of rows inserted per table.

## Automating Daily Backups with Cron

To schedule the daily backup script to run automatically once per day:

1. **Open the Crontab Editor:**
   ```bash
   crontab -e
   ```

2. **Add a Cron Job Entry:**
   For example, to run the `daily_backup.sh` script every day at 2:00 AM, add the following line:
   ```cron
   0 2 * * * /full/path/to/daily_backup.sh >> /full/path/to/daily_backup_cron.log 2>&1
   ```
   Replace `/full/path/to/daily_backup.sh` with the absolute path to your script. Optionally, output can be redirected to a log file (e.g., `daily_backup_cron.log`).

3. **Save and Exit:**
   The cron daemon will now execute the script daily at the scheduled time.

## Additional Notes

- **Logging:**
  Each script logs important actions and errors. For example, `daily_backup.sh` writes logs to `daily_backup.log`. Check these logs for troubleshooting.

- **Docker Container Detection:**
  The scripts automatically detect which Docker container is running. Ensure the correct containers are active before running the scripts.

- **Customization:**
  Feel free to modify the scripts to better suit your environment and backup requirements.

