import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:pdf_builder/shared/database/history_database.dart';

final historyProvider = StateNotifierProvider<HistoryNotifier, List<HistoryItem>>((ref) {
  return HistoryNotifier();
});

class HistoryNotifier extends StateNotifier<List<HistoryItem>> {
  HistoryNotifier() : super([]) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    final items = await HistoryDatabase.instance.fetchAll();
    state = items;
  }

  Future<void> addItem(String title, String path, String type) async {
    final newItem = HistoryItem(
      title: title,
      path: path,
      type: type,
      createdAt: DateTime.now().toIso8601String(),
    );
    await HistoryDatabase.instance.insert(newItem);
    await loadHistory();
  }

  Future<void> deleteItem(int id) async {
    await HistoryDatabase.instance.delete(id);
    await loadHistory();
  }
}
