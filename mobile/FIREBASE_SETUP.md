# Firebase setup for Riyada mobile

1. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
2. From `mobile/`: `flutterfire configure --project=YOUR_PROJECT_ID`
   - Android package: `iq.riyada.riyada`
   - iOS bundle: `iq.riyada.riyada`
3. This generates `lib/core/firebase/firebase_options.dart`, `android/app/google-services.json`, and `ios/Runner/GoogleService-Info.plist`.
4. **Do not commit** service account JSON or `google-services.json` if your policy requires secrets in CI only.

Backend needs the **service account** JSON (not the mobile config files). Set `Fcm__CredentialsPath` on the server.
