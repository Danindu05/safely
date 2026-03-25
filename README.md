# Safely

Safely is an Android-first Flutter + Firebase guardian safety app built with a
clean MVVM architecture. It supports two roles:

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
- FCM token capture and foreground notification handling scaffold
- Low battery alert creation on device
- Manual safety check-ins
- Audio recording during emergency with Firebase Storage upload
- Geofence setup with OpenStreetMap via `flutter_map`
- Trusted place mode using safe geofence zones
- Night mode monitoring with overnight missed-check-in alerts
- Guardian dashboard, alert list, alert detail, live map, and Safemate profile

Prepared structurally, but not implemented as background-grade features yet:

- Fall detection
- Power-button panic alternatives
- Route deviation monitoring
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

### 5. Run the app

```bash
flutter run
```

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

### Check-in

1. Tap `Quick check-in` on the Safemate home screen.
2. Confirm a `checkins` document is created.
3. Confirm a resolved `manual_checkin` alert is created.
4. Check `Activity history`.

### Geofence setup

1. Open `Safety settings` -> `Geofence setup`.
2. Long-press the map to add a safe or unsafe zone.
3. Enable `Geofencing` in Safety settings.
4. Return to the Safemate shell and let the monitor cycle run while inside a saved unsafe zone.
5. Confirm a geofence alert and log entry appear.

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
- Live location, trusted place mode, and geofence monitoring are implemented for foreground/app-active use in this phase.
- FCM token capture and foreground handling are included; Cloud Functions-based push fanout can be added later without changing the UI architecture.

## Verification

Locally verified in this workspace:

- `flutter analyze --no-pub`
- `flutter test`
