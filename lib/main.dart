import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'repositories/local_repository.dart';
import 'services/notification_service.dart';
import 'view_models/app_view_model.dart';
import 'views/screens.dart';
import 'views/subscription_editor.dart';
import 'views/legal_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final repo = await LocalRepository.open();
    final notifications = NotificationService();
    try {
      await notifications.initialize();
    } catch (_) {
      /* Data remains available if platform reminders fail. */
    }
    runApp(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          notificationProvider.overrideWithValue(notifications),
        ],
        child: const SubTrackApp(),
      ),
    );
  } catch (_) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Local storage could not be opened. Please restart SubTrack.',
            ),
          ),
        ),
      ),
    );
  }
}

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/privacy',
      builder: (_, _) => const LegalScreen(
        title: 'Privacy policy',
        asset: 'docs/legal/privacy-policy.md',
      ),
    ),
    GoRoute(
      path: '/terms',
      builder: (_, _) => const LegalScreen(
        title: 'Terms of use',
        asset: 'docs/legal/terms-of-use.md',
      ),
    ),
    GoRoute(
      path: '/support',
      builder: (_, _) =>
          const LegalScreen(title: 'Support', asset: 'docs/legal/support.md'),
    ),
    GoRoute(
      path: '/data-control',
      builder: (_, _) => const LegalScreen(
        title: 'Your local data',
        asset: 'docs/legal/local-data-control.md',
      ),
    ),
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
        GoRoute(
          path: '/subscriptions',
          builder: (_, _) => const SubscriptionsScreen(),
        ),
        GoRoute(path: '/upcoming', builder: (_, _) => const UpcomingScreen()),
        GoRoute(path: '/analytics', builder: (_, _) => const AnalyticsScreen()),
        GoRoute(
          path: '/categories',
          builder: (_, _) => const CategoriesScreen(),
        ),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      ],
    ),
    GoRoute(path: '/add', builder: (_, _) => const SubscriptionEditor()),
    GoRoute(
      path: '/subscription/:id',
      builder: (_, s) => SubscriptionDetails(id: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/edit/:id',
      builder: (_, s) => SubscriptionEditor(id: s.pathParameters['id']!),
    ),
  ],
);

class SubTrackApp extends ConsumerStatefulWidget {
  const SubTrackApp({super.key});
  @override
  ConsumerState<SubTrackApp> createState() => _SubTrackAppState();
}

class _SubTrackAppState extends ConsumerState<SubTrackApp>
    with WidgetsBindingObserver {
  Timer? timer;
  DateTime lastClock = DateTime.now();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appProvider.notifier).refreshReminders();
    });
    timer = Timer.periodic(const Duration(minutes: 1), (_) {
      final now = DateTime.now();
      final clockChanged =
          now.year != lastClock.year ||
          now.month != lastClock.month ||
          now.day != lastClock.day ||
          now.timeZoneOffset != lastClock.timeZoneOffset ||
          now.difference(lastClock).isNegative ||
          now.difference(lastClock) > const Duration(minutes: 2);
      lastClock = now;
      if (clockChanged) ref.read(appProvider.notifier).refreshReminders();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(appProvider.notifier).refreshReminders();
      lastClock = DateTime.now();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    ThemeData theme(Brightness brightness) {
      final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xff7755dc),
        brightness: brightness,
        secondary: const Color(0xff16a898),
      );
      return ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: scheme,
        scaffoldBackgroundColor: brightness == Brightness.light
            ? const Color(0xfff7f7fc)
            : const Color(0xff11121b),
        cardTheme: CardThemeData(
          elevation: 0,
          color: brightness == Brightness.light
              ? Colors.white
              : const Color(0xff1d1e2a),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      );
    }

    return MaterialApp.router(
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('en', 'US'), Locale('en', 'GB')],
      title: 'SubTrack',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: switch (state.theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      routerConfig: router,
    );
  }
}
