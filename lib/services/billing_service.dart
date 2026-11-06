import '../models/subscription.dart';

class BillingService {
  static DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime addMonths(DateTime anchor, int months) {
    final first = DateTime(anchor.year, anchor.month + months, 1);
    final last = DateTime(first.year, first.month + 1, 0).day;
    return DateTime(
      first.year,
      first.month,
      anchor.day > last ? last : anchor.day,
    );
  }

  static DateTime occurrence(Subscription s, int index) {
    final anchor = day(s.nextRenewalDate);
    return switch (s.billingFrequency) {
      BillingFrequency.weekly => DateTime(
        anchor.year,
        anchor.month,
        anchor.day + 7 * index,
      ),
      BillingFrequency.custom => DateTime(
        anchor.year,
        anchor.month,
        anchor.day + (s.customIntervalDays ?? 1) * index,
      ),
      _ => addMonths(
        anchor,
        index *
            switch (s.billingFrequency) {
              BillingFrequency.monthly => 1,
              BillingFrequency.quarterly => 3,
              BillingFrequency.halfYearly => 6,
              _ => 12,
            },
      ),
    };
  }

  static int nextIndex(Subscription s, DateTime now) {
    final today = day(now), anchor = day(s.nextRenewalDate);
    if (!anchor.isBefore(today)) return 0;
    final months = switch (s.billingFrequency) {
      BillingFrequency.monthly => 1,
      BillingFrequency.quarterly => 3,
      BillingFrequency.halfYearly => 6,
      BillingFrequency.yearly => 12,
      _ => 0,
    };
    var i = months > 0
        ? ((today.year - anchor.year) * 12 + today.month - anchor.month) ~/
              months
        : daysUntil(today, anchor) ~/
              (s.billingFrequency == BillingFrequency.weekly
                  ? 7
                  : (s.customIntervalDays ?? 1));
    while (occurrence(s, i).isBefore(today)) {
      i++;
    }
    return i;
  }

  static DateTime next(Subscription s, DateTime now) =>
      occurrence(s, nextIndex(s, now));
  static double monthly(Subscription s) =>
      s.price *
      switch (s.billingFrequency) {
        BillingFrequency.weekly => 52 / 12,
        BillingFrequency.monthly => 1,
        BillingFrequency.quarterly => 1 / 3,
        BillingFrequency.halfYearly => 1 / 6,
        BillingFrequency.yearly => 1 / 12,
        BillingFrequency.custom => 365.2425 / (s.customIntervalDays ?? 1) / 12,
      };
  static Map<String, double> totals(Iterable<Subscription> items) {
    final result = <String, double>{};
    for (final s in items.where((s) => s.status == SubscriptionStatus.active)) {
      result.update(
        s.currencyCode,
        (v) => v + monthly(s),
        ifAbsent: () => monthly(s),
      );
    }
    return result;
  }

  static int daysUntil(DateTime date, DateTime now) => DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
}
