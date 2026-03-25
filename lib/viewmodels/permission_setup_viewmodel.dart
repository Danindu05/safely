import '../core/services/permissions_service.dart';
import '../models/permission_health.dart';
import '../repositories/notification_repository.dart';
import 'base_viewmodel.dart';

class PermissionSetupViewModel extends BaseViewModel {
  PermissionSetupViewModel({
    required PermissionsService permissionsService,
    required NotificationRepository notificationRepository,
  }) : _permissionsService = permissionsService,
       _notificationRepository = notificationRepository {
    refresh();
  }

  final PermissionsService _permissionsService;
  final NotificationRepository _notificationRepository;

  PermissionHealth? _permissionHealth;

  PermissionHealth? get permissionHealth => _permissionHealth;

  Future<void> refresh() async {
    _permissionHealth = await _permissionsService.getPermissionHealth();
    notifyListeners();
  }

  Future<void> requestLocation() async {
    await _permissionsService.requestLocationPermission();
    await refresh();
  }

  Future<void> requestNotifications() async {
    await _notificationRepository.requestPushPermission();
    await _permissionsService.requestNotificationPermission();
    await refresh();
  }

  Future<void> requestMicrophone() async {
    await _permissionsService.requestMicrophonePermission();
    await refresh();
  }

  Future<void> openSettings() async {
    await _permissionsService.openSettings();
  }
}
