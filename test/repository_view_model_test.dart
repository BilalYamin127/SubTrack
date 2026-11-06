import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:subtrack/repositories/local_repository.dart';
import 'package:subtrack/services/notification_service.dart';
import 'package:subtrack/view_models/app_view_model.dart';
import 'package:subtrack/models/subscription.dart';
import 'billing_test.dart' show sample;

class FakeNotifications extends NotificationService {
  List<Subscription> records = [];
  bool enabled = false;
  @override
  Future<void> sync(List<Subscription> subscriptions, bool value) async {
    records = subscriptions;
    enabled = value;
  }

  @override
  Future<bool> requestPermission() async => true;
}

void main() {
  test(
    'CRUD, status changes, settings and clear persist and refresh reminders',
    () async {
      final directory = await Directory.systemTemp.createTemp('subtrack_test');
      Hive.init(directory.path);
      final box = await Hive.openBox<String>('test');
      final repo = LocalRepository(box);
      final notifications = FakeNotifications();
      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          notificationProvider.overrideWithValue(notifications),
        ],
      );
      try {
        final vm = container.read(appProvider.notifier);
        await vm.save(sample());
        expect(repo.loadSubscriptions().length, 1);
        await vm.setStatus(sample(), SubscriptionStatus.paused);
        expect(notifications.records.single.status, SubscriptionStatus.paused);
        await vm.enableReminders(true);
        expect(repo.loadSettings()['reminders'], true);
        await vm.addCategory('Travel', 0xff123456);
        expect(repo.loadCategories().last.name, 'Travel');
        await expectLater(vm.addCategory('travel', 0), throwsArgumentError);
        await vm.delete('1');
        expect(repo.loadSubscriptions(), isEmpty);
        await vm.save(sample());
        await vm.clear();
        expect(repo.loadSubscriptions(), isEmpty);
        expect(repo.loadSettings(), isEmpty);
        expect(notifications.enabled, false);
        expect(container.read(appProvider).categories.length, 7);
      } finally {
        container.dispose();
        await box.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
