# Safely

Safely is an Android-first Flutter + Firebase guardian safety app built with a
clean MVVM architecture. It supports two roles :

- `Safemate`: the protected person using SOS, live sharing, check-ins, and medical info
- `Guardian`: the trusted watcher receiving alerts, live location, and response context

This foundation is designed for real-world demos and later expansion into fall
detection, route deviation, escalation logic, and deeper background monitoring.

## Current scope

Implemented in this phase:

- Firebase initialization via `firebase_options.dart`
- Email/password sign up, login, and logout
- Splash, onboarding, role selection, and permission setup
- Safemate medical profile setup and read-only emergency view
- Guardian linking by Guardian UID
- SOS alert creation in Firestore
- Live emergency/manual location sharing through Realtime Database
- FCM token capture, foreground handling, and Cloud Functions push fanout
- Low battery alert creation on device
- Critical battery emergency mode with live location handoff
- Manual and timed safety check-ins, with WorkManager-backed background checks
- On-device fall, phone-drop, sudden-stop, and abnormal movement detection with confirmation before SOS
- Hidden triple-tap panic trigger for manual silent SOS activation
- Audio recording during emergency with Firebase Storage upload
- Route tracking with OSRM road-aware routing and straight-line fallback
- Geofence setup with OpenStreetMap via `flutter_map`
- Android OS-level geofence registration with app-side fallback checks
- Trusted place mode using safe geofence zones
- Night mode monitoring with overnight missed-check-in alerts
- Enforced notification category settings for SOS, battery, geofence/route, and check-ins
- Guardian dashboard, alert list, alert detail, live map, and Safemate profile

Prepared structurally, but not implemented yet:

- Power-button panic alternatives
- Escalation workflows
- Tamper awareness

## Architecture

The app uses a clean MVVM split:

- `lib/core`
  - constants, theme, Firebase/device services, shared widgets
- `lib/models`
  - app entities and Firebase serialization
- `lib/repositories`
  - app-facing data contracts backed by Firebase/services
- `lib/viewmodels`
  - screen state and business flow
- `lib/screens`
  - views only
- `lib/features`
  - feature barrels for scalable exports

UI does not call Firebase directly. Screens talk to viewmodels, viewmodels talk
to repositories, repositories delegate to services.

## Project structure

```text
lib/
  app_shell.dart
  main.dart
  firebase_options.dart
  core/
    constants/
    services/
    theme/
    utils/
    widgets/
  features/
    auth/
    guardian/
    home/
    safemate/
  models/
  repositories/
  screens/
    auth/
    common/
    guardian/
    safemate/
  viewmodels/
```

## Firebase data model

### Firestore

`users/{uid}`

- `id`
- `name`
- `email`
- `role`
- `guardianIds`
- `safemateIds`
- `createdAt`
- `updatedAt`
- `fcmToken`
- `batteryLevel`
- `lastSeenAt`
- `lastLocationSyncAt`
- `isEmergencyActive`
- `emergencyContactName`
- `emergencyContactPhone`

`medical_profiles/{uid}`

- `userId`
- `fullName`
- `bloodGroup`
- `allergies`
- `medicalConditions`
- `emergencyNotes`
- `emergencyContactName`
- `emergencyContactPhone`
- `updatedAt`

`alerts/{alertId}`

- `id`
- `userId`
- `guardianIds`
- `type`
- `status`
- `title`
- `description`
- `timestamp`
- `locationLat`
- `locationLng`
- `batteryLevel`
- `audioUrl`
- `acknowledgedBy`
- `acknowledgedAt`
- `canceledByUser`
- `resolvedAt`

`checkins/{checkinId}`

- `id`
- `userId`
- `type`
- `timestamp`
- `batteryLevel`
- `locationLat`
- `locationLng`
- `status`

`geofences/{uid}`

- `userId`
- `zones`

`settings/{uid}`

- `userId`
- `lowBatteryWarningPercent`
- `lowBatteryCriticalPercent`
- `checkInEnabled`
- `checkInIntervalMinutes`
- `autoCheckInEnabled`
- `audioRecordingEnabled`
- `geofencingEnabled`
- `liveLocationEnabled`
- `trustedPlaceModeEnabled`
- `nightModeMonitoringEnabled`
- `sosNotificationsEnabled`
- `batteryNotificationsEnabled`
- `geofenceNotificationsEnabled`
- `checkInNotificationsEnabled`
- `emergencyDetectionEnabled`
- `fallDetectionEnabled`
- `movementDetectionEnabled`

`logs/{logId}`

- `userId`
- `eventType`
- `message`
- `timestamp`
- `metadata`

### Realtime Database

`live_locations/{userId}`

- `guardianIds`
- `guardianAccess`
- `lat`
- `lng`
- `accuracy`
- `speed`
- `heading`
- `updatedAt`
- `isEmergencyActive`
- `source`

`guardianAccess` is stored to support scoped RTDB reads for linked guardians.

### Firebase Storage

`emergency_audio/{userId}/{alertId}.m4a`

## Android setup

### 1. Firebase config

`google-services.json` should exist at:

```text
android/app/google-services.json
```

`lib/firebase_options.dart` should remain the generated FlutterFire file.

### 2. Map provider

The app now uses OpenStreetMap tiles through `flutter_map`. No paid Google Maps
API key is required for the current setup.

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Deploy Firebase rules

```bash
firebase deploy --only firestore:rules,database,storage
```

### 5. Deploy Cloud Functions

