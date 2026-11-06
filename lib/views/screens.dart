import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/subscription.dart';
import '../services/billing_service.dart';
import '../view_models/app_view_model.dart';

String money(double amount, String code) => NumberFormat.currency(
  name: code,
  symbol: '$code ',
  decimalDigits: 2,
).format(amount);
String dateLabel(DateTime date) => DateFormat.yMMMd().format(date);
const frequencyLabels = [
  'Weekly',
  'Monthly',
  'Every 3 months',
  'Every 6 months',
  'Yearly',
  'Custom interval',
];
Future<void> guarded(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
      );
    }
  }
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Keep data'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
    false;

class AppShell extends StatelessWidget {
  final String location;
  final Widget child;
  const AppShell({super.key, required this.location, required this.child});
  static const paths = [
    '/',
    '/subscriptions',
    '/upcoming',
    '/analytics',
    '/categories',
    '/settings',
  ];
  static const labels = [
    'Overview',
    'Subscriptions',
    'Upcoming',
    'Analytics',
    'Categories',
    'Settings',
  ];
  static const icons = [
    Icons.dashboard_outlined,
    Icons.layers_outlined,
    Icons.event_outlined,
    Icons.donut_large_outlined,
    Icons.category_outlined,
    Icons.settings_outlined,
  ];
  @override
  Widget build(BuildContext context) {
    final selected = paths.indexOf(location).clamp(0, 5);
    return LayoutBuilder(
      builder: (context, size) {
        final wide = size.maxWidth >= 900;
        return Scaffold(
          body: Row(
            children: [
              if (wide)
                Container(
                  width: 232,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: .08),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(28),
                          child: Brand(),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(28, 24, 0, 14),
                          child: Text(
                            'YOUR WORKSPACE',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        for (var i = 0; i < paths.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 3,
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              selected: selected == i,
                              selectedTileColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              leading: Icon(icons[i]),
                              title: Text(labels[i]),
                              onTap: () => context.go(paths[i]),
                            ),
                          ),
                        const Spacer(),
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Row(
                            children: [
                              Icon(Icons.shield_outlined, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Private. Offline. Yours.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(child: SafeArea(child: child)),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: selected > 3 ? 1 : selected,
                  onDestinationSelected: (i) => context.go(paths[i]),
                  destinations: [
                    for (var i = 0; i < 4; i++)
                      NavigationDestination(
                        icon: Icon(icons[i]),
                        label: labels[i],
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class Brand extends StatelessWidget {
  const Brand({super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.asset(
          'assets/branding/app-icon-256.png',
          width: 24,
          height: 24,
          semanticLabel: 'SubTrack',
        ),
      ),
      const SizedBox(width: 10),
      const Flexible(
        child: Text(
          'SubTrack',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 23,
            letterSpacing: -1,
          ),
        ),
      ),
    ],
  );
}

class PageBody extends StatelessWidget {
  final String title, subtitle;
  final List<Widget> children;
  final Widget? action;
  const PageBody({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.action,
  });
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 20 : 36),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 12,
              spacing: 20,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                ?action,
              ],
            ),
            const SizedBox(height: 28),
            ...children,
          ],
        ),
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  final String title, message;
  const EmptyState({
    super.key,
    this.title = 'A little clarity starts here',
    this.message =
        'Add your first subscription to see your recurring expenses.',
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(38),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => context.push('/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add subscription'),
            ),
          ],
        ),
      ),
    ),
  );
}

List<Subscription> activeSorted(AppState state) =>
    state.subscriptions
        .where((s) => s.status == SubscriptionStatus.active)
        .toList()
      ..sort(
        (a, b) => BillingService.next(
          a,
          DateTime.now(),
        ).compareTo(BillingService.next(b, DateTime.now())),
      );

class SubscriptionTile extends StatelessWidget {
  final Subscription subscription;
  final List<Category> categories;
  const SubscriptionTile(this.subscription, this.categories, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = subscription;
    final cat = categories.firstWhere(
      (c) => c.id == s.categoryId,
      orElse: () => Category.defaults.last,
    );
    final next = BillingService.next(s, DateTime.now());
    final days = BillingService.daysUntil(next, DateTime.now());
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: Color(cat.color).withValues(alpha: .13),
          child: Text(
            s.name.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: Color(cat.color),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          s.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${cat.name} · ${s.status == SubscriptionStatus.active ? (days == 0 ? 'Today' : dateLabel(next)) : s.status.name}\n${frequencyLabels[s.billingFrequency.index]} · Projected',
        ),
        isThreeLine: true,
        trailing: Text(
          money(s.price, s.currencyCode),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        onTap: () => context.push('/subscription/${s.id}'),
      ),
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    final active = activeSorted(state);
    final totals = BillingService.totals(active);
    return PageBody(
      title: 'Your subscriptions, simplified.',
      subtitle: DateFormat('EEEE, MMMM d').format(DateTime.now()),
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
          FilledButton.icon(
            onPressed: () => context.push('/add'),
            icon: const Icon(Icons.add),
            label: const Text('Add subscription'),
          ),
        ],
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff7650d6), Color(0xff49318c)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white70,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'YOUR RECURRING SPEND',
                      style: TextStyle(
                        color: Colors.white70,
                        letterSpacing: 2,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (totals.isEmpty)
                const Text(
                  'No active expenses',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              for (final e in totals.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${money(e.value, e.key)} / month',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${money(e.value * 12, e.key)} yearly equivalent',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              const Text(
                'Projected equivalents • currencies are calculated separately',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (c, b) => Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _stat(
                context,
                'Active subscriptions',
                '${active.length}',
                Icons.layers_outlined,
                b.maxWidth,
              ),
              _stat(
                context,
                'Due in the next 7 days',
                '${active.where((s) => BillingService.daysUntil(BillingService.next(s, DateTime.now()), DateTime.now()) <= 7).length}',
                Icons.event_available_outlined,
                b.maxWidth,
              ),
              _stat(
                context,
                'Next projected payment',
                active.isEmpty
                    ? '—'
                    : dateLabel(
                        BillingService.next(active.first, DateTime.now()),
                      ),
                Icons.schedule_outlined,
                b.maxWidth,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Coming up next',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/upcoming'),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (active.isEmpty)
          const EmptyState()
        else
          ...active.take(5).map((s) => SubscriptionTile(s, state.categories)),
        if (state.notificationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              state.notificationError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 16),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('A clearer picture, without connecting your bank'),
            subtitle: Text(
              'Renewals are projections. SubTrack does not confirm payments or cancel subscriptions with providers.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _stat(
    BuildContext c,
    String label,
    String value,
    IconData icon,
    double width,
  ) => SizedBox(
    width: width < 600 ? width : (width - 32) / 3,
    child: Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(c).colorScheme.secondary),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(
                c,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(label),
          ],
        ),
      ),
    ),
  );
}

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});
  @override
  ConsumerState<SubscriptionsScreen> createState() => _SubscriptionsState();
}

