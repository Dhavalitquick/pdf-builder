import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdf_builder/core/pdf_storage_service.dart';

final scanSignProvider = StateNotifierProvider<ScanSignNotifier, List<File>>((ref) {
  return ScanSignNotifier();
});

class ScanSignNotifier extends StateNotifier<List<File>> {
  ScanSignNotifier() : super([]);

  Future<void> startScan() async {
    try {
      final scanner = DocumentScanner(
        options: DocumentScannerOptions(
          mode: ScannerMode.full,
          pageLimit: 10,
          isGalleryImport: true,
        ),
      );

      final result = await scanner.scanDocument();
      final images = result.images;
      if (images != null && images.isNotEmpty) {
        state = [...state, ...images.map((path) => File(path))];
      }
    } catch (e) {
      debugPrint("Scan error: $e");
    }
  }

  Future<void> uploadFromGallery() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final files = result.files.where((f) => f.path != null).map((f) => File(f.path!)).toList();
      state = [...state, ...files];
    }
  }

  Future<String> extractTextFromImage(String filePath) async {
    try {
      if (filePath.toLowerCase().endsWith('.pdf')) {
        return "OCR text extraction is currently supported for image files (JPG/PNG).";
      }
      final inputImage = InputImage.fromFilePath(filePath);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();
      return recognizedText.text.isNotEmpty ? recognizedText.text : "No readable text found in this image.";
    } catch (e) {
      return "Error extracting text: $e";
    }
  }

  Future<void> generateAndSharePdf({
    required Uint8List? signature,
    required double sigWidth,
    required double sigHeight,
    required bool addDate,
    required String? optionalDate,
    required String position,
  }) async {
    if (state.isEmpty) return;

    final pdf = PdfDocument();

    for (var file in state) {
      final path = file.path.toLowerCase();
      if (path.endsWith('.pdf')) {
        try {
          final List<int> bytes = await file.readAsBytes();
          final PdfDocument sourceDoc = PdfDocument(inputBytes: bytes);
          for (int i = 0; i < sourceDoc.pages.count; i++) {
            final page = pdf.pages.add();
            page.graphics.drawPdfTemplate(
              sourceDoc.pages[i].createTemplate(),
              const Offset(0, 0),
            );
            _drawSignatureAndDate(page, signature, sigWidth, sigHeight, addDate, optionalDate, position);
          }
          sourceDoc.dispose();
        } catch (e) {
          debugPrint("Error processing PDF in Sign: $e");
        }
      } else {
        final page = pdf.pages.add();
        final bitmap = PdfBitmap(file.readAsBytesSync());
        final pageSize = page.getClientSize();

        double imageWidth = bitmap.width.toDouble();
        double imageHeight = bitmap.height.toDouble();
        double scaleX = pageSize.width / imageWidth;
        double scaleY = pageSize.height / imageHeight;
        double scale = scaleX < scaleY ? scaleX : scaleY;

        double finalWidth = imageWidth * scale;
        double finalHeight = imageHeight * scale;
        double offsetX = (pageSize.width - finalWidth) / 2;
        double offsetY = (pageSize.height - finalHeight) / 2;

        page.graphics.drawImage(
          bitmap,
          Rect.fromLTWH(offsetX, offsetY, finalWidth, finalHeight),
        );

        _drawSignatureAndDate(page, signature, sigWidth, sigHeight, addDate, optionalDate, position);
      }
    }

    final List<int> bytes = await pdf.save();
    pdf.dispose();

    await PdfStorageService.savePdfFile(bytes, "SIGN_${DateTime.now().millisecondsSinceEpoch}");

    // Clear state after save
    state = [];
  }

  void _drawSignatureAndDate(
    PdfPage page,
    Uint8List? signature,
    double sigWidth,
    double sigHeight,
    bool addDate,
    String? optionalDate,
    String position,
  ) {
    final pageSize = page.getClientSize();
    double sigX;
    double sigY;

    switch (position) {
      case 'Bottom Left':
        sigX = 30;
        sigY = pageSize.height - sigHeight - 40;
        break;
      case 'Top Right':
        sigX = pageSize.width - sigWidth - 30;
        sigY = 40;
        break;
      case 'Top Left':
        sigX = 30;
        sigY = 40;
        break;
      case 'Center':
        sigX = (pageSize.width - sigWidth) / 2;
        sigY = (pageSize.height - sigHeight) / 2;
        break;
      case 'Bottom Right':
      default:
        sigX = pageSize.width - sigWidth - 30;
        sigY = pageSize.height - sigHeight - 40;
        break;
    }

    if (signature != null) {
      final sigBitmap = PdfBitmap(signature);
      page.graphics.drawImage(
        sigBitmap,
        Rect.fromLTWH(sigX, sigY, sigWidth, sigHeight),
      );
    }

    if (addDate && optionalDate != null && optionalDate.isNotEmpty) {
      final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 11);
      page.graphics.drawString(
        "Date: $optionalDate",
        font,
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
        bounds: Rect.fromLTWH(sigX, pageSize.height - 30, sigWidth + 20, 20),
      );
    }
  }

  void removeImage(int index) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i != index) state[i]
    ];
  }

  void clear() {
    state = [];
  }
}
