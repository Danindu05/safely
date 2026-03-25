import 'dart:async';

import '../models/safety_alert.dart';
import '../repositories/alert_repository.dart';
import 'base_viewmodel.dart';

class GuardianAlertsViewModel extends BaseViewModel {
  GuardianAlertsViewModel({
    required AlertRepository alertRepository,
    required String guardianId,
  }) {
    _subscription = alertRepository.watchAlertsForGuardian(guardianId).listen((
      List<SafetyAlert> alerts,
    ) {
      _alerts = alerts;
      notifyListeners();
    });
  }

  late final StreamSubscription<List<SafetyAlert>> _subscription;
  List<SafetyAlert> _alerts = const <SafetyAlert>[];

  List<SafetyAlert> get alerts => _alerts;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
