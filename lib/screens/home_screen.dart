import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';

import '../services/pdf_service.dart';
import '../widgets/ad_banner.dart';
import 'success_screen.dart';
import 'pdf_viewer_screen.dart';
import 'merge_preview_screen.dart';
import 'split_preview_screen.dart';
import 'image_to_pdf_screen.dart';
import 'pdf_to_image_screen.dart';
import 'privacy_policy_screen.dart';
import '../utils/file_saver.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _handleToolAction(BuildContext context, String title) async {
    String? resultPath;

    try {
      if (title == 'Merge PDFs') {
        FilePickerResult? result = await FilePicker.pickFiles(
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          withData: kIsWeb,
        );
        if (result != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MergePreviewScreen(files: result.files),
            ),
          );
        }
      } else if (title == 'Split PDF') {
        FilePickerResult? result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          withData: kIsWeb,
        );
        if (result != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SplitPreviewScreen(file: result.files.single),
            ),
          );
        }
      } else if (title == 'Compress PDF') {
        FilePickerResult? result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          withData: kIsWeb,
        );
        if (result != null) {
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(color: Color(0xFFD32F2F), strokeWidth: 3),
                ),
              ),
            );
            // Allow UI to paint the dialog before blocking the thread
            await Future.delayed(const Duration(milliseconds: 100));
          }
          
          dynamic input = kIsWeb ? result.files.single.bytes : result.files.single.path;
          final bytes = await PdfService.compressPdf(input);
          
          if (context.mounted) {
            Navigator.pop(context); // Close the dialog
          }
          
          if (bytes != null) {
            resultPath = await FileSaver.saveFile(bytes, 'compressed_document.pdf');
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to compress PDF.')),
            );
          }
        }
      } else if (title == 'Image to PDF') {
        FilePickerResult? result = await FilePicker.pickFiles(
          allowMultiple: true,
          type: FileType.image,
          withData: kIsWeb,
        );
        if (result != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ImageToPdfScreen(images: result.files),
            ),
          );
        }
      } else if (title == 'PDF to Image') {
        FilePickerResult? result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          withData: kIsWeb,
        );
        if (result != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PdfToImageScreen(file: result.files.single),
            ),
          );
        }
      } else if (title == 'Office Viewer') {
        FilePickerResult? result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['docx', 'xlsx', 'pptx'],
        );
        if (result != null && result.files.single.path != null) {
          await OpenFilex.open(result.files.single.path!);
        } else if (kIsWeb && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Office Viewer requires a native app on mobile.'),
            ),
          );
        }
        return;
      } else if (title == 'View PDF') {
        FilePickerResult? result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          withData: kIsWeb,
        );
        if (result != null) {
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PdfViewerScreen(
                  filePath: kIsWeb ? null : result.files.single.path,
                  fileBytes: kIsWeb ? result.files.single.bytes : null,
                ),
              ),
            );
          }
        }
        return;
      }

      if (resultPath != null || (kIsWeb && resultPath == 'Web download triggered')) {
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SuccessScreen(filePath: resultPath ?? 'Web Download'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tools = [
      {
        'title': 'View PDF',
        'subtitle': 'Open and read PDF files',
        'icon': Icons.picture_as_pdf,
        'badge': 'New',
      },
      {
        'title': 'Merge PDFs',
        'subtitle': 'Combine multiple files into one',
        'icon': Icons.call_merge_rounded,
        'badge': 'Popular',
      },
      {
        'title': 'Split PDF',
        'subtitle': 'Extract specific pages easily',
        'icon': Icons.call_split_rounded,
        'badge': null,
      },
      {
        'title': 'Compress PDF',
        'subtitle': 'Shrink file size for sharing',
        'icon': Icons.compress_rounded,
        'badge': 'Fast',
      },
      {
        'title': 'Image to PDF',
        'subtitle': 'Convert photos to document',
        'icon': Icons.image_outlined,
        'badge': null,
      },
      {
        'title': 'PDF to Image',
        'subtitle': 'Extract pages as JPEG/PNG',
        'icon': Icons.picture_as_pdf_outlined,
        'badge': null,
      },
      {
        'title': 'Office Viewer',
        'subtitle': 'Open Word, Excel & PPT',
        'icon': Icons.description_outlined,
        'badge': 'Free',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Professional Off-White
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 48,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 26),
                );
              },
            ),
            const SizedBox(width: 12),
            const Text(
              'Offline PDF Studio',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF757575)),
            tooltip: 'Privacy Policy',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800), // Desktop & Web Constraint
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      // Privacy Trust Banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: Color(0xFF2E7D32), size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '100% Offline & Private. Your files never leave this device.',
                                style: TextStyle(
                                  color: Color(0xFF1B5E20),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Responsive Tool Grid
                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = constraints.maxWidth > 550 ? 3 : 2;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: constraints.maxWidth > 550 ? 1.1 : 0.95,
                            ),
                            itemCount: tools.length,
                            itemBuilder: (context, index) {
                              final tool = tools[index];
                              return _ToolCard(
                                title: tool['title'] as String,
                                subtitle: tool['subtitle'] as String,
                                icon: tool['icon'] as IconData,
                                badge: tool['badge'] as String?,
                                onTap: () => _handleToolAction(context, tool['title'] as String),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? badge;
  final VoidCallback onTap;

  const _ToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: const Color(0xFFD32F2F).withValues(alpha: 0.04),
        splashColor: const Color(0xFFD32F2F).withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 26, color: const Color(0xFFD32F2F)),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF757575),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}