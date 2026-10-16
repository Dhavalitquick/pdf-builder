import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_builder/features/pdf_to_img/pdf_to_img_provider.dart';
import 'package:pdf_builder/shared/ad_banner_widget.dart';

class PdfToImgScreen extends ConsumerWidget {
  const PdfToImgScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfFile = ref.watch(pdfToImgProvider);
    final notifier = ref.read(pdfToImgProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF to Image'),
        actions: [
          if (pdfFile != null)
            IconButton(
              onPressed: () => notifier.clear(),
              icon: const Icon(Icons.clear),
            ),
        ],
      ),
      body: pdfFile == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/pdf.webp', width: 64, height: 64),
                  const SizedBox(height: 16),
                  Text(
                    'No PDF selected',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => notifier.pickPdf(),
                    icon: const Icon(Icons.file_open_outlined),
                    label: const Text('Select PDF'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    child: ListTile(
                      leading: Image.asset('assets/images/pdf.webp', width: 36, height: 36),
                      title: Text(pdfFile.path.split('/').last),
                      subtitle: const Text('PDF Document'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Extract all pages as high-quality images',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => notifier.convertAllAndShare(context),
                      icon: const Icon(Icons.image_search),
                      label: const Text('Convert All Pages'),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: const AdBannerWidget(),
    );
  }
}
