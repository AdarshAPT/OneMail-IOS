import 'package:mime/mime.dart';

class FileInfo {
  static bool isImage(String path) {
    final mimeType = lookupMimeType(path);

    return mimeType!.startsWith('image/');
  }

  static bool isDocument(String path) {
    final mimeType = lookupMimeType(path);
    return mimeType!.startsWith('application/');
  }

  static bool isAudio(String path) {
    final mimeType = lookupMimeType(path);

    return mimeType!.startsWith('audio/');
  }

  static bool isVideo(String path) {
    final mimeType = lookupMimeType(path);

    return mimeType!.startsWith('video/');
  }
}
