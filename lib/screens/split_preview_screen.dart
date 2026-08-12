import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../services/pdf_service.dart';
import '../utils/file_saver.dart';
import 'success_screen.dart';

class SplitPreviewScreen extends StatefulWidget {
  final PlatformFile file;

  const SplitPreviewScreen({super.key, required this.file});

  @override
  State<SplitPreviewScreen> createState() => _SplitPreviewScreenState();
}

class _SplitPreviewScreenState extends State<SplitPreviewScreen> {
  final TextEditingController _rangeController = TextEditingController();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isProcessing = false;
  int _currentPage = 1;
  int _pageCount = 0;

  List<int> _parsePageRange(String input) {
    // E.g., "1, 3, 5-7" -> [0, 2, 4, 5, 6] (0-indexed)
    final List<int> pages = [];
    final parts = input.split(',');
    
    for (var part in parts) {
      part = part.trim();
      if (part.isEmpty) continue;
      
      if (part.contains('-')) {
        final rangeParts = part.split('-');
        if (rangeParts.length == 2) {
          final start = int.tryParse(rangeParts[0].trim());
          final end = int.tryParse(rangeParts[1].trim());
          if (start != null && end != null && start <= end && start > 0) {
            for (int i = start; i <= end; i++) {
              pages.add(i - 1);
            }
          }
        }
      } else {
        final page = int.tryParse(part);
        if (page != null && page > 0) {
          pages.add(page - 1);
        }
      }
    }
    return pages.toSet().toList(); // Remove duplicates
  }

  Future<void> _splitAndSave() async {
    final pagesToExtract = _parsePageRange(_rangeController.text);
    if (pagesToExtract.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid page range (e.g., 1, 3, 5-7).')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });
    
    // Allow UI to paint the progress indicator before CPU-bound operations
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      dynamic input = kIsWeb ? widget.file.bytes : widget.file.path;
      final Uint8List? resultBytes = await PdfService.splitPdf(input, pagesToExtract);

      if (resultBytes != null) {
        final String? savedPath = await FileSaver.saveFile(resultBytes, 'split_document.pdf');
        
        if (mounted && savedPath != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SuccessScreen(filePath: savedPath),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to split PDF.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Split PDF',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              if (_pdfViewerController.zoomLevel > 1.0) {
                _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel - 0.5;
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel + 0.5;
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _pdfViewerController.previousPage(),
          ),
          if (_pageCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Center(
                child: Text(
                  '$_currentPage / $_pageCount',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _pdfViewerController.nextPage(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: (kIsWeb && widget.file.bytes != null)
                ? SfPdfViewer.memory(
                    widget.file.bytes!,
                    controller: _pdfViewerController,
                    pageLayoutMode: PdfPageLayoutMode.single,
                    onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                      setState(() {
                        _pageCount = details.document.pages.count;
                      });
                    },
                    onPageChanged: (PdfPageChangedDetails details) {
                      setState(() {
                        _currentPage = details.newPageNumber;
                      });
                    },
                  )
                : (widget.file.path != null)
                    ? SfPdfViewer.file(
                        File(widget.file.path!),
                        controller: _pdfViewerController,
                        pageLayoutMode: PdfPageLayoutMode.single,
                        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                          setState(() {
                            _pageCount = details.document.pages.count;
                          });
                        },
                        onPageChanged: (PdfPageChangedDetails details) {
                          setState(() {
                            _currentPage = details.newPageNumber;
                          });
                        },
                      )
                    : const Center(child: Text('Invalid File')),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rangeController,
                    decoration: const InputDecoration(
                      labelText: 'Pages to Extract',
                      hintText: 'e.g. 1, 3, 5-7',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _splitAndSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.call_split),
                  label: Text(_isProcessing ? 'Processing' : 'Split'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
