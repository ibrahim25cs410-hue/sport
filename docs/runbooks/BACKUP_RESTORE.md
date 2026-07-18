# MongoDB encrypted backup and restore

## Policy

- Run an encrypted logical backup at least daily; retain 30 daily copies and
  retain a separate monthly copy according to business/legal requirements.
- Store backups outside the application host in versioned, access-controlled
  object storage. The local output directory is staging, not durable storage.
- Keep `BACKUP_ENCRYPTION_KEY` in a secrets manager separate from the backups.
  Limit access to two designated operators and test key recovery quarterly.
- Atlas managed backups/PITR are recommended in addition to these logical backups.
- Never print connection strings, encryption keys, or decrypted archives.

Required tools are MongoDB Database Tools (`mongodump`, `mongorestore`), OpenSSL,
and a Bash environment. Use current supported versions and patch them regularly.

## Backup

First verify the operation without credentials or writes:

```bash
scripts/ops/mongodb-backup.sh --dry-run --output-dir /secure/staging --retention-days 30
```

For the scheduled job, inject secrets into the process environment and run:

```bash
scripts/ops/mongodb-backup.sh --output-dir /secure/staging --retention-days 30
```

The script creates a gzip MongoDB archive encrypted with AES-256-CBC/PBKDF2,
writes atomically, creates a SHA-256 sidecar, and deletes only matching encrypted
backup files older than the retention period. Upload both files to durable object
storage, verify the upload checksum, then remove staging copies according to the
host's secure-deletion policy.

Alert if no successful backup/checksum is uploaded within 26 hours, backup size
changes by more than 50%, or any backup command exits non-zero.

## Quarterly restore drill (isolated database)

Restores are dry-run by default. Never target the production database for a drill.

1. Open an approved change record and choose a recent backup plus its checksum.
2. Provision an isolated Atlas project/cluster or least-privilege drill database.
   Network access must be restricted; disable outbound email/push integrations.
3. Verify the encrypted file:

   ```bash
   sha256sum --check riyada-mongodb-YYYYMMDDTHHMMSSZ.archive.gz.enc.sha256
   ```

4. Preview the restore:

   ```bash
   scripts/ops/mongodb-restore.sh \
     --backup riyada-mongodb-YYYYMMDDTHHMMSSZ.archive.gz.enc \
     --source-db sports-booking \
     --target-db riyada_restore_drill
   ```

5. After two-person review, inject `MONGODB_RESTORE_URI` and
   `BACKUP_ENCRYPTION_KEY`, then execute with the exact confirmation:

   ```bash
   scripts/ops/mongodb-restore.sh \
     --backup riyada-mongodb-YYYYMMDDTHHMMSSZ.archive.gz.enc \
     --source-db sports-booking \
     --target-db riyada_restore_drill \
     --execute --confirm RESTORE:riyada_restore_drill
   ```

6. Validate collection counts, representative users/fields/bookings, indexes,
   date ranges, and referential IDs against production read-only metrics captured
   at the backup time. Do not send notifications or modify production.
7. Record backup timestamp, recovery point objective achieved, restore duration,
   MongoDB tool versions, validation results, operators, and evidence location.
8. Delete the isolated drill database through the approved Atlas process after
   evidence retention. The provided script does not delete databases.

`--drop` is intentionally guarded by the stronger confirmation
`DROP-AND-RESTORE:<target>`. It drops matching collections in the target namespace
and must not be used against production during a drill.

## Production recovery

Declare an incident and stop or isolate writers before recovery. Prefer Atlas
point-in-time recovery when available. Agree on the recovery timestamp, assess
data that will be lost, export salvageable post-backup records, and obtain explicit
incident commander plus database-owner approval. Restore to a new database/cluster,
validate it, then switch the application connection string in a controlled window.
Keep the old database read-only until reconciliation and sign-off. Never run an
in-place `--drop` restore as the first recovery action.
