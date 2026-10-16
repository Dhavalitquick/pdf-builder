import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdf_builder/core/pdf_storage_service.dart';
import 'package:pdf_builder/core/subscription_service.dart';
import 'package:pdf_builder/shared/paywall_dialog.dart';

final pageEditorProvider = StateNotifierProvider<PageEditorNotifier, PageEditorState>((ref) {
  return PageEditorNotifier();
});

class PageEditorState {
  final File? sourceFile;
  final List<int> pageIndices;
  final bool isLoading;

  PageEditorState({
    this.sourceFile,
    this.pageIndices = const [],
    this.isLoading = false,
  });

  PageEditorState copyWith({
    File? sourceFile,
    List<int>? pageIndices,
    bool? isLoading,
  }) {
    return PageEditorState(
      sourceFile: sourceFile ?? this.sourceFile,
      pageIndices: pageIndices ?? this.pageIndices,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PageEditorNotifier extends StateNotifier<PageEditorState> {
  PageEditorNotifier() : super(PageEditorState());

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      state = state.copyWith(isLoading: true);
      final file = File(result.files.single.path!);
      try {
        final bytes = await file.readAsBytes();
        final doc = PdfDocument(inputBytes: bytes);
        final count = doc.pages.count;
        doc.dispose();

        final indices = List.generate(count, (index) => index);
        state = PageEditorState(
          sourceFile: file,
          pageIndices: indices,
          isLoading: false,
        );
      } catch (e) {
        state = PageEditorState(isLoading: false);
      }
    }
  }

  void deletePage(int index) {
    final list = List<int>.from(state.pageIndices);
    list.removeAt(index);
    if (list.isEmpty) {
      state = PageEditorState();
    } else {
      state = state.copyWith(pageIndices: list);
    }
  }

  void reorderPages(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final list = List<int>.from(state.pageIndices);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = state.copyWith(pageIndices: list);
  }

  Future<String?> saveEditedPdf(String customName, BuildContext context) async {
    if (state.sourceFile == null || state.pageIndices.isEmpty) return "No PDF loaded.";

    final allowed = await SubscriptionService.instance.checkAndConsumeConversionQuota();
    if (!allowed) {
      if (context.mounted) {
        showPaywallDialog(context, message: 'You have reached your 3 free PDF conversions for today. Upgrade to Premium for unlimited conversions!');
      }
      return "Daily free conversion limit reached.";
    }

    try {
      final bytes = await state.sourceFile!.readAsBytes();
      final sourceDoc = PdfDocument(inputBytes: bytes);
      final newDoc = PdfDocument();

      for (var pageIdx in state.pageIndices) {
        newDoc.pages.add().graphics.drawPdfTemplate(
          sourceDoc.pages[pageIdx].createTemplate(),
          const Offset(0, 0),
        );
      }
      sourceDoc.dispose();

      final savedBytes = await newDoc.save();
      newDoc.dispose();

      final fileName = customName.trim().isNotEmpty ? customName.trim() : "Edited_${DateTime.now().millisecondsSinceEpoch}";
      await PdfStorageService.savePdfFile(savedBytes, fileName);

      state = PageEditorState();
      return null;
    } catch (e) {
      return "Error saving edited PDF: $e";
    }
  }

  void clear() {
    state = PageEditorState();
  }
}
