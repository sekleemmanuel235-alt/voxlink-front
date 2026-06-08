import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Demande micro + caméra avant un appel.
  static Future<bool> requestCallPermissions({bool video = false}) async {
    final mic = await Permission.microphone.request();
    if (video) {
      final cam = await Permission.camera.request();
      return mic.isGranted && cam.isGranted;
    }
    return mic.isGranted;
  }

  /// Demande accès galerie / stockage pour upload de média.
  static Future<bool> requestMediaPermission() async {
    final photos = await Permission.photos.request();
    if (photos.isGranted) return true;
    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  /// Demande micro seul pour le clonage vocal.
  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<bool> get hasMicrophone =>
      Permission.microphone.status.then((s) => s.isGranted);

  static Future<bool> get hasCamera =>
      Permission.camera.status.then((s) => s.isGranted);
}
