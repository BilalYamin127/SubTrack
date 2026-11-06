import 'package:flutter_test/flutter_test.dart';
import 'package:subtrack/models/subscription.dart';
import 'package:subtrack/services/billing_service.dart';
import 'package:subtrack/services/reminder_planner.dart';

Subscription sample({
  String id = '1',
  String currency = 'USD',
  BillingFrequency frequency = BillingFrequency.monthly,
  double price = 12,
  DateTime? anchor,
  SubscriptionStatus status = SubscriptionStatus.active,
  List<int> reminders = const [7, 3, 1, 0],
  int days = 10,
}) => Subscription(
  id: id,
  name: 'Test',
  categoryId: 'other',
  price: price,
  currencyCode: currency,
  billingFrequency: frequency,
  customIntervalDays: days,
  firstPaymentDate: DateTime(2020),
  nextRenewalDate: anchor ?? DateTime(2024, 1, 31),
  status: status,
  reminderDays: reminders,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);
void main() {
  test('month-end clamp recovers original anchor', () {
    final s = sample();
    expect(BillingService.occurrence(s, 1), DateTime(2024, 2, 29));
    expect(BillingService.occurrence(s, 2), DateTime(2024, 3, 31));
    expect(BillingService.occurrence(s, 13), DateTime(2025, 2, 28));
  });
  test('29th and 30th recover after February', () {
    for (final d in [29, 30]) {
      final s = sample(anchor: DateTime(2025, 1, d));
      expect(BillingService.occurrence(s, 1), DateTime(2025, 2, 28));
      expect(BillingService.occurrence(s, 2), DateTime(2025, 3, d));
    }
  });
  test('yearly leap day recovers in leap year', () {
    final s = sample(
      frequency: BillingFrequency.yearly,
      anchor: DateTime(2024, 2, 29),
    );
    expect(BillingService.occurrence(s, 1), DateTime(2025, 2, 28));
    expect(BillingService.occurrence(s, 4), DateTime(2028, 2, 29));
  });
  test('quarter and half-year use calendar months', () {
    expect(
      BillingService.occurrence(
        sample(frequency: BillingFrequency.quarterly),
        1,
      ),
      DateTime(2024, 4, 30),
    );
    expect(
      BillingService.occurrence(
        sample(frequency: BillingFrequency.halfYearly),
        1,
      ),
      DateTime(2024, 7, 31),
    );
  });
  test('today remains due and old anchors roll forward', () {
    final s = sample();
    expect(
      BillingService.next(s, DateTime(2026, 11, 30, 23)),
      DateTime(2026, 11, 30),
    );
    expect(
      BillingService.next(s, DateTime(2026, 12, 1)),
      DateTime(2026, 12, 31),
    );
    expect(
      BillingService.next(
        sample(
          frequency: BillingFrequency.custom,
          days: 1,
          anchor: DateTime(1900),
        ),
        DateTime(2026, 11, 6),
      ),
      DateTime(2026, 11, 6),
    );
  });
  test('monthly equivalents follow documented formulas', () {
    for (final entry in {
      BillingFrequency.weekly: 52.0,
      BillingFrequency.monthly: 12.0,
      BillingFrequency.quarterly: 4.0,
      BillingFrequency.halfYearly: 2.0,
      BillingFrequency.yearly: 1.0,
      BillingFrequency.custom: 36.52425,
    }.entries) {
      expect(
        BillingService.monthly(sample(frequency: entry.key)),
        closeTo(entry.value, .00001),
      );
    }
  });
  test('currency totals exclude inactive records', () {
    final totals = BillingService.totals([
      sample(),
      sample(currency: 'PKR', price: 300),
      sample(status: SubscriptionStatus.paused),
      sample(status: SubscriptionStatus.cancelled),
    ]);
    expect(totals, {'USD': 12.0, 'PKR': 300.0});
  });
  test('serialization preserves all fields', () {
    final s = sample();
    expect(Subscription.fromJson(s.toJson()).toJson(), s.toJson());
  });
  test('reminders deduplicate offsets, exclude inactive and past times', () {
    final now = DateTime(2026, 11, 6, 10);
    final list = ReminderPlanner.plan([
      sample(anchor: DateTime(2026, 11, 7), reminders: [1, 1, 0]),
      sample(id: 'paused', status: SubscriptionStatus.paused),
    ], now);
    expect(list.where((r) => r.subscription.id == 'paused'), isEmpty);
    expect(list.every((r) => r.date.isAfter(now)), isTrue);
    expect(list.where((r) => r.date == DateTime(2026, 11, 7, 9)).length, 1);
    expect(
      list.map((r) => '${r.subscription.id}:${r.date}').toSet().length,
      list.length,
    );
  });
  test('old daily subscriptions still receive reminders and cap at 60', () {
    final reminders = ReminderPlanner.plan([
      sample(
        anchor: DateTime(2020),
        frequency: BillingFrequency.custom,
        days: 1,
      ),
    ], DateTime(2026, 11, 6));
    expect(reminders.length, 60);
    expect(reminders.first.date, DateTime(2026, 11, 6, 9));
  });
  test('date difference ignores time and DST', () {
    expect(
      BillingService.daysUntil(DateTime(2026, 3, 9), DateTime(2026, 3, 8, 23)),
      1,
    );
  });
}
