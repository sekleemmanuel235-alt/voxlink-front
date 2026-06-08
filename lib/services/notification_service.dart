import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Gère les notifications locales (appels entrants, nouveaux messages).
/// En production, coupler avec firebase_messaging pour les push distantes.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  static Future<void> showMessageNotification({
    required String senderName,
    required String message,
    int id = 1,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'voxlink_messages', 'Messages VoxLink',
        channelDescription: 'Notifications de nouveaux messages',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(badgeNumber: 1),
    );
    await _plugin.show(id, senderName, message, details);
  }

  static Future<void> showCallNotification({
    required String callerName,
    int id = 2,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'voxlink_calls', 'Appels VoxLink',
        channelDescription: 'Notifications d\'appels entrants',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(id, '📞 Appel entrant', callerName, details);
  }

  static Future<void> cancelAll() async => _plugin.cancelAll();
}
