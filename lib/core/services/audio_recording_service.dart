import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecordingService {
  AudioRecordingService(this._recorder);

  final AudioRecorder _recorder;
  String? _activePath;

  bool get isRecording => _activePath != null;

  Future<String?> startEmergencyRecording({
    required String userId,
    required String alertId,
  }) async {
    if (!await _recorder.hasPermission()) {
      return null;
    }

    final Directory directory = await getTemporaryDirectory();
    final String path = '${directory.path}/safely_${userId}_$alertId.m4a';

    await _recorder.start(const RecordConfig(), path: path);

    _activePath = path;
    return path;
  }

  Future<String?> stopRecording() async {
    final String? path = await _recorder.stop();
    _activePath = null;
    return path;
  }

  Future<void> cancelRecording() async {
    final String? path = _activePath;
    await _recorder.cancel();
    _activePath = null;

    if (path != null) {
      final File file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> dispose() {
    return _recorder.dispose();
  }
}
