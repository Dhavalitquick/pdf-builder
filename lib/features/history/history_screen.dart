import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdf_builder/features/history/history_provider.dart';
import 'package:pdf_builder/shared/database/history_database.dart';
import 'package:pdf_builder/shared/pdf_viewer_screen.dart';
import 'package:pdf_builder/core/subscription_service.dart';
import 'package:pdf_builder/shared/paywall_dialog.dart';
import 'package:pdf_builder/shared/ad_banner_widget.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(historyProvider.notifier).loadHistory();
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.read(historyProvider.notifier).loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final notifier = ref.read(historyProvider.notifier);

    final filteredHistory = history.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item.title.toLowerCase().contains(_searchQuery) ||
             item.path.split('/').last.toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('PDFs'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search PDFs by exact name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: filteredHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/pdf.webp', width: 64, height: 64),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No saved PDFs found' : 'No matching PDFs found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      final item = filteredHistory[index];
                      return PdfCustomCard(
                        item: item,
                        onTap: () async {
                          File file = File(item.path);
                          if (!await file.exists()) {
                            try {
                              final docDir = await getApplicationDocumentsDirectory();
                              final fileName = item.path.split('/').last;
                              final fallbackFile = File('${docDir.path}/PDF Storage/$fileName');
                              if (await fallbackFile.exists()) {
                                file = fallbackFile;
                              } else {
                                final altFile = File('${docDir.path}/$fileName');
                                if (await altFile.exists()) {
                                  file = altFile;
                                }
                              }
                            } catch (_) {}
                          }

                          final fileExists = await file.exists();
                          if (!context.mounted) return;
                          if (fileExists) {
                            if (file.path.endsWith('.pdf')) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PdfViewerScreen(
                                    path: file.path,
                                    title: item.title,
                                  ),
                                ),
                              );
                            } else {
                              // Open image or other files
                              if (!context.mounted) return;
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(item.title),
                                  content: Image.file(file),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('File no longer exists locally.'),
                              ),
                            );
                          }
                        },
                        onDelete: () {
                          if (item.id != null) {
                            notifier.deleteItem(item.id!);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const AdBannerWidget(),
    );
  }
}

class PdfCustomCard extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const PdfCustomCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  Future<void> _protectPdf(BuildContext context) async {
    if (!SubscriptionService.instance.isPremium) {
      showPaywallDialog(context, message: 'Password Protection is available exclusively for Premium subscribers!');
      return;
    }

    final TextEditingController controller = TextEditingController();
    bool obscure = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Protect "${item.title}" with Password'),
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
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final password = controller.text.trim();
                if (password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password cannot be empty.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  File file = File(item.path);
                  if (!await file.exists()) {
                    final docDir = await getApplicationDocumentsDirectory();
                    final fileName = item.path.split('/').last;
                    final fallbackFile = File('${docDir.path}/PDF Storage/$fileName');
                    if (await fallbackFile.exists()) {
                      file = fallbackFile;
                    }
                  }

                  if (!await file.exists()) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('File no longer exists locally.'),
                      ),
                    );
                    return;
                  }

                  final bytes = await file.readAsBytes();
                  final doc = PdfDocument(inputBytes: bytes);
                  doc.security.userPassword = password;
                  doc.security.ownerPassword = password;

                  final encryptedBytes = await doc.save();
                  doc.dispose();

                  await file.writeAsBytes(encryptedBytes);

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PDF password protected successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error protecting PDF: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Encrypt & Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 10, left: 10),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: item.type.toLowerCase().contains('pdf') ? Image.asset(
                    'assets/images/pdf.webp',
                    fit: BoxFit.contain,
                  ) : const Icon(Icons.image_outlined, size: 48),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.path.split('/').last,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.createdAt.split('T').first,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.path.endsWith('.pdf'))
                      CustomIconButton(
                        icon: Icons.lock_outline,
                        onPressed: () => _protectPdf(context),
                        tooltip: 'Protect with Password',
                      ),
                    CustomIconButton(
                      icon: Icons.delete_outline,
                      onPressed: onDelete,
                      tooltip: 'Delete PDF',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.iconColor = Colors.orange,
    this.backgroundColor = const Color(0xFFFFF3E0),
    this.tooltip = '',
    this.size = 44,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWithSplash(
          onPressed: onPressed,
          size: size,
          icon: icon,
          iconColor: iconColor,
          iconSize: iconSize,
        ),
      ),
    );
  }
}

class InkWithSplash extends StatelessWidget {
  final VoidCallback onPressed;
  final double size;
  final IconData icon;
  final Color iconColor;
  final double iconSize;

  const InkWithSplash({
    super.key,
    required this.onPressed,
    required this.size,
    required this.icon,
    required this.iconColor,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Icon(icon, color: iconColor, size: iconSize),
          ),
        ),
      ),
    );
  }
}
