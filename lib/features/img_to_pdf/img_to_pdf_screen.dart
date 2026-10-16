import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_builder/features/img_to_pdf/img_to_pdf_provider.dart';
import 'package:pdf_builder/shared/ad_banner_widget.dart';

class ImgToPdfScreen extends ConsumerWidget {
  const ImgToPdfScreen({super.key});

  void _showImageSourceOptions(BuildContext context, ImgToPdfNotifier notifier) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Image Source',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Colors.blue),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  notifier.pickFromGallery(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Colors.purple),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  notifier.captureFromCamera(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNameDialog(BuildContext context, ImgToPdfNotifier notifier) {
    final TextEditingController controller = TextEditingController(
      text: "PDF_${DateTime.now().millisecondsSinceEpoch}",
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter PDF Name'),
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
              final success = await notifier.generateAndSharePdf(name, context);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF saved successfully! Check it in PDFs.'), backgroundColor: Colors.green),
                );
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
    final images = ref.watch(imgToPdfProvider);
    final notifier = ref.read(imgToPdfProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image to PDF'),
        actions: [
          if (images.isNotEmpty)
            IconButton(
              onPressed: () => _showNameDialog(context, notifier),
              icon: const Icon(Icons.check),
            ),
        ],
      ),
      body: images.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No images selected',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showImageSourceOptions(context, notifier),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Select / Capture Images'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return Card(
                        key: ValueKey(images[index].path),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.file(
                              images[index],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text('Image ${index + 1}'),
                          subtitle: Text(images[index].path.split('/').last),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => notifier.removeImage(index),
                          ),
                        ),
                      );
                    },
                    onReorder: (oldIndex, newIndex) =>
                        notifier.reorder(oldIndex, newIndex),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showNameDialog(context, notifier),
                      icon: const Icon(Icons.save_alt_outlined),
                      label: const Text('Save PDF'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: images.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showImageSourceOptions(context, notifier),
              child: const Icon(Icons.add_a_photo_outlined),
            )
          : null,
      bottomNavigationBar: const AdBannerWidget(),
    );
  }
}
