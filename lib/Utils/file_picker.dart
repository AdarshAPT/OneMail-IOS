import 'dart:io';

import 'package:file_picker/file_picker.dart';

class Filepicker {
  Future<List<File>?> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        List<File> files = result.paths.map((path) => File(path!)).toList();
        return files;
      } else {}
    } catch (e) {
      throw Exception("No image selected");
    }

    return null;
  }
}
