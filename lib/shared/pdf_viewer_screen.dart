import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/pdf_download_service.dart';

class PdfViewerScreen extends StatefulWidget {
  final String path;
  final String title;

  const PdfViewerScreen({super.key, required this.path, required this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  pdfx.PdfControllerPinch? _pdfController;
  bool _isLoading = true;
  int _pagesCount = 0;
  int _currentPage = 1;
  File? _tempDecryptedFile;

  @override
  void initState() {
    super.initState();
    _initPdf(widget.path);
  }

  Future<void> _initPdf(String filePath) async {
    setState(() => _isLoading = true);
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF file not found locally.'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      final bytes = await file.readAsBytes();
      
      bool isEncrypted = false;
      try {
        final testDoc = PdfDocument(inputBytes: bytes);
        testDoc.dispose();
      } catch (e) {
        isEncrypted = true;
      }

      String validPath = filePath;

      if (isEncrypted) {
        if (!mounted) return;
        final password = await _promptForPassword(context);
        if (password == null || password.isEmpty) {
          setState(() => _isLoading = false);
          return;
        }

        try {
          final decryptedDoc = PdfDocument(inputBytes: bytes, password: password);
          final newDoc = PdfDocument();
          for (int i = 0; i < decryptedDoc.pages.count; i++) {
            newDoc.pages.add().graphics.drawPdfTemplate(
              decryptedDoc.pages[i].createTemplate(),
              const Offset(0, 0),
            );
          }
          decryptedDoc.dispose();

          final decryptedBytes = await newDoc.save();
          newDoc.dispose();

          final tempDir = await getTemporaryDirectory();
          final tempFile = File("${tempDir.path}/clean_${DateTime.now().millisecondsSinceEpoch}.pdf");
          await tempFile.writeAsBytes(decryptedBytes);
          _tempDecryptedFile = tempFile;
          validPath = tempFile.path;
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Incorrect password or unable to decrypt PDF.'), backgroundColor: Colors.red),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      _pdfController?.dispose();
      _pdfController = pdfx.PdfControllerPinch(
        document: pdfx.PdfDocument.openFile(validPath),
      );
      
      final doc = await pdfx.PdfDocument.openFile(validPath);
      if (mounted) {
        setState(() {
          _pagesCount = doc.pagesCount;
          _isLoading = false;
        });
      }
      await doc.close();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening PDF renderer: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String?> _promptForPassword(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    bool obscure = true;

    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Password Protected PDF'),
          content: TextField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: 'Enter PDF Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setDialogState(() => obscure = !obscure),
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    if (_tempDecryptedFile != null && _tempDecryptedFile!.existsSync()) {
      _tempDecryptedFile!.deleteSync();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (!_isLoading && _pagesCount > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '$_currentPage/$_pagesCount',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share PDF',
            onPressed: () async {
              if (await File(widget.path).exists()) {
                await Share.shareXFiles([XFile(widget.path)], text: widget.title);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download PDF',
            onPressed: () => downloadPdf(widget.path, widget.title, context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pagesCount == 0
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock, size: 64, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text('PDF could not be loaded or requires password.'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _initPdf(widget.path),
                        child: const Text('Retry / Enter Password'),
                      ),
                    ],
                  ),
                )
              : pdfx.PdfViewPinch(
                  controller: _pdfController!,
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                ),
    );
  }
}
