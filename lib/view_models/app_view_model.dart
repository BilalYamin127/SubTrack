import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/subscription.dart';
import '../repositories/local_repository.dart';
import '../services/notification_service.dart';

final repositoryProvider = Provider<LocalRepository>(
  (ref) => throw UnimplementedError(),
);
final notificationProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError(),
);
final appProvider = NotifierProvider<AppViewModel, AppState>(AppViewModel.new);

class AppState {
  final List<Subscription> subscriptions;
  final List<Category> categories;
  final Map<String, dynamic> settings;
  final String? notificationError;
  const AppState(
    this.subscriptions,
    this.categories,
    this.settings, [
    this.notificationError,
  ]);
  String get currency => settings['currency'] as String? ?? 'USD';
  String get theme => settings['theme'] as String? ?? 'system';
  bool get reminders => settings['reminders'] as bool? ?? false;
}

class AppViewModel extends Notifier<AppState> {
  LocalRepository get repo => ref.read(repositoryProvider);
  @override
  AppState build() => AppState(
    repo.loadSubscriptions(),
    repo.loadCategories(),
    repo.loadSettings(),
  );
  Future<void> refreshReminders() async {
    try {
      await ref
          .read(notificationProvider)
          .sync(List.of(state.subscriptions), state.reminders);
      state = AppState(state.subscriptions, state.categories, state.settings);
    } catch (_) {
      state = AppState(
        state.subscriptions,
        state.categories,
        state.settings,
        'Reminders could not be scheduled. Check device permissions and reopen the app.',
      );
    }
  }

  Future<void> save(Subscription s) async {
    await repo.save(s);
    state = AppState(
      repo.loadSubscriptions(),
      state.categories,
      state.settings,
    );
    await refreshReminders();
  }

  Future<void> delete(String id) async {
    await repo.delete(id);
    state = AppState(
      repo.loadSubscriptions(),
      state.categories,
      state.settings,
    );
    await refreshReminders();
  }

  Future<void> setStatus(Subscription s, SubscriptionStatus value) =>
      save(s.withStatus(value));
  Future<void> addCategory(String name, int color) async {
    if (state.categories.any(
      (c) => c.name.toLowerCase() == name.trim().toLowerCase(),
    )) {
      throw ArgumentError('A category with this name already exists.');
    }
    final values = [
      ...state.categories,
      Category(const Uuid().v4(), name.trim(), color),
    ];
    await repo.categories(values);
    state = AppState(state.subscriptions, values, state.settings);
  }

  Future<void> setting(String key, dynamic value) async {
    final values = {...state.settings, key: value};
    await repo.settings(values);
    state = AppState(state.subscriptions, state.categories, values);
    await refreshReminders();
  }

  Future<void> enableReminders(bool value) async {
    if (value && !await ref.read(notificationProvider).requestPermission()) {
      throw StateError(
        'Notifications are unavailable or permission was denied. Enable them in device settings.',
      );
    }
    await setting('reminders', value);
  }

  Future<void> clear() async {
    await repo.clear();
    state = AppState([], List.of(Category.defaults), {});
    await refreshReminders();
  }
}
