import '../models/subscription.dart';
import 'billing_service.dart';

class PlannedReminder {
  final Subscription subscription;
  final DateTime date;
  final int leadDays;
  const PlannedReminder(this.subscription, this.date, this.leadDays);
}

class ReminderPlanner {
  static List<PlannedReminder> plan(
    List<Subscription> subscriptions,
    DateTime now, {
    int limit = 60,
  }) {
    final result = <PlannedReminder>[];
    final horizon = DateTime(now.year + 1, now.month, now.day, 23, 59);
    for (final s in subscriptions.where(
      (s) => s.status == SubscriptionStatus.active,
    )) {
      var index = BillingService.nextIndex(s, now);
      while (true) {
        final renewal = BillingService.occurrence(s, index++);
        if (renewal.isAfter(horizon)) break;
        for (final lead in s.reminderDays.toSet().where(
          (d) => [7, 3, 1, 0].contains(d),
        )) {
          final date = DateTime(
            renewal.year,
            renewal.month,
            renewal.day - lead,
            9,
          );
          if (date.isAfter(now)) result.add(PlannedReminder(s, date, lead));
        }
      }
    }
    result.sort((a, b) {
      final d = a.date.compareTo(b.date);
      return d == 0 ? a.subscription.id.compareTo(b.subscription.id) : d;
    });
    return result.take(limit).toList();
  }
}