class _SubscriptionsState extends ConsumerState<SubscriptionsScreen> {
  String query = '', status = 'all', category = 'all';
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    final items =
        state.subscriptions
            .where(
              (s) =>
                  s.name.toLowerCase().contains(query.toLowerCase()) &&
                  (status == 'all' || s.status.name == status) &&
                  (category == 'all' || s.categoryId == category),
            )
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    return PageBody(
      title: 'All subscriptions',
      subtitle: 'Everything recurring, in one place.',
      action: FilledButton.icon(
        onPressed: () => context.push('/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add new'),
      ),
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search subscriptions',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => query = v),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            DropdownButton<String>(
              value: status,
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Text('All statuses'),
                ),
                for (final s in SubscriptionStatus.values)
                  DropdownMenuItem(value: s.name, child: Text(s.name)),
              ],
              onChanged: (v) => setState(() => status = v!),
            ),
            DropdownButton<String>(
              value: category,
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Text('All categories'),
                ),
                for (final c in state.categories)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() => category = v!),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (items.isEmpty)
          const EmptyState(
            title: 'Nothing here yet',
            message: 'Add a subscription or adjust your filters.',
          )
        else
          ...items.map((s) => SubscriptionTile(s, state.categories)),
      ],
    );
  }
}

class UpcomingScreen extends ConsumerWidget {
  const UpcomingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    final items = activeSorted(state);
    final groups = <String, List<Subscription>>{
      'Today': [],
      'Within 7 days': [],
      'Within 30 days': [],
      'Later': [],
    };
    for (final s in items) {
      final d = BillingService.daysUntil(
        BillingService.next(s, DateTime.now()),
        DateTime.now(),
      );
      groups[d == 0
              ? 'Today'
              : d <= 7
              ? 'Within 7 days'
              : d <= 30
              ? 'Within 30 days'
              : 'Later']!
          .add(s);
    }
    return PageBody(
      title: 'Upcoming renewals',
      subtitle:
          'Plan ahead. These dates are projected, not confirmed payments.',
      children: [
        if (items.isEmpty) const EmptyState(),
        for (final e in groups.entries)
          if (e.value.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '${e.key} · ${e.value.length}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...e.value.map((s) => SubscriptionTile(s, state.categories)),
          ],
      ],
    );
  }
}

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsState();
}

