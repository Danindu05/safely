import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';

class FirestoreService {
  FirestoreService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get users {
    return _firestore.collection(FirestoreCollections.users);
  }

  CollectionReference<Map<String, dynamic>> get medicalProfiles {
    return _firestore.collection(FirestoreCollections.medicalProfiles);
  }

  CollectionReference<Map<String, dynamic>> get alerts {
    return _firestore.collection(FirestoreCollections.alerts);
  }

  CollectionReference<Map<String, dynamic>> get checkins {
    return _firestore.collection(FirestoreCollections.checkins);
  }

  CollectionReference<Map<String, dynamic>> get geofences {
    return _firestore.collection(FirestoreCollections.geofences);
  }

  CollectionReference<Map<String, dynamic>> get settings {
    return _firestore.collection(FirestoreCollections.settings);
  }

  CollectionReference<Map<String, dynamic>> get logs {
    return _firestore.collection(FirestoreCollections.logs);
  }

  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  ) {
    return _firestore.runTransaction(action);
  }

  FieldValue serverTimestamp() => FieldValue.serverTimestamp();
}
