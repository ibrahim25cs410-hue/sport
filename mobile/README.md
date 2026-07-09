# Riyada Mobile

Flutter client for the Riyada sports booking platform.

See the [root README](../README.md) for:

- Backend `.env` configuration
- API / Socket.io setup (`--dart-define`)
- Release builds (APK, Windows)
- Git push and authentication

## Quick run

```powershell
flutter pub get
flutter run -d windows --dart-define=API_PORT=3000
```

Ensure `node-backend` is running on the same host/port.
