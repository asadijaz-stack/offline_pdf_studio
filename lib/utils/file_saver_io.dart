import 'dart:io';
import 'package:file_picker/file_picker.dart';

import 'dart:typed_data';

Future<String?> saveFileImpl(List<int> bytes, String fileName) async {
  String? outputFile = await FilePicker.saveFile(
    dialogTitle: 'Save Your File',
    fileName: fileName,
    bytes: Uint8List.fromList(bytes),
  );

  if (outputFile != null) {
    try {
      final file = File(outputFile);
      if (!await file.exists() || (await file.length()) == 0) {
        await file.writeAsBytes(bytes, flush: true);
      }
    } catch (e) {
      // file_picker might have already saved the bytes natively using the passed `bytes` parameter.
      // If we can't write to the path directly using dart:io, it's likely handled by the native platform.
    }
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
