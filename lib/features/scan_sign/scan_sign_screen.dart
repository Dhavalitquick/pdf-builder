import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_builder/features/scan_sign/scan_sign_provider.dart';
import 'package:pdf_builder/shared/ad_banner_widget.dart';
import 'package:signature/signature.dart';

class ScanSignScreen extends ConsumerStatefulWidget {
  const ScanSignScreen({super.key});

  @override
  ConsumerState<ScanSignScreen> createState() => _ScanSignScreenState();
}

class _ScanSignScreenState extends ConsumerState<ScanSignScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  bool _isExtracting = false;

  // Custom adjustable signature bounds sizing state
  double _sigWidth = 140.0;
  double _sigHeight = 60.0;
  String _sigPosition = 'Bottom Right';

  // Optional custom date stamping parameters state
  bool _addDate = false;
  final TextEditingController _dateController = TextEditingController(
    text: "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
  );

  @override
  void dispose() {
    _signatureController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _showSourceSelection(BuildContext context, ScanSignNotifier notifier) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Option', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Colors.purple),
                title: const Text('Scan Document (Camera Click)'),
                onTap: () {
                  Navigator.pop(ctx);
                  notifier.startScan();
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined, color: Colors.blue),
                title: const Text('Upload Document (Images or PDFs)'),
                onTap: () {
                  Navigator.pop(ctx);
                  notifier.uploadFromGallery();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _extractAndShowText(String path, ScanSignNotifier notifier) async {
    setState(() => _isExtracting = true);
    final text = await notifier.extractTextFromImage(path);
    setState(() => _isExtracting = false);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Extracted Data'),
        content: SingleChildScrollView(
          child: Text(text),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data copied to clipboard!')),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Copy Data'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSaveOptionsDialog(Uint8List? signature, ScanSignNotifier notifier) async {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Signature & Date Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (signature != null) ...[
                  const Text('Preview Live Signature Placement Area:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 220,
                      height: 120,
                      alignment: Alignment.bottomRight,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Container(
                        width: (_sigWidth / 300) * 120 + 30,
                        height: (_sigHeight / 180) * 60 + 15,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.2),
                          border: Border.all(color: Colors.deepPurple),
                        ),
                        child: const Text('Sign Here', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text('Adjust Signature Size:', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    const Text('Width: '),
                    Expanded(
                      child: Slider(
                        min: 60.0,
                        max: 300.0,
                        value: _sigWidth,
                        onChanged: (val) {
                          setState(() => _sigWidth = val);
                          setDialogState(() => _sigWidth = val);
                        },
                      ),
                    ),
                    Text('${_sigWidth.toInt()} px'),
                  ],
                ),
                Row(
                  children: [
                    const Text('Height: '),
                    Expanded(
                      child: Slider(
                        min: 30.0,
                        max: 180.0,
                        value: _sigHeight,
                        onChanged: (val) {
                          setState(() => _sigHeight = val);
                          setDialogState(() => _sigHeight = val);
                        },
                      ),
                    ),
                    Text('${_sigHeight.toInt()} px'),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Signature Position (Where to place):', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _sigPosition,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: const [
                    DropdownMenuItem(value: 'Bottom Right', child: Text('Bottom Right')),
                    DropdownMenuItem(value: 'Bottom Left', child: Text('Bottom Left')),
                    DropdownMenuItem(value: 'Top Right', child: Text('Top Right')),
                    DropdownMenuItem(value: 'Top Left', child: Text('Top Left')),
                    DropdownMenuItem(value: 'Center', child: Text('Center')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _sigPosition = val);
                      setDialogState(() => _sigPosition = val);
                    }
                  },
                ),
                const Divider(),
                CheckboxListTile(
                  title: const Text('Include Date on Document'),
                  value: _addDate,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _addDate = val);
                      setDialogState(() => _addDate = val);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                if (_addDate) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Custom Date Text',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await notifier.generateAndSharePdf(
                  signature: signature,
                  sigWidth: _sigWidth,
                  sigHeight: _sigHeight,
                  addDate: _addDate,
                  optionalDate: _dateController.text,
                  position: _sigPosition,
                );
                _signatureController.clear();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signed PDF saved successfully in PDFs!'), backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text('Generate PDF'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scannedImages = ref.watch(scanSignProvider);
    final notifier = ref.read(scanSignProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign'),
        actions: [
          if (scannedImages.isNotEmpty)
            IconButton(
              onPressed: () async {
                final signature = await _signatureController.toPngBytes();
                await _showSaveOptionsDialog(signature, notifier);
              },
              icon: const Icon(Icons.check),
            ),
        ],
      ),
      body: _isExtracting
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Extracting text from image...'),
              ],
            ))
          : scannedImages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.document_scanner, size: 64, color: Colors.purple),
                      const SizedBox(height: 16),
                      const Text('No documents scanned or uploaded yet'),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showSourceSelection(context, notifier),
                        icon: const Icon(Icons.add),
                        label: const Text('Scan or Upload Document'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: scannedImages.length,
                        itemBuilder: (context, index) {
                          final file = scannedImages[index];
                          return Card(
                            child: ListTile(
                              onTap: () => _extractAndShowText(file.path, notifier),
                              leading: file.path.toLowerCase().endsWith('.pdf')
                                  ? Image.asset('assets/images/pdf.webp', width: 40, height: 40)
                                  : Image.file(file, width: 50, height: 50, fit: BoxFit.cover),
                              title: Text('Page ${index + 1}'),
                              subtitle: const Text('Tap to extract text data'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.analytics_outlined, color: Colors.purple),
                                    tooltip: 'Extract Data',
                                    onPressed: () => _extractAndShowText(file.path, notifier),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => notifier.removeImage(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Add Signature', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Signature(
                              controller: _signatureController,
                              height: 120,
                              backgroundColor: Colors.grey[100]!,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _signatureController.clear(),
                                child: const Text('Clear Signature'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: scannedImages.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showSourceSelection(context, notifier),
              child: const Icon(Icons.add_a_photo),
            )
          : null,
      bottomNavigationBar: const AdBannerWidget(),
    );
  }
}
