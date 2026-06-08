import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

/// Gère l'enregistrement audio pour le clonage vocal ElevenLabs.
/// Durée recommandée : 30 secondes minimum pour un bon clonage.
class VoiceRecorderService {
  static final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  static bool _isOpen = false;
  static String? _filePath;

  static bool get isRecording => _recorder.isRecording;

  static Future<void> start() async {
    if (!_isOpen) {
      await _recorder.openRecorder();
      _isOpen = true;
    }
    final dir = await getTemporaryDirectory();
    _filePath = '${dir.path}/voxlink_voice_sample.wav';
    await _recorder.startRecorder(
      toFile: _filePath,
      codec: Codec.pcm16WAV,
    );
  }

  static Future<Uint8List?> stop() async {
    if (!_recorder.isRecording) return null;
    await _recorder.stopRecorder();
    if (_filePath == null) return null;
    final file = File(_filePath!);
    if (await file.exists()) return await file.readAsBytes();
    return null;
  }

  static Future<void> dispose() async {
    if (_isOpen) { await _recorder.closeRecorder(); _isOpen = false; }
  }
}
