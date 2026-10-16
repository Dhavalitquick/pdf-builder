import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_builder/core/history_service.dart';

class PdfStorageService {
  static Future<File> savePdfFile(List<int> bytes, String preferredName) async {
    final cleanName = preferredName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final fileName = cleanName.endsWith('.pdf') ? cleanName : '$cleanName.pdf';
    
    Directory? targetDir;
    if (Platform.isAndroid) {
      try {
        final publicDownload = Directory('/storage/emulated/0/Download');
        if (await publicDownload.exists()) {
          targetDir = Directory('${publicDownload.path}/PDF Storage');
        }
      } catch (_) {}
    }

    if (targetDir == null) {
      final docDir = await getApplicationDocumentsDirectory();
      targetDir = Directory('${docDir.path}/PDF Storage');
    }

    if (!await targetDir.exists()) {
      try {
        await targetDir.create(recursive: true);
      } catch (_) {
        final docDir = await getApplicationDocumentsDirectory();
        targetDir = Directory('${docDir.path}/PDF Storage');
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
      }
    }

    final file = File('${targetDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    // Register in history DB
    await HistoryService.addHistory(file.path);

    return file;
  }
}
