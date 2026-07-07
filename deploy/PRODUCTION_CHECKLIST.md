# Riyada Production Checklist

## Infrastructure (implemented in repo)

- [x] PostgreSQL provider (`AddRiyadaDatabase`) — SQLite for dev, Npgsql for production
- [x] `docker-compose.yml` — local Postgres 16
- [x] CORS restricted in production via `Cors:AllowedOrigins`
- [x] JWT production guard — rejects default dev key when `ASPNETCORE_ENVIRONMENT=Production`
- [x] API pagination (`page`, `limit`) for fields, bookings, notifications
- [x] Web admin panel (`/admin`) — stats, fields, owners, pending bookings, wallet top-up
- [x] Infinite scroll — mobile + web fields; mobile bookings/history/notifications
- [x] Integration tests — `SportsApp/Tests/Riyada.Api.Tests`
- [x] Store publishing guide — `docs/STORE_PUBLISHING.md`
- [x] Backup script — `deploy/backup-db.sh` (pg_dump + SQLite fallback)

## Before go-live (server ops)

- [ ] DNS A record points `api.yourdomain.com` to the Ubuntu server
- [ ] `production.env.example` copied to `/etc/riyada/riyada.env` with strong `Jwt__Key` (min 32 chars)
- [ ] PostgreSQL user + database created on server
- [ ] Firebase service account JSON at `/etc/riyada/firebase-service-account.json` (chmod 600)
- [ ] Mobile app configured via `flutterfire configure` (bundle ID `iq.riyada.riyada`)
- [ ] `google-services.json` and `GoogleService-Info.plist` in place (not committed to git)
- [ ] API base URL in Flutter points to `https://api.yourdomain.com/api`
- [ ] Android signing keystore + `key.properties` for Play Store
- [ ] iOS certificates + App Store Connect listing (requires Mac)

## Deploy

```bash
chmod +x deploy/deploy.sh deploy/backup-db.sh
sudo ./deploy/deploy.sh api.yourdomain.com
sudo systemctl restart riyada
```

## Verify HTTPS and security

### 1. TLS certificate

```bash
curl -I https://api.yourdomain.com/api/health
openssl s_client -connect api.yourdomain.com:443 -servername api.yourdomain.com </dev/null 2>/dev/null | openssl x509 -noout -dates -issuer
sudo certbot certificates
```

### 2. Firewall (UFW)

```bash
sudo ufw status verbose
```

Expect only: `22/tcp`, `80/tcp`, `443/tcp`.

### 3. Service health

```bash
sudo systemctl status riyada
sudo journalctl -u riyada -n 50 --no-pager
curl https://api.yourdomain.com/api/health
```

### 4. Secrets not in source

```bash
grep -R "Riyada-Flutter-MVP" /var/www/riyada/publish || echo "OK — dev JWT not in publish"
```

Production must use `Jwt__Key` from `/etc/riyada/riyada.env`.

### 5. CORS

From browser console on `https://riyada.iq`, API calls must succeed. Random origins must be blocked.

### 6. Push notifications

1. Log in on a physical device.
2. Confirm `POST /api/users/update-token` returns 200.
3. Create booking → owner receives push.
4. Approve → user receives push.

### 7. Database backups

```bash
sudo /usr/local/bin/riyada-backup-db
ls -lh /var/backups/riyada/
```

### 8. SSL auto-renewal

```bash
sudo certbot renew --dry-run
```

### 9. Run tests before deploy

```bash
cd SportsApp
dotnet test Tests/Riyada.Api.Tests/Riyada.Api.Tests.csproj
cd ../mobile && flutter analyze && flutter test
```

## Environment variables reference

| Variable | Purpose |
|----------|---------|
| `ConnectionStrings__Default` | PostgreSQL connection string (production) |
| `Jwt__Key` | Signing key (min 32 chars, not dev default) |
| `Cors__AllowedOrigins__0` | Allowed web origin |
| `Fcm__CredentialsPath` | Firebase Admin service account JSON |
| `ASPNETCORE_ENVIRONMENT` | Set to `Production` |

## Admin test account (change password before launch)

| Email | Password |
|-------|----------|
| admin@riyada.iq | admin123 |

## Firebase setup (one-time)

1. Firebase Console → Service accounts → Generate new private key.
2. Copy JSON to `/etc/riyada/firebase-service-account.json`.
3. Flutter: `cd mobile && dart pub global activate flutterfire_cli && flutterfire configure`.
4. Enable Cloud Messaging API in Google Cloud Console.

## Hardening

- Swagger disabled in production (`IsDevelopment()` gate).
- CORS restricted to configured origins in production.
- Rate limiting enabled via `AddRiyadaRateLimiting`.
- Monitor disk: PostgreSQL data + `/var/backups/riyada/`.
