import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf_builder/core/history_service.dart';
import 'package:pdf_builder/core/subscription_service.dart';
import 'package:pdf_builder/shared/paywall_dialog.dart';

final pdfToImgProvider = StateNotifierProvider<PdfToImgNotifier, File?>((ref) {
  return PdfToImgNotifier();
});

class PdfToImgNotifier extends StateNotifier<File?> {
  PdfToImgNotifier() : super(null);

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      state = File(result.files.single.path!);
    }
  }

  Future<bool> convertAndShare(int pageNumber, BuildContext context) async {
    if (state == null) return false;

    final allowed = await SubscriptionService.instance.checkAndConsumeConversionQuota();
    if (!allowed) {
      if (context.mounted) {
        showPaywallDialog(context, message: 'You have reached your 3 free PDF conversions for today. Upgrade to Premium for unlimited conversions!');
      }
      return false;
    }

    final document = await PdfDocument.openFile(state!.path);
    final page = await document.getPage(pageNumber);
    final pageImage = await page.render(
      width: page.width * 2,
      height: page.height * 2,
      format: PdfPageImageFormat.png,
    );

    if (pageImage != null) {
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/IMG_PAGE_$pageNumber\_${DateTime.now().millisecondsSinceEpoch}.png");
      await file.writeAsBytes(pageImage.bytes);

      // Save image to history storage
      await HistoryService.addHistory(file.path);

      await Share.shareXFiles([XFile(file.path)], text: 'Extracted Page $pageNumber');
    }

    await page.close();
    await document.close();
    return true;
  }

  Future<bool> convertAllAndShare(BuildContext context) async {
    if (state == null) return false;

    final allowed = await SubscriptionService.instance.checkAndConsumeConversionQuota();
    if (!allowed) {
      if (context.mounted) {
        showPaywallDialog(context, message: 'You have reached your 3 free PDF conversions for today. Upgrade to Premium for unlimited conversions!');
      }
      return false;
    }

    final document = await PdfDocument.openFile(state!.path);
    final List<XFile> xFiles = [];
    final output = await getTemporaryDirectory();

    for (int i = 1; i <= document.pagesCount; i++) {
      final page = await document.getPage(i);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );
      if (pageImage != null) {
        final file = File("${output.path}/IMG_ALL_PAGE_$i\_${DateTime.now().millisecondsSinceEpoch}.png");
        await file.writeAsBytes(pageImage.bytes);
        xFiles.add(XFile(file.path));

        // Save each image path into local database history
        await HistoryService.addHistory(file.path);
      }
      await page.close();
    }
    await document.close();

    if (xFiles.isNotEmpty) {
      await Share.shareXFiles(xFiles, text: 'All pages extracted from PDF');
    }
    return true;
  }

  void clear() {
    state = null;
  }
}
