import 'dart:convert';
import 'package:enough_mail/enough_mail.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

class Email {
  final MimeMessage mimeMessage;
  final Rx<bool> isFlag;
  final Rx<bool> isSeen;
  final Rx<bool> isSelect = false.obs;

  factory Email.fromJSON(Map json) {
    bool isSeen = json['isSeen'] == "true";
    bool isFlag = json['isFlag'] == "true";
    return Email(
      MimeMessage.parseFromText(json['mimeMessage']),
      isFlag.obs,
      isSeen.obs,
    );
  }

  List<ContentInfo>? _attachments;
  List<ContentInfo> get attachments {
    var infos = _attachments;
    if (infos == null) {
      infos = mimeMessage.findContentInfo();
      final inlineAttachments = mimeMessage
          .findContentInfo(disposition: ContentDisposition.inline)
          .where((info) =>
              info.fetchId.isNotEmpty &&
              !(info.isText ||
                  info.isImage ||
                  info.mediaType?.sub ==
                      MediaSubtype.messageDispositionNotification));
      infos.addAll(inlineAttachments);
      _attachments = infos;
    }
    return infos;
  }

  @override
  String toString() {
    Map msg = {
      'mimeMessage': mimeMessage.toString(),
      'isFlag': isFlag.toString(),
      'isSeen': isSeen.toString(),
    };
    return jsonEncode(msg);
  }

  Email(this.mimeMessage, this.isFlag, this.isSeen);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Email &&
          runtimeType == other.runtimeType &&
          mimeMessage.decodeSubject()! == other.mimeMessage.decodeSubject()! &&
          mimeMessage.decodeDate()! == other.mimeMessage.decodeDate()!;

  @override
  int get hashCode =>
      mimeMessage.decodeSubject()!.hashCode +
      mimeMessage.decodeDate()!.hashCode;
}
