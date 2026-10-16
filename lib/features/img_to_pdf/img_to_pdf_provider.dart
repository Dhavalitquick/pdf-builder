import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdf_builder/core/pdf_storage_service.dart';
import 'package:pdf_builder/core/subscription_service.dart';
import 'package:pdf_builder/shared/paywall_dialog.dart';

final imgToPdfProvider = StateNotifierProvider<ImgToPdfNotifier, List<File>>((ref) {
  return ImgToPdfNotifier();
});

class ImgToPdfNotifier extends StateNotifier<List<File>> {
  ImgToPdfNotifier() : super([]);

  final ImagePicker _picker = ImagePicker();

  Future<void> pickFromGallery(BuildContext context) async {
    final List<XFile> images = await _picker.pickMultiImage();
    for (var image in images) {
      final cropped = await _cropImage(image.path, context);
      if (cropped != null) {
        state = [...state, File(cropped)];
      }
    }
  }

  Future<void> captureFromCamera(BuildContext context) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final cropped = await _cropImage(image.path, context);
      if (cropped != null) {
        state = [...state, File(cropped)];
      }
    }
  }

  Future<String?> _cropImage(String path, BuildContext context) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Document / Image',
          toolbarColor: Colors.deepPurple,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        IOSUiSettings(
          title: 'Crop Document / Image',
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
      ],
    );
    return croppedFile?.path;
  }

  void removeImage(int index) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i != index) state[i]
    ];
  }

  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final List<File> items = List.from(state);
    final File item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = items;
  }

  Future<bool> generateAndSharePdf(String customName, BuildContext context) async {
    if (state.isEmpty) return false;

    final allowed = await SubscriptionService.instance.checkAndConsumeConversionQuota();
    if (!allowed) {
      if (context.mounted) {
        showPaywallDialog(context, message: 'You have reached your 3 free PDF conversions for today. Upgrade to Premium for unlimited conversions!');
      }
      return false;
    }

    final pdf = PdfDocument();

    for (var file in state) {
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
    }

    final List<int> bytes = await pdf.save();
    pdf.dispose();

    final fileName = customName.trim().isNotEmpty ? customName.trim() : "PDF_${DateTime.now().millisecondsSinceEpoch}";
    await PdfStorageService.savePdfFile(bytes, fileName);

    // Clear current images state so user returns to empty screen after saving
    state = [];
    return true;
  }
}
