import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/app_enums.dart';
import '../../models/permission_health.dart';

class PermissionsService {
  Future<PermissionHealth> getPermissionHealth() async {
    return PermissionHealth(
      location: await _locationPermissionState(),
      notifications: _fromPermissionStatus(
        await Permission.notification.status,
      ),
      microphone: _fromPermissionStatus(await Permission.microphone.status),
    );
  }

  Future<AppPermissionState> requestLocationPermission() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return AppPermissionState.denied;
    }

    final LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse) {
      await Permission.locationAlways.request();
    }

    final LocationPermission effectivePermission =
        await Geolocator.checkPermission();
    return switch (permission) {
      LocationPermission.deniedForever => AppPermissionState.permanentlyDenied,
      _ => switch (effectivePermission) {
        LocationPermission.always ||
        LocationPermission.whileInUse => AppPermissionState.granted,
        LocationPermission.deniedForever =>
          AppPermissionState.permanentlyDenied,
        _ => AppPermissionState.denied,
      },
    };
  }

  Future<AppPermissionState> requestNotificationPermission() async {
    final PermissionStatus status = await Permission.notification.request();
    return _fromPermissionStatus(status);
  }

  Future<AppPermissionState> requestMicrophonePermission() async {
    final PermissionStatus status = await Permission.microphone.request();
    return _fromPermissionStatus(status);
  }

  Future<bool> openSettings() {
    return openAppSettings();
  }

  Future<AppPermissionState> _locationPermissionState() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return AppPermissionState.denied;
    }

    final LocationPermission permission = await Geolocator.checkPermission();
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => AppPermissionState.granted,
      LocationPermission.deniedForever => AppPermissionState.permanentlyDenied,
      _ => AppPermissionState.denied,
    };
  }

  AppPermissionState _fromPermissionStatus(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return AppPermissionState.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return AppPermissionState.permanentlyDenied;
    }
    return AppPermissionState.denied;
  }
}
