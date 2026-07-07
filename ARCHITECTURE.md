# Riyada — Architecture

## Monorepo layout

```
رياضة/
├── SportsApp/                    # ASP.NET Core backend
│   ├── Riyada.sln
│   ├── Domain/                   # Entities, no dependencies
│   ├── Application/              # DTOs, business rules, interfaces
│   ├── Infrastructure/           # EF Core, services, external I/O
│   │   └── Data/AppDbContext.cs
│   └── Api/                      # Minimal API entry point
│
└── mobile/                       # Flutter (Dart only)
    └── lib/
        ├── config/
        ├── models/
        ├── services/             # ApiClient (Dio)
        ├── providers/            # Provider state
        └── screens/
```

## Run backend

```bash
cd SportsApp/Api
dotnet run
```

## Run Flutter

```bash
cd mobile
flutter pub get
flutter run
```

## Conventions

- API uses **`fieldId`** in JSON; SQLite column may remain `StadiumId` (mapped in EF).
- Commission: **10%** of (price per hour × hours booked) per approved booking (`Application/Common/FinancialRules.cs`).
- JWT stored in Flutter via **`flutter_secure_storage`**.

## Removed

- React Native / Expo files in `mobile/`
- Monolithic `SportsApp/Program.cs` (replaced by layered projects)

## Next steps

1. Port `BookingService` + Auth endpoints to `Infrastructure` + `Api`
2. Add `BookingService` + screens in Flutter
3. Wire full auth/register/booking flows
