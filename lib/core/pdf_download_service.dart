import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';

Future<void> downloadPdf(
    String path,
    String title,
    BuildContext context,
    ) async {
  try {
    // ------------------------------------------------------------
    // 1. Check source PDF
    // ------------------------------------------------------------
    final sourceFile = File(path);

    if (!await sourceFile.exists()) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Source PDF file not found.'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    // ------------------------------------------------------------
    // 2. Clean filename
    // ------------------------------------------------------------
    String cleanFileName = title.trim();

    if (cleanFileName.isEmpty) {
      cleanFileName = 'document';
    }

    if (!cleanFileName.toLowerCase().endsWith('.pdf')) {
      cleanFileName = '$cleanFileName.pdf';
    }

    // Remove invalid filename characters
    cleanFileName = cleanFileName.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );

    // ------------------------------------------------------------
    // 3. ANDROID
    // ------------------------------------------------------------
    if (Platform.isAndroid) {
      await _savePdfToAndroid(
        sourceFile: sourceFile,
        fileName: cleanFileName,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PDF downloaded to Downloads/PDF Builder',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      return;
    }

    // ------------------------------------------------------------
    // 4. IOS
    // ------------------------------------------------------------
    if (Platform.isIOS) {
      final documentsDir =
      await getApplicationDocumentsDirectory();

      final targetDir = Directory(
        '${documentsDir.path}/PDF Builder',
      );

      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final file = await _getUniqueFile(
        targetDir,
        cleanFileName,
      );

      await sourceFile.copy(file.path);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PDF saved to Files/PDF Builder',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      return;
    }

    // ------------------------------------------------------------
    // 5. Other platforms
    // ------------------------------------------------------------
    final documentsDir =
    await getApplicationDocumentsDirectory();

    final targetDir = Directory(
      '${documentsDir.path}/PDF Builder',
    );

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final file = await _getUniqueFile(
      targetDir,
      cleanFileName,
    );

    await sourceFile.copy(file.path);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF saved successfully.'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e, stackTrace) {
    debugPrint(
      'Error downloading PDF: $e\n$stackTrace',
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failed to download PDF: $e',
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

// ================================================================
// ANDROID - MediaStore
// ================================================================

Future<void> _savePdfToAndroid({
  required File sourceFile,
  required String fileName,
}) async {
  await MediaStore.ensureInitialized();
  MediaStore.appFolder = "PDF Builder";
  final mediaStore = MediaStore();

  final tempDirectory = await getTemporaryDirectory();
  final uniqueFile = await _getUniqueFile(tempDirectory, fileName);
  final finalFileName = uniqueFile.path.split('/').last;

  final tempFile = File('${tempDirectory.path}/$finalFileName');

  await sourceFile.copy(tempFile.path);

  await mediaStore.saveFile(
    tempFilePath: tempFile.path,
    dirType: DirType.download,
    dirName: DirName.download,
  );

  if (await tempFile.exists()) {
    await tempFile.delete();
  }
}

// ================================================================
// UNIQUE FILE FOR IOS / ANDROID / LOCAL STORAGE
// ================================================================

Future<File> _getUniqueFile(
    Directory directory,
    String fileName,
    ) async {
  String filePath = '${directory.path}/$fileName';
  File file = File(filePath);

  if (!await file.exists()) {
    return file;
  }

  final extensionIndex = fileName.lastIndexOf('.');
  final baseName = extensionIndex > 0
      ? fileName.substring(0, extensionIndex)
      : fileName;

  int copyIndex = 1;

  while (await file.exists()) {
    filePath = '${directory.path}/${baseName}_$copyIndex.pdf';
    file = File(filePath);
    copyIndex++;
  }

  return file;
}
