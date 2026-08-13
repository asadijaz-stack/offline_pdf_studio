import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

class PdfService {
  /// Merges multiple PDFs into a single document.
  static Future<Uint8List?> mergePdfs(List<String> filePaths, List<Uint8List> fileBytes) async {
    try {
      final int count = kIsWeb ? fileBytes.length : filePaths.length;
      if (count == 0) return null;

      // Load the first file as the base document
      final PdfDocument document = PdfDocument();
      PdfSection? currentSection;
      
      for (int i = 0; i < count; i++) {
        PdfDocument loadedDocument;
        if (kIsWeb) {
          loadedDocument = PdfDocument(inputBytes: fileBytes[i]);
        } else {
          final File file = File(filePaths[i]);
          loadedDocument = PdfDocument(inputBytes: file.readAsBytesSync());
        }
        
        for (int j = 0; j < loadedDocument.pages.count; j++) {
          final PdfPage sourcePage = loadedDocument.pages[j];
          final PdfTemplate template = sourcePage.createTemplate();
          
          // Create a new section if this is the first page or if the size changes
          if (currentSection == null || currentSection.pageSettings.size != template.size) {
            currentSection = document.sections!.add();
            currentSection.pageSettings.size = template.size;
            currentSection.pageSettings.margins.all = 0;
          }
          
          final PdfPage newPage = currentSection.pages.add();
          newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));
        }
        loadedDocument.dispose();
      }
      
      final List<int> bytes = document.saveSync();
      document.dispose();
      
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Error merging PDFs: $e');
      return null;
    }
  }

  /// Splits a PDF by extracting specific pages.
  static Future<Uint8List?> splitPdf(dynamic fileInput, List<int> pagesToExtract) async {
    try {
      PdfDocument document;
      if (kIsWeb) {
        document = PdfDocument(inputBytes: fileInput as Uint8List);
      } else {
        document = PdfDocument(inputBytes: File(fileInput as String).readAsBytesSync());
      }
      
      // Iterate backwards and remove pages that are NOT in the extraction list
      // This preserves the exact PDF format, text, and metadata, unlike drawing templates
      for (int i = document.pages.count - 1; i >= 0; i--) {
        if (!pagesToExtract.contains(i)) {
          document.pages.removeAt(i);
        }
      }
      
      final List<int> bytes = document.saveSync();
      document.dispose();
      
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Error splitting PDF: $e');
      return null;
    }
  }

  /// Compresses a PDF to reduce its file size.
  static Future<Uint8List?> compressPdf(dynamic fileInput) async {
    try {
      PdfDocument document;
      if (kIsWeb) {
        document = PdfDocument(inputBytes: fileInput as Uint8List);
      } else {
        document = PdfDocument(inputBytes: File(fileInput as String).readAsBytesSync());
      }
      
      // Syncfusion applies comprehensive compression to the document structure
      document.compressionLevel = PdfCompressionLevel.best;
      
      final List<int> bytes = document.saveSync();
      document.dispose();
      
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Error compressing PDF: $e');
      return null;
    }
  }

  /// Converts a list of images into a single PDF document.
  static Future<Uint8List?> imagesToPdf(List<dynamic> imageInputs) async {
    try {
      final PdfDocument document = PdfDocument();
      document.pageSettings.margins.all = 0;
      
      for (var input in imageInputs) {
        Uint8List imageBytes;
        if (kIsWeb) {
          imageBytes = input as Uint8List;
        } else {
          imageBytes = File(input as String).readAsBytesSync();
        }
        
        final PdfBitmap pdfImage = PdfBitmap(imageBytes);
        final PdfPage page = document.pages.add();
        
        // Calculate proportional scale to fit within page bounds without stretching
        final double pageWidth = page.getClientSize().width;
        final double pageHeight = page.getClientSize().height;
        final double imageWidth = pdfImage.width.toDouble();
        final double imageHeight = pdfImage.height.toDouble();
        
        final double widthScale = pageWidth / imageWidth;
        final double heightScale = pageHeight / imageHeight;
        final double scale = widthScale < heightScale ? widthScale : heightScale;
        
        final double finalWidth = imageWidth * scale;
        final double finalHeight = imageHeight * scale;
        
        // Center the image on the page
        final double x = (pageWidth - finalWidth) / 2;
        final double y = (pageHeight - finalHeight) / 2;
        
        page.graphics.drawImage(
          pdfImage, 
          Rect.fromLTWH(x, y, finalWidth, finalHeight),
        );
      }
      
      final List<int> bytes = document.saveSync();
      document.dispose();
      
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Error converting images to PDF: $e');
      return null;
    }
  }

  /// Extracts pages from a PDF as images.
  static Future<Uint8List?> renderPdfPageToImage(dynamic fileInput, int pageNumber) async {
    try {
      pdfx.PdfDocument document;
      if (kIsWeb) {
        document = await pdfx.PdfDocument.openData(fileInput as Uint8List);
      } else {
        document = await pdfx.PdfDocument.openFile(fileInput as String);
      }
      
      final page = await document.getPage(pageNumber);
      final pageImage = await page.render(
        width: page.width * 2.0, 
        height: page.height * 2.0,
        format: pdfx.PdfPageImageFormat.png,
      );
      
      await page.close();
      await document.close();
      
      return pageImage?.bytes;
    } catch(e) {
      debugPrint('Error converting PDF to images: $e');
      return null;
    }
  }

  /// Extracts all pages from a PDF as images (PNG format).
  static Future<List<Uint8List>?> renderAllPdfPagesToImages(dynamic fileInput) async {
    try {
      pdfx.PdfDocument document;
      if (kIsWeb) {
        document = await pdfx.PdfDocument.openData(fileInput as Uint8List);
      } else {
        document = await pdfx.PdfDocument.openFile(fileInput as String);
      }
      
      final List<Uint8List> images = [];
      for (int i = 1; i <= document.pagesCount; i++) {
        final page = await document.getPage(i);
        final pageImage = await page.render(
          width: page.width * 2.0, 
          height: page.height * 2.0,
          format: pdfx.PdfPageImageFormat.png,
        );
        if (pageImage?.bytes != null) {
          images.add(pageImage!.bytes);
        }
        await page.close();
      }
      
      await document.close();
      return images;
    } catch(e) {
      debugPrint('Error converting all PDF pages to images: $e');
      return null;
    }
  }
}