import 'dart:async';

import '../models/activity_log.dart';
import '../models/safety_alert.dart';
import '../models/safety_checkin.dart';
import '../repositories/alert_repository.dart';
import 'base_viewmodel.dart';

enum HistoryFilter { all, alerts, checkins, battery, route, geofence, events }

class ActivityHistoryViewModel extends BaseViewModel {
  ActivityHistoryViewModel({
    required AlertRepository alertRepository,
    required String userId,
  }) : _alertRepository = alertRepository {
    _alertsSubscription = _alertRepository.watchAlertsForUser(userId).listen((
      List<SafetyAlert> alerts,
    ) {
      _alerts = alerts;
      notifyListeners();
    });
    _checkinSubscription = _alertRepository.watchCheckIns(userId).listen((
      List<SafetyCheckIn> checkIns,
    ) {
      _checkIns = checkIns;
      notifyListeners();
    });
    _logsSubscription = _alertRepository.watchLogs(userId).listen((
      List<ActivityLog> logs,
    ) {
      _logs = logs;
      notifyListeners();
    });
  }

  final AlertRepository _alertRepository;
  StreamSubscription<List<SafetyAlert>>? _alertsSubscription;
  StreamSubscription<List<SafetyCheckIn>>? _checkinSubscription;
  StreamSubscription<List<ActivityLog>>? _logsSubscription;

  HistoryFilter _filter = HistoryFilter.all;
  List<SafetyAlert> _alerts = const <SafetyAlert>[];
  List<SafetyCheckIn> _checkIns = const <SafetyCheckIn>[];
  List<ActivityLog> _logs = const <ActivityLog>[];

  HistoryFilter get filter => _filter;
  List<SafetyAlert> get alerts => _alerts;
  List<SafetyCheckIn> get checkIns => _checkIns;
  List<ActivityLog> get logs => _logs;

  void setFilter(HistoryFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  @override
  void dispose() {
    _alertsSubscription?.cancel();
    _checkinSubscription?.cancel();
    _logsSubscription?.cancel();
    super.dispose();
  }
}
