import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_builder/main.dart';
import 'package:pdf_builder/features/extract_text/extract_text_screen.dart';
import 'package:pdf_builder/features/img_to_pdf/img_to_pdf_screen.dart';
import 'package:pdf_builder/features/merge_split/merge_split_screen.dart';
import 'package:pdf_builder/features/page_editor/page_editor_screen.dart';
import 'package:pdf_builder/features/pdf_to_img/pdf_to_img_screen.dart';
import 'package:pdf_builder/features/scan_sign/scan_sign_screen.dart';
import 'package:pdf_builder/shared/feature_card.dart';
import 'package:pdf_builder/shared/ad_banner_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'PDF Builder Pro',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle Theme',
            onPressed: () {
              ref.read(themeModeProvider.notifier).state =
                  themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.deepPurple.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All-in-One PDF Tool',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Convert, Merge, Split and Sign documents instantly.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.auto_awesome, color: Colors.amber, size: 40),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 32),
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
              children: [
                FeatureCard(
                  title: 'Image to PDF',
                  description: 'Capture & Convert',
                  icon: Icons.image_outlined,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ImgToPdfScreen()),
                    );
                  },
                ).animate().scale(delay: 100.ms),
                FeatureCard(
                  title: 'PDF to Image',
                  description: 'Extract Pages',
                  icon: Icons.picture_as_pdf_outlined,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PdfToImgScreen()),
                    );
                  },
                ).animate().scale(delay: 200.ms),
                FeatureCard(
                  title: 'Merge PDF',
                  description: 'Combine Files',
                  icon: Icons.merge_type,
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MergeSplitScreen()),
                    );
                  },
                ).animate().scale(delay: 300.ms),
                FeatureCard(
                  title: 'Split PDF',
                  description: 'Separate Pages',
                  icon: Icons.call_split,
                  color: Colors.red,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MergeSplitScreen()),
                    );
                  },
                ).animate().scale(delay: 400.ms),
                FeatureCard(
                  title: 'Sign',
                  description: 'Sign Documents',
                  icon: Icons.document_scanner_outlined,
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ScanSignScreen()),
                    );
                  },
                ).animate().scale(delay: 500.ms),
                FeatureCard(
                  title: 'Extract Text',
                  description: 'Image to Copyable Text',
                  icon: Icons.text_snippet_outlined,
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ExtractTextScreen()),
                    );
                  },
                ).animate().scale(delay: 600.ms),
                FeatureCard(
                  title: 'Page Editor',
                  description: 'Reorder & Delete Pages',
                  icon: Icons.edit_document,
                  color: Colors.amber.shade800,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PageEditorScreen()),
                    );
                  },
                ).animate().scale(delay: 700.ms),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdBannerWidget(),
    );
  }
}
