import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../models/subscription.dart';
import '../services/billing_service.dart';
import '../view_models/app_view_model.dart';
import 'screens.dart';

class SubscriptionEditor extends ConsumerStatefulWidget {
  final String? id;
  const SubscriptionEditor({super.key, this.id});
  @override
  ConsumerState<SubscriptionEditor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<SubscriptionEditor> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      price = TextEditingController(),
      interval = TextEditingController(text: '30'),
      notes = TextEditingController();
  late String currency, category;
  BillingFrequency frequency = BillingFrequency.monthly;
  SubscriptionStatus status = SubscriptionStatus.active;
  DateTime first = BillingService.day(DateTime.now()),
      next = BillingService.day(DateTime.now());
  Set<int> reminders = {7, 3, 1, 0};
  Subscription? original;
  bool saving = false, missing = false;
  @override
  void initState() {
    super.initState();
    final state = ref.read(appProvider);
    currency = state.currency;
    category = state.categories.first.id;
    if (widget.id != null) {
      original = state.subscriptions
          .where((s) => s.id == widget.id)
          .firstOrNull;
      missing = original == null;
      final s = original;
      if (s != null) {
        name.text = s.name;
        price.text = s.price.toString();
        interval.text = '${s.customIntervalDays ?? 30}';
        notes.text = s.notes ?? '';
        currency = s.currencyCode;
        category = s.categoryId;
        frequency = s.billingFrequency;
        status = s.status;
        first = s.firstPaymentDate;
        next = s.nextRenewalDate;
        reminders = s.reminderDays.toSet();
      }
    }
  }

  @override
  void dispose() {
    for (final c in [name, price, interval, notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> pick(bool isFirst) async {
    final firstDay = ref.read(appProvider).settings['firstDay'] as int? ?? 1;
    // Material's en_US calendar begins Sunday; en_GB begins Monday.
    final d = await showDatePicker(
      context: context,
      initialDate: isFirst ? first : next,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
      locale: firstDay == 1
          ? const Locale('en', 'GB')
          : const Locale('en', 'US'),
    );
    if (d != null) {
      setState(() {
        if (isFirst) {
          first = d;
          if (next.isBefore(first)) next = first;
        } else {
          next = d;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    if (missing) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Subscription not found.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          original == null ? 'Add subscription' : 'Edit subscription',
        ),
      ),
      body: PageBody(
        title: original == null
            ? 'Make room for clarity.'
            : 'Update your subscription',
        subtitle: 'A few details now. Fewer surprises later.',
        children: [
          Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Subscription name',
                    hintText: 'e.g. Netflix',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: state.categories
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (v) => category = v!,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: price,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          hintText: '0.00',
                        ),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          return n == null || !n.isFinite || n < 0 || n > 1e12
                              ? 'Enter a valid price'
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: currency,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                        ),
                        items: currencies
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) => currency = v!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BillingFrequency>(
                  initialValue: frequency,
                  decoration: const InputDecoration(
                    labelText: 'Billing frequency',
                  ),
                  items: BillingFrequency.values
                      .map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(frequencyLabels[f.index]),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => frequency = v!),
                ),
                if (frequency == BillingFrequency.custom) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: interval,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Interval in days',
                      helperText: 'Annualized using 365.2425 days per year.',
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return n == null || n < 1 || n > 36500
                          ? 'Enter 1–36500 days'
                          : null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('First payment date'),
                        subtitle: Text(dateLabel(first)),
                        trailing: const Icon(Icons.calendar_today_outlined),
                        onTap: () => pick(true),
                      ),
                      ListTile(
                        title: const Text('Next renewal / recurrence anchor'),
                        subtitle: Text(dateLabel(next)),
                        trailing: const Icon(Icons.event_repeat),
                        onTap: () => pick(false),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Choose the original intended renewal day. A 31st renewal is clamped in short months and returns to the 31st afterward. Past dates roll forward automatically.',
                  ),
                ),
                DropdownButtonFormField<SubscriptionStatus>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: SubscriptionStatus.values
                      .map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.name)),
                      )
                      .toList(),
                  onChanged: (v) => status = v!,
                ),
                const SizedBox(height: 24),
                Text(
                  'Remind me',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final d in [7, 3, 1, 0])
                      FilterChip(
                        label: Text(
                          d == 0 ? 'On renewal day' : '$d days before',
                        ),
                        selected: reminders.contains(d),
                        onSelected: (v) => setState(
                          () => v ? reminders.add(d) : reminders.remove(d),
                        ),
                      ),
                  ],
                ),
                if (!state.reminders)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Preferences are saved. Enable local reminders in Settings to receive alerts.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notes,
                  maxLines: 4,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: saving ? null : _save,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(saving ? 'Saving…' : 'Save subscription'),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!form.currentState!.validate()) return;
    if (next.isBefore(first)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Next renewal cannot be before the first payment.'),
        ),
      );
      return;
    }
    setState(() => saving = true);
    final now = DateTime.now();
    await guarded(context, () async {
      final s = Subscription(
        id: original?.id ?? const Uuid().v4(),
        name: name.text.trim(),
        categoryId: category,
        price: double.parse(price.text),
        currencyCode: currency,
        billingFrequency: frequency,
        customIntervalDays: frequency == BillingFrequency.custom
            ? int.parse(interval.text)
            : null,
        firstPaymentDate: first,
        nextRenewalDate: next,
        status: status,
        reminderDays: reminders.toList()..sort((a, b) => b.compareTo(a)),
        notes: notes.text.trim(),
        createdAt: original?.createdAt ?? now,
        updatedAt: now,
      );
      await ref.read(appProvider.notifier).save(s);
      if (mounted) context.pop();
    });
    if (mounted) setState(() => saving = false);
  }
}
