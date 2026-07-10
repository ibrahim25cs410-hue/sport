# Riyada — Architecture Roadmap

## Current stack

| Layer | Technology |
|-------|------------|
| API | Node.js + Express + Socket.io (`node-backend/`) |
| Database | MongoDB Atlas (prod) or in-memory (dev) |
| Mobile | Flutter + Riverpod + Dio + Socket.io (`mobile/`) |
| Web | React + Vite + Socket.io (`web/`) |

Legacy: `SportsApp/` (.NET + SignalR) is unused by current clients.

## Done

1. Auth (JWT, roles: user / owner)
2. Fields + stadiums CRUD
3. Bookings + notifications
4. Real-time via Socket.io (`notification`, `bookingUpdated`, `slotSelection`, `slotRelease`)
5. Flutter service layer + Socket bootstrap
6. Web Socket.io client (replaces SignalR)

## Remaining (optional)

- Admin API routes (`/admin/*`)
- Stadium-first Flutter UI (services exist; screens still field-centric)
- Reviews / wallet persistence (currently stubbed)
- Retire or archive `SportsApp/`

## Local testing

```powershell
# Terminal 1 — API
cd node-backend
copy .env.example .env   # optional for local
npm install
npm run dev              # http://localhost:3000

# Terminal 2 — Web
cd web
npm install
npm run dev              # http://localhost:5173

# Terminal 3 — Flutter
cd mobile
flutter pub get
flutter run -d windows --dart-define=API_PORT=3000
```
