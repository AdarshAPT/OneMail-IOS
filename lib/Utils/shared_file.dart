import 'dart:io';
import 'dart:typed_data';
import 'package:enough_mail/enough_mail.dart';

enum SharedDataAddState { added, notAdded }

class SharedDataAddResult {
  static const added = SharedDataAddResult(SharedDataAddState.added);
  static const notAdded = SharedDataAddResult(SharedDataAddState.notAdded);
  final SharedDataAddState state;
  final dynamic details;

  const SharedDataAddResult(this.state, [this.details]);
}

abstract class SharedData {
  final MediaType mediaType;

  SharedData(this.mediaType);
}

class SharedFile extends SharedData {
  final File file;
  SharedFile(this.file, MediaType? mediaType)
      : super(mediaType ?? MediaType.guessFromFileName(file.path));
}

class SharedBinary extends SharedData {
  final Uint8List? data;
  final String? filename;
  SharedBinary(this.data, this.filename, MediaType mediaType)
      : super(mediaType);
}

class SharedText extends SharedData {
  final String text;
  final String? subject;
  SharedText(this.text, MediaType? mediaType, {this.subject})
      : super(mediaType ?? MediaType.textPlain);
}

class SharedMailto extends SharedData {
  final Uri mailto;
  SharedMailto(this.mailto)
      : super(MediaType.fromSubtype(MediaSubtype.textHtml));
}
