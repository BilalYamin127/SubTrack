// Generate real Flutter UI captures without modifying or deleting user data.
// Run: flutter test tools/screenshots_test.dart --update-goldens
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtrack/main.dart';
import 'package:subtrack/models/subscription.dart';
import 'package:subtrack/services/notification_service.dart';
import 'package:subtrack/view_models/app_view_model.dart';

class CaptureViewModel extends AppViewModel {
  static bool dark = false;
  @override
  AppState build() {
    final now = DateTime.now();
    Subscription record(
      String id,
      String name,
      String category,
      double price,
      BillingFrequency frequency,
      int days,
    ) => Subscription(
      id: id,
      name: name,
      categoryId: category,
      price: price,
      currencyCode: 'USD',
      billingFrequency: frequency,
      firstPaymentDate: DateTime(now.year, now.month - 3, now.day),
      nextRenewalDate: DateTime(now.year, now.month, now.day + days),
      status: SubscriptionStatus.active,
      reminderDays: const [7, 3, 1, 0],
      notes: 'Personal plan · Renewal dates are projected.',
      createdAt: now,
      updatedAt: now,
    );
    return AppState(
      [
        record(
          'stream',
          'Stream Plus',
          'entertainment',
          12.99,
          BillingFrequency.monthly,
          2,
        ),
        record(
          'music',
          'Daily Music',
          'entertainment',
          9.99,
          BillingFrequency.monthly,
          5,
        ),
        record(
          'cloud',
          'Cloud Workspace',
          'productivity',
          6.99,
          BillingFrequency.monthly,
          9,
        ),
        record(
          'internet',
          'Home Internet',
          'utilities',
          29,
          BillingFrequency.monthly,
          0,
        ),
        record(
          'gym',
          'Fitness Club',
          'fitness',
          24,
          BillingFrequency.monthly,
          18,
        ),
        record(
          'learn',
          'Learning Pass',
          'education',
          59,
          BillingFrequency.yearly,
          45,
        ),
      ],
      List.of(Category.defaults),
      {
        'currency': 'USD',
        'theme': dark ? 'dark' : 'light',
        'reminders': false,
        'firstDay': 1,
      },
    );
  }
}

class CaptureNotifications extends NotificationService {
  @override
  Future<void> sync(List<Subscription> subscriptions, bool enabled) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('capture eight real screens for Android and iOS', (tester) async {
    // Use the app's bundled Roboto font, not the test Ahem placeholder.
    final font = FontLoader('Roboto');
    final bytes = await tester.runAsync(
      () => File('assets/fonts/Roboto.ttf').readAsBytes(),
    );
    font.addFont(Future.value(ByteData.sublistView(bytes!)));
    await font.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final boundary = GlobalKey();
    Future<void> mount() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appProvider.overrideWith(CaptureViewModel.new),
            notificationProvider.overrideWithValue(CaptureNotifications()),
          ],
          child: RepaintBoundary(key: boundary, child: const SubTrackApp()),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> save(String path) async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage(
          pixelRatio:
              debugDefaultTargetPlatformOverride == TargetPlatform.android
              ? 2.5
              : 3,
        );
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(path);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      debugPrint('Captured $path');
    }

    for (final platform in ['android', 'ios']) {
      debugDefaultTargetPlatformOverride = platform == 'android'
          ? TargetPlatform.android
          : TargetPlatform.iOS;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = platform == 'android'
          ? const Size(432, 768)
          : const Size(440, 956);
      CaptureViewModel.dark = false;
      router.go('/');
      await mount();
      final prefix = 'store/$platform/en-US/screenshots';
      for (final screen in [
        (name: '01-dashboard', route: '/'),
        (name: '02-subscriptions', route: '/subscriptions'),
        (name: '03-add-subscription', route: '/add'),
        (name: '04-subscription-details', route: '/subscription/stream'),
        (name: '05-upcoming-renewals', route: '/upcoming'),
        (name: '06-expense-analytics', route: '/analytics'),
        (name: '07-categories', route: '/categories'),
        (name: '08-settings', route: '/settings'),
      ]) {
        if (screen.name == '08-settings') {
          await tester.pumpWidget(const SizedBox());
          CaptureViewModel.dark = true;
          router.go(screen.route);
          await mount();
        } else {
          router.go(screen.route);
          await tester.pumpAndSettle();
        }
        if (screen.name == '03-add-subscription') {
          await tester.enterText(
            find.byType(TextFormField).at(0),
            'Design Studio',
          );
          await tester.enterText(find.byType(TextFormField).at(1), '8.99');
          FocusManager.instance.primaryFocus?.unfocus();
        }
        await save('$prefix/${screen.name}.png');
      }
      for (final route in ['/privacy', '/terms', '/support', '/data-control']) {
        router.go(route);
        await tester.pumpAndSettle();
        expect(find.byType(SelectableText), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
    }
    debugDefaultTargetPlatformOverride = null;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    router.go('/');
  });
}
