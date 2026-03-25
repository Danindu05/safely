import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../constants/app_constants.dart';

class FirebaseStorageService {
  FirebaseStorageService(this._storage);

  final FirebaseStorage _storage;

  Future<String> uploadEmergencyAudio({
    required String userId,
    required String alertId,
    required String filePath,
  }) async {
    final Reference reference = _storage.ref(
      '${StoragePaths.emergencyAudio}/$userId/$alertId.m4a',
    );

    await reference.putFile(
      File(filePath),
      SettableMetadata(contentType: 'audio/m4a'),
    );

    return reference.getDownloadURL();
  }
}
