import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_builder/features/merge_split/merge_split_provider.dart';
import 'package:pdf_builder/shared/ad_banner_widget.dart';

class MergeSplitScreen extends ConsumerWidget {
  const MergeSplitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfs = ref.watch(mergeSplitProvider);
    final notifier = ref.read(mergeSplitProvider.notifier);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Merge & Split'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Merge'),
              Tab(text: 'Split'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Merge Tab
            Column(
              children: [
                Expanded(
                  child: pdfs.isEmpty
                      ? const Center(child: Text('Add PDFs to merge'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: pdfs.length,
                          itemBuilder: (context, index) {
                            return Card(
                              child: ListTile(
                                leading: Image.asset('assets/images/pdf.webp', width: 36, height: 36),
                                title: Text(pdfs[index].path.split('/').last),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => notifier.removePdf(index),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => notifier.pickPdfs(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add PDF'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: pdfs.length < 2
                              ? null
                              : () async {
                                  final error = await notifier.mergeAndShare(context);
                                  if (error != null && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(error), backgroundColor: Colors.red),
                                    );
                                  } else if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Merged PDF saved successfully inside PDFs!'), backgroundColor: Colors.green),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.merge_type),
                          label: const Text('Save & Merge'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Split Tab
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.call_split, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Select a PDF to split it into multiple single-page documents',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await ref.read(mergeSplitProvider.notifier).pickPdfs();
                      },
                      icon: const Icon(Icons.file_open),
                      label: const Text('Pick PDF to Split'),
                    ),
                    if (pdfs.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Selected: ${pdfs.last.path.split('/').last}'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final error = await notifier.splitAndShare(pdfs.last, context);
                          if (error != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error), backgroundColor: Colors.red),
                            );
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Split pages saved successfully inside PDFs!'), backgroundColor: Colors.green),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        child: const Text('Confirm & Save Split'),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const AdBannerWidget(),
      ),
    );
  }
}
