import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pdf_builder/core/subscription_service.dart';
import 'package:pdf_builder/shared/paywall_dialog.dart';
import 'package:pdf_builder/shared/ad_banner_widget.dart';

class ExtractTextScreen extends StatefulWidget {
  const ExtractTextScreen({super.key});

  @override
  State<ExtractTextScreen> createState() => _ExtractTextScreenState();
}

class _ExtractTextScreenState extends State<ExtractTextScreen> {
  File? _imageFile;
  bool _isProcessing = false;
  String _extractedText = '';
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _extractedText = '';
      });
      await _extractText(_imageFile!);
    }
  }

  Future<void> _extractText(File file) async {
    setState(() => _isProcessing = true);
    
    final allowed = await SubscriptionService.instance.checkAndConsumeOcrQuota();
    if (!allowed) {
      if (mounted) {
        showPaywallDialog(
          context,
          message: 'You have used your 1 free OCR text extraction for today. Upgrade to Premium for unlimited OCR!',
        );
      }
      setState(() => _isProcessing = false);
      return;
    }

    try {
      final inputImage = InputImage.fromFilePath(file.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      setState(() {
        _extractedText = recognizedText.text.isNotEmpty
            ? recognizedText.text
            : "No readable text found in this image.";
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _extractedText = "Error extracting text: $e";
        _isProcessing = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_extractedText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _extractedText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text copied to clipboard!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extract Text (OCR)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_imageFile == null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.text_snippet_outlined, size: 64, color: Colors.indigo),
                    const SizedBox(height: 12),
                    const Text(
                      'Select an image to extract copyable text',
                      style: TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade700, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      _imageFile!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Change (Gallery)'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Change (Camera)'),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 24),
            const Text(
              'Extracted Copyable Text:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(minHeight: 180),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _isProcessing
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Recognizing text...'),
                        ],
                      ),
                    )
                  : _extractedText.isEmpty
                      ? Center(
                          child: Text(
                            'No image selected yet.',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        )
                      : SelectableText(
                          _extractedText,
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
            ),
            const SizedBox(height: 20),
            if (_extractedText.isNotEmpty && !_isProcessing)
              ElevatedButton.icon(
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy),
                label: const Text('Copy Extracted Text'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const AdBannerWidget(),
    );
  }
}
