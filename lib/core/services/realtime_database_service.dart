import 'package:firebase_database/firebase_database.dart';

import '../constants/app_constants.dart';

class RealtimeDatabaseService {
  RealtimeDatabaseService(this._database);

  final FirebaseDatabase _database;

  DatabaseReference liveLocationRef(String userId) {
    return _database.ref('${RealtimeDatabasePaths.liveLocations}/$userId');
  }
}
