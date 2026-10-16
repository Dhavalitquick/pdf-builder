import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdf_builder/core/pdf_storage_service.dart';
import 'package:pdf_builder/core/subscription_service.dart';
import 'package:pdf_builder/shared/paywall_dialog.dart';

final mergeSplitProvider = StateNotifierProvider<MergeSplitNotifier, List<File>>((ref) {
  return MergeSplitNotifier();
});

class MergeSplitNotifier extends StateNotifier<List<File>> {
  MergeSplitNotifier() : super([]);

  Future<void> pickPdfs() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result != null) {
      state = [...state, ...result.files.where((f) => f.path != null).map((f) => File(f.path!))];
    }
  }

  void removePdf(int index) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i != index) state[i]
    ];
  }

  Future<String?> mergeAndShare(BuildContext context) async {
    if (state.length < 2) return "Select at least 2 PDFs to merge.";

    final allowed = await SubscriptionService.instance.checkAndConsumeConversionQuota();
    if (!allowed) {
      if (context.mounted) {
        showPaywallDialog(context, message: 'You have reached your 3 free PDF conversions for today. Upgrade to Premium for unlimited conversions!');
      }
      return "Daily free conversion limit reached.";
    }

    try {
      final PdfDocument finalDoc = PdfDocument();

      for (var file in state) {
        final List<int> bytes = await file.readAsBytes();
        final PdfDocument sourceDoc = PdfDocument(inputBytes: bytes);
        
        for (int i = 0; i < sourceDoc.pages.count; i++) {
          finalDoc.pages.add().graphics.drawPdfTemplate(
            sourceDoc.pages[i].createTemplate(),
            const Offset(0, 0),
          );
        }
        sourceDoc.dispose();
      }

      final List<int> bytes = await finalDoc.save();
      finalDoc.dispose();

      await PdfStorageService.savePdfFile(bytes, "merged_${DateTime.now().millisecondsSinceEpoch}");

      state = [];
      return null;
    } catch (e) {
      if (e.toString().contains("encrypted") || e.toString().contains("password")) {
        return "One of the selected PDFs is encrypted or password-protected and cannot be opened.";
      }
      return "Error merging PDFs: $e";
    }
  }

  Future<String?> splitAndShare(File file, BuildContext context) async {
    final allowed = await SubscriptionService.instance.checkAndConsumeConversionQuota();
    if (!allowed) {
      if (context.mounted) {
        showPaywallDialog(context, message: 'You have reached your 3 free PDF conversions for today. Upgrade to Premium for unlimited conversions!');
      }
      return "Daily free conversion limit reached.";
    }

    try {
      final List<int> bytes = await file.readAsBytes();
      final PdfDocument sourceDoc = PdfDocument(inputBytes: bytes);
      
      for (int i = 0; i < sourceDoc.pages.count; i++) {
        final PdfDocument splitDoc = PdfDocument();
        splitDoc.pages.add().graphics.drawPdfTemplate(
          sourceDoc.pages[i].createTemplate(),
          const Offset(0, 0),
        );
        
        final List<int> splitBytes = await splitDoc.save();
        await PdfStorageService.savePdfFile(splitBytes, "page_${i + 1}_${DateTime.now().millisecondsSinceEpoch}");
        splitDoc.dispose();
      }
      sourceDoc.dispose();

      state = [];
      return null;
    } catch (e) {
      if (e.toString().contains("encrypted") || e.toString().contains("password")) {
        return "This PDF is encrypted or password-protected and cannot be opened.";
      }
      return "Error splitting PDF: $e";
    }
  }

  void clear() {
    state = [];
  }
}
