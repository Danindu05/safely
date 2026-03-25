import 'package:battery_plus/battery_plus.dart';

class BatteryService {
  BatteryService(this._battery);

  final Battery _battery;

  Future<int> getBatteryLevel() {
    return _battery.batteryLevel;
  }

  Stream<BatteryState> get onBatteryStateChanged {
    return _battery.onBatteryStateChanged;
  }
}
