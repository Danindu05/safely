import 'app_enums.dart';

class PermissionHealth {
  const PermissionHealth({
    required this.location,
    required this.notifications,
    required this.microphone,
  });

  final AppPermissionState location;
  final AppPermissionState notifications;
  final AppPermissionState microphone;

  bool get allGranted {
    return location == AppPermissionState.granted &&
        notifications == AppPermissionState.granted &&
        microphone == AppPermissionState.granted;
  }
}
