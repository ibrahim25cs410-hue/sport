# Riyada — Sports Field Booking Platform

Riyada is a sports field booking system for Ninawa (Iraq). It supports **users** (book fields) and **owners** (manage bookings and revenue). Real-time updates use **Socket.io** end to end.

## Stack

| Layer | Technology |
|-------|------------|
| Mobile | Flutter (Dart) + Riverpod + Dio |
| Web | React + Vite + Socket.io client |
| API | Node.js + Express + Socket.io |
| Database | MongoDB Atlas (production) or in-memory (development) |

## Project layout

```
sport/
├── server.js         # Production API on Render (HTTP + Socket.io)
├── node-backend/     # Alternate Express API (not the live Render process)
├── mobile/           # Flutter app (Android, iOS, Windows, Web)
├── web/              # React web client
└── SportsApp/        # Legacy .NET API (not used by current clients)
```

**Live API:** `https://sports-x7v7.onrender.com/api`  
Env: `MONGODB_URI` (required), `JWT_SECRET` (recommended; otherwise derived from Mongo URI), `NODE_ENV=production`.

---

## Backend (production: root `server.js`)

### Environment variables

Copy the example file and edit values:

```powershell
copy .env.example .env
```

| Variable | Required in production | Description |
|----------|------------------------|-------------|
| `MONGODB_URI` | Yes | MongoDB Atlas connection string |
| `JWT_SECRET` | Recommended | Long random string (32+ characters) |
| `NODE_ENV` | Yes | Set to `production` on Render |
| `PORT` | No | HTTP port (Render sets this) |
| `ALLOWED_ORIGINS` | No | Comma-separated web origins for CORS |

**Development:** If `MONGODB_URI` is omitted, data is stored in memory and cleared on restart.

### Run locally

```powershell
npm install
npm start
```

Health check: `http://localhost:3000/api/health`

### Socket.io events

| Event | Purpose |
|-------|---------|
| `notification` | Persisted notification pushed to a user |
| `bookingUpdated` | Booking status change |
| `slotSelection` / `slotRelease` | Field slot hold sync |

Connect with JWT: `auth: { token: "<jwt>" }` to the server origin (no `/api` suffix).

---

## Alternate backend (`node-backend`)

Modular Express API kept in-repo for migration work. The live Render service runs root `server.js`, not this folder.

```powershell
cd node-backend
npm install
npm run dev
```

### Tests (`node-backend`)

```powershell
npm run test:sockets
npm run test:bookings
npm run test:stadiums
npm test
```

---

## Flutter mobile (`mobile`)

### API configuration

Production builds default to `https://sports-x7v7.onrender.com/api`. Override for local or staging:

```powershell
cd mobile
flutter pub get

# Emulator / local API
flutter run --dart-define=API_HOST=localhost --dart-define=API_PORT=3000

# Physical device (use your PC LAN IP)
flutter run --dart-define=API_HOST=192.168.1.10 --dart-define=API_PORT=3000

# Full URL override
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api
```

Socket.io uses the same host as the API (`ApiConfig.socketBaseUrl`).

### Service initialization

At cold start, `AppBootstrap` runs in this order:

1. Firebase / FCM / local notifications
2. Auth session restore (`AuthNotifier.bootstrap`)
3. `ServiceBootstrap` — wires Api, Booking, Stadium, and Socket services
4. `NotificationBootstrap` — FCM + Socket.io → local notifications

After login or registration, `AuthNotifier` connects Socket.io automatically.

### Build release APK

```powershell
cd mobile
flutter build apk --release `
  --dart-define=API_BASE_URL=https://sports-x7v7.onrender.com/api
```

Output: `mobile/build/app/outputs/flutter-apk/app-release.apk`

### Build Windows

```powershell
flutter build windows --release `
  --dart-define=API_BASE_URL=https://sports-x7v7.onrender.com/api
```

---

## Web (`web`)

### Environment variables

```powershell
cd web
copy .env.example .env.local
```

| Variable | Description |
|----------|-------------|
| `VITE_API_HOST` | API host (default `localhost`) |
| `VITE_API_PORT` | API port (default `61082` in code; use `3000` for node-backend) |
| `VITE_API_BASE` | Full API base URL (overrides host/port) |

### Run and build

```powershell
cd web
npm install
npm run dev      # http://localhost:5173
npm run build    # output in web/dist
```

Live updates use `useSocket` (Socket.io). Polling remains as a fallback in `useLiveUpdates`.

---

## Quick start (full stack)

**Terminal 1 — API**

```powershell
cd node-backend
npm install
npm run dev
```

**Terminal 2 — Flutter**

```powershell
cd mobile
flutter pub get
flutter run -d windows --dart-define=API_PORT=3000
```

**Terminal 3 — Web (optional)**

```powershell
cd web
npm install
npm run dev
```

---

## Git: fix remote auth and push

If `git push` fails with **Repository not found**, verify the remote URL and authenticate.

### 1. Check remote

```powershell
cd d:\sport
git remote -v
git status
git log -1 --oneline
```

### 2. Set the correct GitHub remote

```powershell
git remote set-url origin https://github.com/YOUR_USER/YOUR_REPO.git
```

Or with SSH (recommended after adding your SSH key to GitHub):

```powershell
git remote set-url origin git@github.com:YOUR_USER/YOUR_REPO.git
```

### 3. Authenticate (HTTPS + Personal Access Token)

1. GitHub → **Settings** → **Developer settings** → **Personal access tokens**
2. Create a token with `repo` scope
3. Push and use the token as the password when prompted:

```powershell
git push -u origin main
```

### 4. Or install GitHub CLI and login

```powershell
winget install GitHub.cli
gh auth login
git push -u origin main
```

### 5. Stage and commit new changes (if any)

```powershell
git add docs/ROADMAP.md `
  mobile/lib/core/bootstrap/ `
  mobile/lib/main.dart `
  mobile/lib/providers/auth_provider.dart `
  mobile/lib/providers/service_providers.dart `
  web/.env.example `
  README.md

git commit -m "Finalize Socket.io bootstrap and project documentation"
git push -u origin main
```

---

## Commission

Platform commission is **10%** of (hourly rate × booked hours) per confirmed booking, deducted from owner revenue.
