import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../services/pdf_service.dart';
import '../utils/file_saver.dart';
import 'success_screen.dart';

class PdfToImageScreen extends StatefulWidget {
  final PlatformFile file;

  const PdfToImageScreen({super.key, required this.file});

  @override
  State<PdfToImageScreen> createState() => _PdfToImageScreenState();
}

class _PdfToImageScreenState extends State<PdfToImageScreen> {
  final TextEditingController _pageController = TextEditingController(text: '1');
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _convertAll = false;
  bool _isProcessing = false;
  int _currentPage = 1;
  int _pageCount = 0;

  Future<void> _convertAndSave() async {
    if (!_convertAll) {
      final int? pageNumber = int.tryParse(_pageController.text.trim());
      
      if (pageNumber == null || pageNumber < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid positive page number.')),
        );
        return;
      }
    }

    setState(() {
      _isProcessing = true;
    });
    
    // Allow UI to paint the progress indicator before CPU-bound operations
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      dynamic input = kIsWeb ? widget.file.bytes : widget.file.path;
      
      if (_convertAll) {
        final List<Uint8List>? resultBytesList = await PdfService.renderAllPdfPagesToImages(input);
        
        if (resultBytesList != null && resultBytesList.isNotEmpty) {
          List<String> fileNames = List.generate(resultBytesList.length, (i) => 'page_${i+1}.png');
          final String? savedPath = await FileSaver.saveMultipleFiles(resultBytesList, fileNames, 'pdf_images.zip');
          
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
              const SnackBar(content: Text('Failed to extract images.')),
            );
          }
        }
      } else {
        final int pageNumber = int.parse(_pageController.text.trim());
        final Uint8List? resultBytes = await PdfService.renderPdfPageToImage(input, pageNumber);

        if (resultBytes != null) {
          final String? savedPath = await FileSaver.saveFile(resultBytes, 'page_$pageNumber.png');
          
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
              const SnackBar(content: Text('Failed to extract page as image.')),
            );
          }
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
          'Export PDF to Image',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _pageController,
                        keyboardType: TextInputType.number,
                        enabled: !_convertAll,
                        decoration: const InputDecoration(
                          labelText: 'Page Number',
                          hintText: 'e.g. 1',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _convertAndSave,
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
                          : const Icon(Icons.image),
                      label: Text(_isProcessing ? 'Processing' : (_convertAll ? 'Export All' : 'Export PNG')),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    setState(() => _convertAll = !_convertAll);
                  },
                  child: Row(
                    children: [
                      Checkbox(
                        value: _convertAll,
                        onChanged: (val) => setState(() => _convertAll = val ?? false),
                      ),
                      const Text('Convert entire PDF to images'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
