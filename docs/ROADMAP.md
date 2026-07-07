# Riyada — Architecture Roadmap

## Current vs Target

| Layer | Current | Target |
|-------|---------|--------|
| API | Minimal API, SQLite | Clean Architecture + JWT |
| Web | React + Vite | Same (Chrome testing ready) |
| Mobile | React Native Expo | Flutter rewrite |

## Phases

1. **Database Schema** — ERD + Domain entities (`SportsApp/Domain/`)
2. **API Refactor** — Domain → Application → Infrastructure → Api
3. **Security** — Password hashing, JWT, authorization
4. **Real-Time** — SignalR notifications
5. **Flutter** — `/mobile` with Dio + Riverpod
6. **Web Chrome** — `cd web && npm run dev` → http://localhost:3000

## Chrome Testing (Now)

```bash
# Terminal 1
cd SportsApp && dotnet run

# Terminal 2
cd web && npm run dev
```

Open http://localhost:3000 in Chrome. API proxied to :5000.

## Flutter API Client Pattern

- `dio` for HTTP
- `flutter_secure_storage` for JWT
- Interceptor: `Authorization: Bearer <token>`
- Base URL: `http://10.0.2.2:5000/api/v1` (emulator)
