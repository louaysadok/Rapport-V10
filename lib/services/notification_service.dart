import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

/// Notifications locales : rappel quotidien à 18:00 heure de l'appareil.
class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// Programme le rappel quotidien à 18:00 heure locale.
  Future<void> scheduleDailyReminder({int hour = 18, int minute = 0}) async {
    await init();
    await _plugin.cancelAll();

    final locationName = await FlutterTimezone.getLocalTimezone();
    final location = tz.getLocation(locationName);
    final now = tz.TZDateTime.now(location);
    var scheduled = tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'rapport_daily',
      'Rappel journal de bord',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      1,
      'Rapport+',
      "N'oubliez pas de remplir votre journal de bord aujourd'hui.",
      scheduled,
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Affiche une notification immédiate.
  Future<void> showNow({
    int id = 0,
    required String title,
    required String body,
  }) async {
    await init();
    const android = AndroidNotificationDetails(
      'rapport_immediate',
      'Rapport+',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    await _plugin.show(id, title, body, const NotificationDetails(android: android));
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
