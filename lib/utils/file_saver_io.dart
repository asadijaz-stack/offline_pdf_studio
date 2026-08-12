import 'dart:io';
import 'package:file_picker/file_picker.dart';

Future<String?> saveFileImpl(List<int> bytes, String fileName) async {
  String? outputFile = await FilePicker.saveFile(
    dialogTitle: 'Save Your File',
    fileName: fileName,
  );

  if (outputFile != null) {
    final file = File(outputFile);
    await file.writeAsBytes(bytes, flush: true);
    return outputFile;
  }
  return null;
}

Future<String?> saveMultipleFilesImpl(List<List<int>> filesBytes, List<String> fileNames, String zipName) async {
  String? directoryPath = await FilePicker.getDirectoryPath(
    dialogTitle: 'Select Directory to Save Files',
  );

  if (directoryPath != null) {
    for (int i = 0; i < filesBytes.length; i++) {
      final file = File('$directoryPath/${fileNames[i]}');
      await file.writeAsBytes(filesBytes[i], flush: true);
    }
    return directoryPath;
  }
  return null;
}
