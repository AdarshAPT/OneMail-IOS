import 'dart:typed_data';

import 'package:enough_mail/codecs.dart';
import 'package:oneMail/Utils/shared_file.dart';

import 'logger.dart';

Future<List<SharedData>> collectSharedData(Map<dynamic, dynamic> shared) async {
  final sharedData = <SharedData>[];
  final String? mimeTypeText = shared['mimeType'];
  final mediaType = (mimeTypeText == null || mimeTypeText.contains('*'))
      ? null
      : MediaType.fromText(mimeTypeText);
  final int? length = shared['length'];
  final String? text = shared['text'];
  logSuccess('share text: "$text"');
  if (length != null && length > 0) {
    for (var i = 0; i < length; i++) {
      final String? filename = shared['name.$i'];
      final Uint8List? data = shared['data.$i'];
      final String? typeName = shared['type.$i'];
      final localMediaType = (typeName != 'null')
          ? MediaType.fromText(typeName!)
          : mediaType ?? MediaType.guessFromFileName(filename!);
      sharedData.add(SharedBinary(data, filename, localMediaType));
      logSuccess(
          'share: loaded ${localMediaType.text}  "$filename" with ${data?.length} bytes');
    }
  } else if (text != null) {
    if (text.startsWith('mailto:')) {
      final mailto = Uri.parse(text);
      sharedData.add(SharedMailto(mailto));
    } else {
      sharedData.add(SharedText(text, mediaType, subject: shared['subject']));
    }
  }
  return sharedData;
}
