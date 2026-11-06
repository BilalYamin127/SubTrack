enum BillingFrequency { weekly, monthly, quarterly, halfYearly, yearly, custom }

enum SubscriptionStatus { active, paused, cancelled }

class Subscription {
  final String id, name, categoryId, currencyCode;
  final double price;
  final BillingFrequency billingFrequency;
  final int? customIntervalDays;
  final DateTime firstPaymentDate, nextRenewalDate, createdAt, updatedAt;
  final SubscriptionStatus status;
  final List<int> reminderDays;
  final String? notes;
  const Subscription({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.currencyCode,
    required this.billingFrequency,
    this.customIntervalDays,
    required this.firstPaymentDate,
    required this.nextRenewalDate,
    required this.status,
    required this.reminderDays,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'categoryId': categoryId,
    'price': price,
    'currencyCode': currencyCode,
    'billingFrequency': billingFrequency.name,
    'customIntervalDays': customIntervalDays,
    'firstPaymentDate': firstPaymentDate.toIso8601String(),
    'nextRenewalDate': nextRenewalDate.toIso8601String(),
    'status': status.name,
    'reminderDays': reminderDays,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
    id: j['id'],
    name: j['name'],
    categoryId: j['categoryId'],
    price: (j['price'] as num).toDouble(),
    currencyCode: j['currencyCode'],
    billingFrequency: BillingFrequency.values.byName(j['billingFrequency']),
    customIntervalDays: j['customIntervalDays'],
    firstPaymentDate: DateTime.parse(j['firstPaymentDate']),
    nextRenewalDate: DateTime.parse(j['nextRenewalDate']),
    status: SubscriptionStatus.values.byName(j['status']),
    reminderDays: List<int>.from(j['reminderDays']),
    notes: j['notes'],
    createdAt: DateTime.parse(j['createdAt']),
    updatedAt: DateTime.parse(j['updatedAt']),
  );
  Subscription withStatus(SubscriptionStatus value) => Subscription.fromJson({
    ...toJson(),
    'status': value.name,
    'updatedAt': DateTime.now().toIso8601String(),
  });
}

class Category {
  final String id, name, icon;
  final int color;
  const Category(this.id, this.name, this.color, [this.icon = 'category']);
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color,
    'icon': icon,
  };
  factory Category.fromJson(Map<String, dynamic> j) =>
      Category(j['id'], j['name'], j['color'], j['icon']);
  static const defaults = [
    Category('entertainment', 'Entertainment', 0xff8b5cf6),
    Category('productivity', 'Productivity', 0xff3b82f6),
    Category('utilities', 'Utilities', 0xff14b8a6),
    Category('fitness', 'Fitness', 0xfff97316),
    Category('education', 'Education', 0xffeab308),
    Category('shopping', 'Shopping', 0xffec4899),
    Category('other', 'Other', 0xff64748b),
  ];
}