class _AnalyticsState extends ConsumerState<AnalyticsScreen> {
  String? currency;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    final totals = BillingService.totals(state.subscriptions);
    final selected = totals.containsKey(currency)
        ? currency
        : totals.keys.firstOrNull;
    final items =
        state.subscriptions
            .where(
              (s) =>
                  s.status == SubscriptionStatus.active &&
                  s.currencyCode == selected,
            )
            .toList()
          ..sort(
            (a, b) =>
                BillingService.monthly(b).compareTo(BillingService.monthly(a)),
          );
    final byCategory = <Category, double>{};
    for (final s in items) {
      final c = state.categories.firstWhere(
        (c) => c.id == s.categoryId,
        orElse: () => Category.defaults.last,
      );
      byCategory.update(
        c,
        (v) => v + BillingService.monthly(s),
        ifAbsent: () => BillingService.monthly(s),
      );
    }
    return PageBody(
      title: 'Expense insights',
      subtitle:
          'Understand your recurring commitments, one currency at a time.',
      action: selected == null
          ? null
          : DropdownButton<String>(
              value: selected,
              items: totals.keys
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => currency = v),
            ),
      children: [
        if (selected == null)
          const EmptyState()
        else ...[
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              Chip(
                label: Text('${money(totals[selected]!, selected)} / month'),
              ),
              Chip(
                label: Text(
                  '${money(totals[selected]! * 12, selected)} / year',
                ),
              ),
              Chip(label: Text('${items.length} active')),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly spend by category',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  if (totals[selected]! > 0)
                    SizedBox(
                      height: 240,
                      child: PieChart(
                        PieChartData(
                          centerSpaceRadius: 65,
                          sectionsSpace: 5,
                          sections: byCategory.entries
                              .where((e) => e.value > 0)
                              .map(
                                (e) => PieChartSectionData(
                                  value: e.value,
                                  color: Color(e.key.color),
                                  radius: 38,
                                  showTitle: false,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  for (final e in byCategory.entries)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 6,
                        backgroundColor: Color(e.key.color),
                      ),
                      title: Text(e.key.name),
                      trailing: Text(money(e.value, selected)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Most expensive subscriptions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          for (final s in items)
            Card(
              child: ListTile(
                title: Text(s.name),
                subtitle: const Text('Monthly equivalent'),
                trailing: Text(money(BillingService.monthly(s), selected)),
                onTap: () => context.push('/subscription/${s.id}'),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Weekly: price × 52 ÷ 12. Custom intervals: price × 365.2425 ÷ interval days ÷ 12. Totals include active subscriptions only.',
          ),
        ],
      ],
    );
  }
}

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    return PageBody(
      title: 'Categories',
      subtitle: 'Give every recurring expense a home.',
      action: FilledButton.icon(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New category'),
      ),
      children: [
        for (final c in state.categories)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(c.color).withValues(alpha: .15),
                child: Icon(Icons.category_outlined, color: Color(c.color)),
              ),
              title: Text(c.name),
              trailing: Text(
                '${state.subscriptions.where((s) => s.categoryId == c.id).length} subscriptions',
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    var color = 0xff8b5cf6;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLength: 40,
                decoration: const InputDecoration(labelText: 'Category name'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                children: [
                  for (final c in Category.defaults)
                    InkWell(
                      onTap: () => setState(() => color = c.color),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(c.color),
                        child: color == c.color
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;
                await guarded(context, () async {
                  await ref
                      .read(appProvider.notifier)
                      .addCategory(controller.text, color);
                  if (context.mounted) Navigator.pop(context);
                });
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    final vm = ref.read(appProvider.notifier);
    return PageBody(
      title: 'Settings',
      subtitle: 'Make SubTrack feel like yours.',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.currency_exchange),
                  title: const Text('Default currency'),
                  trailing: DropdownButton<String>(
                    value: state.currency,
                    items: currencies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) =>
                        guarded(context, () => vm.setting('currency', v)),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Appearance'),
                  trailing: DropdownButton<String>(
                    value: state.theme,
                    items: ['system', 'light', 'dark']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) =>
                        guarded(context, () => vm.setting('theme', v)),
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Local reminders'),
                  subtitle: const Text(
                    'At 9:00 AM local time. Device permission required.',
                  ),
                  value: state.reminders,
                  onChanged: (v) =>
                      guarded(context, () => vm.enableReminders(v)),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: const Text('First day of week'),
                  trailing: DropdownButton<int>(
                    value: state.settings['firstDay'] as int? ?? 1,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Monday')),
                      DropdownMenuItem(value: 7, child: Text('Sunday')),
                    ],
                    onChanged: (v) =>
                        guarded(context, () => vm.setting('firstDay', v)),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Manage categories'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/categories'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (state.notificationError != null) Text(state.notificationError!),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Reminders use a rolling schedule of the next 60 alerts within one year. Open SubTrack regularly to refresh it. Reminder delivery depends on device permissions and power settings. Web preview does not support notifications.',
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: const Text('Clear all local data'),
            subtitle: const Text(
              'Permanently delete subscriptions, categories and preferences.',
            ),
            onTap: () async {
              if (await confirm(
                context,
                'Clear local data?',
                'This permanently deletes all SubTrack records on this device.',
              )) {
                if (context.mounted) await guarded(context, vm.clear);
              }
            },
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/privacy'),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms of use'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/terms'),
              ),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Your local data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/data-control'),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/support'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Center(child: Text('SubTrack 1.0.0 • Stored on your device')),
      ],
    );
  }
}

const currencies = [
  'USD',
  'PKR',
  'EUR',
  'GBP',
  'INR',
  'AED',
  'SAR',
  'CAD',
  'AUD',
  'JPY',
  'CNY',
  'CHF',
  'BDT',
  'NZD',
  'SGD',
];

class SubscriptionDetails extends ConsumerWidget {
  final String id;
  const SubscriptionDetails({super.key, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    final s = state.subscriptions.where((s) => s.id == id).firstOrNull;
    if (s == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Subscription')),
        body: const Center(child: Text('Subscription not found.')),
      );
    }
    final vm = ref.read(appProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.name),
        actions: [
          IconButton(
            onPressed: () => context.push('/edit/$id'),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: PageBody(
        title: money(s.price, s.currencyCode),
        subtitle:
            '${frequencyLabels[s.billingFrequency.index]} · ${s.status.name}',
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Next projected renewal'),
                  subtitle: Text(
                    dateLabel(BillingService.next(s, DateTime.now())),
                  ),
                ),
                ListTile(
                  title: const Text('First payment date'),
                  subtitle: Text(dateLabel(s.firstPaymentDate)),
                ),
                ListTile(
                  title: const Text('Category'),
                  subtitle: Text(
                    state.categories
                        .firstWhere(
                          (c) => c.id == s.categoryId,
                          orElse: () => Category.defaults.last,
                        )
                        .name,
                  ),
                ),
                ListTile(
                  title: const Text('Monthly equivalent'),
                  subtitle: Text(
                    money(BillingService.monthly(s), s.currencyCode),
                  ),
                ),
                ListTile(
                  title: const Text('Reminders before renewal'),
                  subtitle: Text(
                    s.reminderDays.isEmpty
                        ? 'None'
                        : s.reminderDays
                              .map((d) => d == 0 ? 'On the day' : '$d days')
                              .join(', '),
                  ),
                ),
                if (s.notes?.isNotEmpty ?? false)
                  ListTile(
                    title: const Text('Notes'),
                    subtitle: Text(s.notes!),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => guarded(
                  context,
                  () => vm.setStatus(
                    s,
                    s.status == SubscriptionStatus.active
                        ? SubscriptionStatus.paused
                        : SubscriptionStatus.active,
                  ),
                ),
                icon: Icon(
                  s.status == SubscriptionStatus.active
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
                label: Text(
                  s.status == SubscriptionStatus.active ? 'Pause' : 'Resume',
                ),
              ),
              if (s.status != SubscriptionStatus.cancelled)
                OutlinedButton(
                  onPressed: () => guarded(
                    context,
                    () => vm.setStatus(s, SubscriptionStatus.cancelled),
                  ),
                  child: const Text('Mark cancelled'),
                ),
              TextButton(
                onPressed: () async {
                  if (await confirm(
                    context,
                    'Delete ${s.name}?',
                    'This removes the local record and its reminders.',
                  )) {
                    if (context.mounted) {
                      await guarded(context, () async {
                        await vm.delete(id);
                        if (context.mounted) context.go('/subscriptions');
                      });
                    }
                  }
                },
                child: const Text('Delete record'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Changing status only updates this record. Manage or cancel your actual subscription directly with the provider.',
          ),
        ],
      ),
    );
  }
}
