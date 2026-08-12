import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/ad_banner.dart';
import '../widgets/pdf_viewer_scaffold.dart';

class PdfViewerScreen extends StatelessWidget {
  final String? filePath;
  final Uint8List? fileBytes;

  const PdfViewerScreen({super.key, this.filePath, this.fileBytes});

  @override
  Widget build(BuildContext context) {
    return PdfViewerScaffold(
      title: 'PDF Viewer',
      filePath: filePath,
      fileBytes: fileBytes,
      bottomActionWidget: const AdBannerWidget(),
    );
  }
}
