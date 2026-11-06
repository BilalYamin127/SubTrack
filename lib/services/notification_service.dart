import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/subscription.dart';
import 'reminder_planner.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin plugin;
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : plugin = plugin ?? FlutterLocalNotificationsPlugin();
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  Future<void> initialize() async {
    if (!supported) return;
    tzdata.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  Future<bool> requestPermission() async {
    if (!supported) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  // Serialize rebuilds so rapid edits cannot leave stale reminders behind.
  Future<void> _queue = Future.value();
  Future<void> sync(List<Subscription> subscriptions, bool enabled) {
    final task = _queue
        .catchError((Object _) {})
        .then((_) => _sync(subscriptions, enabled));
    _queue = task;
    return task;
  }

  Future<void> _sync(List<Subscription> subscriptions, bool enabled) async {
    if (!supported) return;
    // Refresh timezone after travel or a device timezone change.
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await plugin.cancelAll();
    if (!enabled) return;
    final candidates = ReminderPlanner.plan(subscriptions, DateTime.now());
    var id = 1;
    for (final c in candidates.take(60)) {
      await plugin.zonedSchedule(
        id++,
        '${c.subscription.name} renewal',
        c.leadDays == 0
            ? 'Projected renewal today • ${c.subscription.currencyCode} ${c.subscription.price.toStringAsFixed(2)}'
            : 'Projected renewal in ${c.leadDays} days • ${c.subscription.currencyCode} ${c.subscription.price.toStringAsFixed(2)}',
        tz.TZDateTime.from(c.date, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'renewals',
            'Renewal reminders',
            channelDescription: 'Projected subscription renewals',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: c.subscription.id,
      );
    }
  }
}
