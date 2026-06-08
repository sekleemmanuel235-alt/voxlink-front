import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

/// Fournit un identifiant d'appareil stable et unique.
/// Utilise le vrai UUID matériel via device_info_plus.
/// Fallback sur un UUID généré et persisté si indisponible.
class DeviceService {
  static String? _cachedId;

  static Future<String> getDeviceId() async {
    if (_cachedId != null) return _cachedId!;

    // Try cache first
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('voxlink_device_id');
    if (cached != null) { _cachedId = cached; return cached; }

    String id;
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        id = android.id; // hardware serial / build ID
      } else if (Platform.isIOS) {
        final ios = await info.iosInfo;
        id = ios.identifierForVendor ?? _generateFallback();
      } else {
        id = _generateFallback();
      }
    } catch (_) {
      id = _generateFallback();
    }

    await prefs.setString('voxlink_device_id', id);
    _cachedId = id;
    return id;
  }

  static String _generateFallback() {
    final rng = Random.secure();
    return List.generate(32, (_) => rng.nextInt(16).toRadixString(16)).join();
  }
}
