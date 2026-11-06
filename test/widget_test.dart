import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:subtrack/main.dart';
import 'package:subtrack/repositories/local_repository.dart';
import 'package:subtrack/view_models/app_view_model.dart';
import 'repository_view_model_test.dart' show FakeNotifications;

void main() {
  testWidgets(
    'mobile flow creates a record and renders details without overflow',
    (tester) async {
      final dir = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('subtrack_widget'),
      ))!;
      Hive.init(dir.path);
      final box = (await tester.runAsync(
        () => Hive.openBox<String>('widget'),
      ))!;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              repositoryProvider.overrideWithValue(LocalRepository(box)),
              notificationProvider.overrideWithValue(FakeNotifications()),
            ],
            child: const SubTrackApp(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('No active expenses'), findsOneWidget);
        expect(tester.takeException(), isNull);
        router.push('/add');
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).at(0), 'Netflix');
        await tester.enterText(find.byType(TextFormField).at(1), '14.99');
        await tester.dragUntilVisible(
          find.text('Save subscription'),
          find.byType(SingleChildScrollView).last,
          const Offset(0, -300),
        );
        await tester.runAsync(() async {
          await tester.tap(find.text('Save subscription'));
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pumpAndSettle();
        expect(find.text('Netflix'), findsOneWidget);
        expect(tester.takeException(), isNull);
        router.go('/subscriptions');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Netflix'));
        await tester.pumpAndSettle();
        expect(find.text('Next projected renewal'), findsOneWidget);
        expect(find.text('USD 14.99'), findsWidgets);
        expect(tester.takeException(), isNull);
        router.go('/analytics');
        await tester.pumpAndSettle();
        expect(find.text('Monthly spend by category'), findsOneWidget);
        expect(tester.takeException(), isNull);
        tester.view.physicalSize = const Size(1440, 1000);
        await tester.pumpAndSettle();
        expect(find.text('YOUR WORKSPACE'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        router.go('/');
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await tester.runAsync(() async {
          await box.close();
          await dir.delete(recursive: true);
        });
      }
    },
  );
}
