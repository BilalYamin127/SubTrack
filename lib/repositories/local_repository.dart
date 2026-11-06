import 'dart:convert';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/subscription.dart';

class LocalRepository {
  final Box<String> box;
  LocalRepository(this.box);
  static Future<LocalRepository> open() async {
    await Hive.initFlutter();
    return LocalRepository(await Hive.openBox<String>('subtrack_v1'));
  }

  List<Subscription> loadSubscriptions() => box.keys
      .where((k) => k.toString().startsWith('subscription:'))
      .map(
        (k) => Subscription.fromJson(
          Map<String, dynamic>.from(jsonDecode(box.get(k)!)),
        ),
      )
      .toList();
  List<Category> loadCategories() => box.get('categories') == null
      ? List.of(Category.defaults)
      : (jsonDecode(box.get('categories')!) as List)
            .map((j) => Category.fromJson(Map<String, dynamic>.from(j)))
            .toList();
  Map<String, dynamic> loadSettings() => Map<String, dynamic>.from(
    jsonDecode(box.get('settings', defaultValue: '{}')!),
  );
  Future<void> save(Subscription s) =>
      box.put('subscription:${s.id}', jsonEncode(s.toJson()));
  Future<void> delete(String id) => box.delete('subscription:$id');
  Future<void> categories(List<Category> values) =>
      box.put('categories', jsonEncode(values.map((c) => c.toJson()).toList()));
  Future<void> settings(Map<String, dynamic> values) =>
      box.put('settings', jsonEncode(values));
  Future<void> clear() => box.clear();
}
