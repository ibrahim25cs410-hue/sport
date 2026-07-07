# Riyada — Local Windows Server Guide

Use this when your **laptop is the API server** for teammates at University of Mosul (campus Wi‑Fi) or at home.

---

## Part 1: Firebase push notifications (already implemented)

| Layer | Status |
|-------|--------|
| `PushNotificationService` (Firebase Admin) | `SportsApp/Infrastructure/Services/PushNotificationService.cs` |
| Booking → owner push (new booking) | `QueueNotifyOwner` in `BookingService` |
| Booking → user push (approve/reject) | `QueueNotifyUser` in `BookingService` |
| Token registration API | `POST /api/users/update-token` |
| Flutter sync on login/bootstrap | `FcmService.syncTokenWithServer` in `auth_provider.dart` |

**Enable pushes on your laptop:**

1. Firebase Console → Project Settings → Service accounts → **Generate new private key**.
2. Save JSON somewhere safe, e.g. `D:\sport\secrets\firebase-service-account.json`.
3. Copy `local/riyada.local.env.example` → `local/riyada.local.env` and set:
   ```
   Fcm__CredentialsPath=D:\sport\secrets\firebase-service-account.json
   Fcm__ProjectId=your-project-id
   ```
4. Mobile: run `flutterfire configure` once (see `mobile/FIREBASE_SETUP.md`).
5. Teammates’ phones must reach **your API URL** for token upload; push delivery itself goes through Google FCM (internet), not your laptop.

---

## Part 2: Local production-ready server

### 1. Kestrel vs IIS on a laptop

**Recommendation: Kestrel directly (via `run.bat`), not IIS.**

| Approach | Verdict |
|----------|---------|
| **Kestrel + `run.bat`** | Best for a dev/team laptop — simple, matches `dotnet run`, easy logs, binds `0.0.0.0:61082` |
| **IIS reverse proxy** | Overkill unless you already use IIS for other sites; more setup, little gain for one API |
| **Windows Service** | Optional later if you want auto-start on boot without a console window |

Your API already listens on **port 61082** (`launchSettings.json`). The scripts use that port (not 5000).

**Start the server:**

```bat
cd d:\sport\local
run.bat
```

Keep the window open (or minimize it). The script restarts the API if it crashes.

**Optional — prevent sleep while serving:**

```bat
powercfg /change standby-timeout-ac 0
powercfg /change monitor-timeout-ac 30
```

Or: Settings → System → Power → **Never** sleep when plugged in.

---

### 2. Network access for your team

#### A. Same building / campus Wi‑Fi (simplest)

1. Start API: `local\run.bat`
2. **Allow firewall** (Admin PowerShell):
   ```powershell
   cd d:\sport\local
   Set-ExecutionPolicy -Scope Process Bypass
   .\allow-firewall.ps1
   ```
3. Find your laptop IP:
   ```bat
   ipconfig
   ```
   Use **IPv4** on Wi‑Fi (e.g. `192.168.1.45`).

4. Teammates configure the Flutter app:
   - **Debug:** run with  
     `flutter run --dart-define=API_HOST=192.168.1.45`
   - Or in app settings if you expose API host ( `ApiConfig.setHost` ).
   - Base URL becomes: `http://192.168.1.45:61082/api`

**University networks** often block device-to-device traffic. If ping/API fails on campus Wi‑Fi, use **Tailscale** or **ngrok** below.

#### B. Teammates at home — use a tunnel

| Tool | Best for | URL stability | Security |
|------|----------|---------------|----------|
| **Tailscale** (recommended) | Regular team, VPN-style access | Stable virtual IP (`100.x.x.x`) per machine | Encrypted mesh; no public exposure |
| **ngrok** | Quick demos, HTTPS URL for mobile | Free tier: **URL changes** each restart | Public HTTPS URL; use authtoken + optional reserved domain |

**Tailscale (recommended for Mosul team):**

