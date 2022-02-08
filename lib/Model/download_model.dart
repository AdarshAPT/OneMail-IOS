import 'dart:convert';

import 'package:uuid/uuid.dart';

class DownloadFileModel {
  final String id = const Uuid().v1();
  final String fileName;
  final String filePath;
  final bool isImage;
  final bool isFile;
  final bool isVideo;
  final bool isAudio;
  final String mimeType;
  final String downloadDate;
  final String size;
  final String emailAddress;

  DownloadFileModel(
      this.fileName,
      this.filePath,
      this.isImage,
      this.isFile,
      this.isVideo,
      this.isAudio,
      this.mimeType,
      this.downloadDate,
      this.size,
      this.emailAddress);

  factory DownloadFileModel.fromJSON(String stringJSON) {
    Map json = jsonDecode(stringJSON);
    return DownloadFileModel(
        json['fileName'],
        json['filePath'],
        json['isImage'],
        json['isFile'],
        json['isVideo'],
        json['isAudio'],
        json['mimeType'],
        json['downloadDate'],
        json['size'],
        json['emailAddress']);
  }

  @override
  String toString() {
    Map json = {
      'fileName': fileName,
      'filePath': filePath,
      'isImage': isImage,
      'isFile': isFile,
      'isVideo': isVideo,
      'isAudio': isAudio,
      'mimeType': mimeType,
      'downloadDate': downloadDate,
      'size': size,
      'emailAddress': emailAddress,
    };

    return jsonEncode(json);
  }
}
