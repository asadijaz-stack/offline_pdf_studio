import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../widgets/ad_banner.dart';

class PdfViewerScreen extends StatefulWidget {
  final String? filePath;
  final Uint8List? fileBytes;

  const PdfViewerScreen({super.key, this.filePath, this.fileBytes});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  int _currentPage = 1;
  int _pageCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'PDF Viewer',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
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
            child: (kIsWeb && widget.fileBytes != null)
                ? SfPdfViewer.memory(
                    widget.fileBytes!,
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
                : (widget.filePath != null)
                    ? SfPdfViewer.file(
                        File(widget.filePath!),
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
                    : const Center(child: Text('Invalid PDF Source')),
          ),
          const AdBannerWidget(),
        ],
      ),
    );
  }
}
