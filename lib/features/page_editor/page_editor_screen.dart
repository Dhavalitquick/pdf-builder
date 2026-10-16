import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_builder/features/page_editor/page_editor_provider.dart';
import 'package:pdf_builder/shared/ad_banner_widget.dart';

class PageEditorScreen extends ConsumerWidget {
  const PageEditorScreen({super.key});

  void _showNameDialog(BuildContext context, PageEditorNotifier notifier) {
    final TextEditingController controller = TextEditingController(
      text: "EditedPDF_${DateTime.now().millisecondsSinceEpoch}",
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Edited PDF'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter file name',
            suffixText: '.pdf',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              Navigator.pop(ctx);
              final error = await notifier.saveEditedPdf(name, context);
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error), backgroundColor: Colors.red),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edited PDF saved successfully in PDFs!'), backgroundColor: Colors.green),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pageEditorProvider);
    final notifier = ref.read(pageEditorProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Page Editor'),
        actions: [
          if (state.sourceFile != null && state.pageIndices.isNotEmpty)
            IconButton(
              onPressed: () => _showNameDialog(context, notifier),
              icon: const Icon(Icons.check),
              tooltip: 'Save PDF',
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.sourceFile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit_document, size: 64, color: Colors.amber),
                      const SizedBox(height: 16),
                      const Text('Select a PDF to reorder or delete pages'),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => notifier.pickPdf(),
                        icon: const Icon(Icons.file_open_outlined),
                        label: const Text('Select PDF to Edit'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'File: ${state.sourceFile!.path.split('/').last}\nReorder pages or tap delete to remove pages.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.pageIndices.length,
                        onReorder: (oldIndex, newIndex) => notifier.reorderPages(oldIndex, newIndex),
                        itemBuilder: (context, index) {
                          final pageNum = state.pageIndices[index] + 1;
                          return Card(
                            key: ValueKey('page_$index'),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.amber.shade100,
                                child: Text('$pageNum', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                              ),
                              title: Text('Page $pageNum (Position ${index + 1})'),
                              subtitle: Text('Original Page: $pageNum'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => notifier.deletePage(index),
                                tooltip: 'Delete Page',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showNameDialog(context, notifier),
                          icon: const Icon(Icons.save),
                          label: const Text('Save Edited PDF'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: Colors.amber.shade800,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: const AdBannerWidget(),
    );
  }
}