The `sendGuardianAlert` function sends FCM notifications when new alerts are created.

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

### 6. Run the app

```bash
flutter run
```

For Android geofencing while the app is closed, grant location access with background/always permission when Android offers it. If the OS rejects background geofence registration, Safely keeps the existing app-side geofence checks active as a fallback.

## How to test the app

### Sign up and role setup

1. Launch the app.
2. Complete onboarding.
3. Sign up with email/password.
4. Choose either `I need protection` or `I am a Guardian`.
5. Complete permission setup.
6. If you chose Safemate, fill the medical profile screen and configure safe zones if you want trusted place mode.

### Guardian linking

1. Create a Guardian account and open the Guardian dashboard.
2. Copy the Guardian UID shown in the `Linking ID` card.
3. Sign in as a Safemate.
4. Open `Guardians`.
5. Paste the Guardian UID and tap `Link guardian`.

### SOS flow

1. Sign in as a linked Safemate.
2. Open the Safemate home screen.
3. Tap the large `SOS` button.
4. Confirm that:
   - an alert document appears in Firestore
   - the Safemate enters `Emergency active`
   - live location appears under `live_locations/{userId}`
   - Guardian alert cards update in real time

### Live location

1. With an active SOS or manual live share, open the Guardian app.
2. Go to `Live map`.
3. Select the linked Safemate if needed.
4. Confirm the marker updates and geofence circles are visible.

### Audio recording

1. Ensure microphone permission is granted.
2. Keep `Record emergency audio` enabled in Safety settings.
3. Trigger SOS.
4. End the emergency.
5. Confirm the uploaded file exists in Firebase Storage and the alert has an `audioUrl`.
6. Open the alert in Guardian `Alert detail` and play the recording.

### Battery alert test

This is on-device logic. The easiest manual test path is:

1. Set low battery thresholds to a high value like `95%`.
2. Return to the Safemate shell and let the monitor cycle run.
3. Confirm a low battery alert appears in Firestore and Guardian alerts.
4. For critical battery behavior, set the critical threshold above the current battery level and confirm `isEmergencyActive` turns true and `live_locations/{userId}` is written.

### Check-in

1. Tap `Quick check-in` on the Safemate home screen.
2. Confirm a `checkins` document is created.
3. Confirm a resolved `manual_checkin` alert is created.
4. Check `Activity history`.
5. For timed reminders, enable check-ins and set a short interval. The app shows an in-app prompt when active, and the Android WorkManager task can create a missed check-in alert if the background prompt is not answered.

### Route tracking

1. Open the Safemate home screen.
2. Tap `Start route`.
3. Enter destination latitude/longitude.
4. Confirm the route preview draws a road-aware path when OSRM is available, or a straight-line fallback when routing fails.
5. Move more than the configured route threshold away from the path and confirm a `route_deviation` alert is created.

### Emergency detection

1. Open `Safety settings`.
2. Enable `Emergency detection`, `Fall and impact detection`, and `Abnormal movement detection`.
3. Keep the Safemate app active.
4. When Safely detects a suspicious fall/movement pattern, confirm the full-screen `Are you safe?` prompt appears.
5. Tap `I'm Safe` to cancel or `Send Help` to trigger SOS.
6. Let the countdown expire to test automatic SOS from `no_response`.

### Silent panic trigger

1. On the Safemate shell, rapidly tap the hidden top-right corner hotspot three times.
2. Confirm SOS starts without the detection confirmation prompt.

### Geofence setup

1. Open `Safety settings` -> `Geofence setup`.
2. Long-press the map to add a safe or unsafe zone.
3. Enable `Geofencing` in Safety settings.
4. Grant background location permission if Android offers it.
5. Enter a saved unsafe zone.
6. Confirm a geofence alert appears. OS-level geofencing handles closed-app entry when Android permits it; otherwise the Safemate shell monitor handles it while the app is active.

### Notification settings

1. Open the Guardian notification settings tab.
2. Turn off a category such as battery alerts.
3. Trigger that alert type from the Safemate account.
4. Confirm the alert still exists in Firestore, but `sendGuardianAlert` skips the disabled Guardian notification category.

### Trusted place mode

1. Create at least one `Safe zone` in Geofence setup.
2. Enable `Trusted place mode` in Safety settings.
3. Move inside that safe zone.
4. Confirm the Safemate home screen shows `Trusted place` / `Safe zone active`.

### Night mode monitoring

1. Enable `Night mode monitoring` in Safety settings.
2. Set a short check-in interval, for example `15` minutes.
3. Make sure you are outside a trusted safe zone.
4. During the active night window of `10 PM` to `6 AM`, wait past the interval without checking in.
5. Confirm a `missed_checkin` alert is created for guardians.

## Notes

- Detection and trigger logic runs on device.
- Firebase is used for communication, persistence, and media storage only.
- Background monitoring uses Android WorkManager, which is periodic and battery-managed by Android. It improves reliability but is not a constant real-time loop.
- OS-level geofencing requires Android background location permission. If unavailable, app-side checks continue.
- Road-aware route tracking uses the public OSRM server and falls back to the local straight-line deviation logic if route generation fails.
- Emergency detection uses simple threshold-based phone motion checks while the app is active. It intentionally asks for confirmation first to reduce false positives.
- FCM push fanout is handled by the included Cloud Function and respects Guardian notification category settings.

## Verification

Locally verified in this workspace:

- `flutter analyze --no-pub`
- `flutter test`
- `flutter build apk --debug`
