# PostgreSQL Restore Script (restore_postgres.sh) Runbook

## Overview

The `restore_postgres.sh` script restores PostgreSQL databases from backup files.
It supports compressed backups (.gz, .zip) and dry-run mode for simulation.
It sends notifications via a configurable external script.

## Usage

Basic usage:
```
./restore_postgres.sh <database_name> <backup_file> [options]
```

Options:
- `--dry-run` : Simulate the restore without applying changes.
- `--host=<host>` : Override default database host (default: "localhost").
- `--port=<port>` : Override default database port (default: 5432).
- `--user=<user>` : Override default database user (default: "postgres").

## Monitoring & Alerts

- Restore logs are stored as `restore_log_YYYYMMDD_HHMMSS.log` in the script directory.
- Monitor logs for success and failure messages.
- Alerts will notify on restore failures, backup file issues, and notification script errors.
- Dry-run executions generate informational alerts.
- Notification script configuration can be found in the script header or config file (refer to script comments for details).

## Troubleshooting

- Check log files for detailed errors.
- Ensure backup file exists and is in supported format (.sql, .dump, .gz, .zip).
- Verify notification script is executable and correctly configured.
- For compressed backups, ensure required tools (gunzip, unzip) are installed.
- Use dry-run mode to test restore operation without impact.
- Common errors include missing backup files, permission denied, and decompression failures. Check logs for specific messages.

## Failover Drill Procedure

- Use `--dry-run` option to simulate restore during failover drills.
- Confirm dry-run alerts and notifications are received.
- Review logs and validate no changes were applied.

## Contact & Escalation

- In case of restore failures or persistent alerts, contact the DBA team at dba-team@example.com.
- Escalate unresolved issues to the on-call SRE engineer.

---

*Document last updated: 2026-04-30*