1. Install [Tailscale](https://tailscale.com) on your laptop and each teammate’s phone/PC.
2. Same Tailnet → your laptop gets e.g. `100.64.0.12`.
3. API URL for everyone: `http://100.64.0.12:61082/api`
4. Run `allow-firewall.ps1` (port 61082).
5. No dynamic public IP problem — Tailscale handles NAT.

**ngrok:**

```bat
ngrok http 61082
```

Use the printed `https://xxxx.ngrok-free.app` as API base (add `/api`):

```
https://xxxx.ngrok-free.app/api
```

Flutter:

```bat
flutter run --dart-define=API_BASE_URL=https://xxxx.ngrok-free.app/api
```

**Dynamic IP with ngrok:** Your home ISP IP can change; ngrok gives a **fixed hostname** while the tunnel runs. When you restart ngrok (free), the subdomain **changes** — send the new URL to the team or pay for a reserved domain.

#### C. Windows Firewall (manual)

If you prefer GUI: **Windows Security → Firewall → Advanced → Inbound Rules → New Rule → Port → TCP 61082 → Allow → Private**.

Only open **Private** profile on laptops; avoid **Public** (coffee-shop Wi‑Fi).

---

### 3. Database setup

**Important:** Riyada currently uses **SQLite** (`SportsApp/Api/sports.db`), not SQL Server or PostgreSQL.

| Topic | What to do |
|-------|------------|
| Auto-start | SQLite is a **file** — no Windows service. The DB is ready when `sports.db` exists. |
| Backup | Run `local\backup-db.bat` manually or schedule it (Task Scheduler). |
| OneDrive | Script auto-copies to `%USERPROFILE%\OneDrive\RiyadaBackups` if OneDrive exists. |

**Schedule daily backup (Task Scheduler):**

1. Open **Task Scheduler** → Create Basic Task.
2. Trigger: Daily, 2:00 AM.
3. Action: Start program → `d:\sport\local\backup-db.bat`.
4. “Run whether user is logged on or not” only if the API folder is accessible.

**If you migrate to SQL Server / PostgreSQL later:**

- Set service **Startup type: Automatic** in `services.msc` (`SQL Server (MSSQLSERVER)` or `postgresql-x64-*`).
- Change `ConnectionStrings__Default` in `riyada.local.env`.

---

### 4. Security and reliability risks (laptop as server)

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Laptop sleep** | API unreachable | Plug in power; disable sleep; keep `run.bat` window open |
| **Laptop off / reboot** | Total outage | Document “server hours”; optional Task Scheduler to run `run.bat` at logon |
| **LAN IP change** | Teammates’ app breaks | DHCP reservation on router; or use **Tailscale** stable IP |
| **Public IP change** | Only matters for port-forwarding | Prefer Tailscale/ngrok instead of raw port forward |
| **ngrok URL change** | Team must update app URL | Reserved ngrok domain (paid) or Tailscale |
| **Weak JWT secret** | Token forgery | Set `Jwt__Key` in `riyada.local.env` (32+ chars) |
| **Exposed API on public Wi‑Fi** | Abuse | Firewall rule **Private only**; use Tailscale, not open port 61082 to the internet |
| **SQLite corruption** | Data loss | Daily `backup-db.bat`; don’t kill laptop during writes |
| **No HTTPS on LAN** | Tokens on HTTP | Acceptable for trusted campus lab; use **ngrok HTTPS** or reverse proxy for stricter setups |

**Checklist before a team test session:**

- [ ] `run.bat` running, `http://localhost:61082/api/health` returns OK
- [ ] Firewall rule for 61082 (Private)
- [ ] Teammates have correct `API_HOST` or `API_BASE_URL`
- [ ] Laptop plugged in, sleep disabled
- [ ] FCM credentials in `riyada.local.env` if testing push
- [ ] Backup run at least once: `backup-db.bat`

---

## Quick reference

```bat
REM Start API
d:\sport\local\run.bat

REM Backup database
d:\sport\local\backup-db.bat

REM Firewall (Admin PowerShell)
d:\sport\local\allow-firewall.ps1

REM Your IP
ipconfig

REM Teammate Flutter (LAN)
flutter run --dart-define=API_HOST=192.168.1.45

REM Teammate Flutter (ngrok)
flutter run --dart-define=API_BASE_URL=https://YOUR_SUBDOMAIN.ngrok-free.app/api

REM Teammate Flutter (Tailscale)
flutter run --dart-define=API_HOST=100.64.0.12
```

---

## FCM + local API note

Push **notifications** are delivered by Google’s servers to the device token. Your laptop only needs to:

1. Accept `POST /api/users/update-token` when users log in.
2. Call Firebase Admin when bookings change.

Teammates’ phones do **not** need to reach your laptop for the push itself — but they **do** need reachability for normal API calls (bookings, login, etc.) via LAN, Tailscale, or ngrok.
