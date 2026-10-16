import 'package:pdf_builder/shared/database/history_database.dart';

class HistoryService {
  static Future<void> addHistory(String path) async {
    final title = path.split('/').last;
    final item = HistoryItem(
      title: title,
      path: path,
      type: 'PDF Document',
      createdAt: DateTime.now().toIso8601String(),
    );
    await HistoryDatabase.instance.insert(item);
  }

  static Future<List<String>> getHistory() async {
    final items = await HistoryDatabase.instance.fetchAll();
    return items.map((e) => e.path).toList();
  }

  static Future<void> clearHistory() async {
    final items = await HistoryDatabase.instance.fetchAll();
    for (var item in items) {
      if (item.id != null) {
        await HistoryDatabase.instance.delete(item.id!);
      }
    }
  }
}
