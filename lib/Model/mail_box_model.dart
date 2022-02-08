import 'dart:convert';
import 'package:enough_mail/enough_mail.dart';

class MailboxModel {
  final String name;
  final String path;
  final List<MailboxFlag> flags;
  final String? pathSeparator;

  MailboxModel(this.name, this.path, this.flags, this.pathSeparator);

  factory MailboxModel.fromJSON(Map<String, dynamic> json) {
    return MailboxModel(
        json["name"], json["path"], json["flags"], json["pathSeparator"]);
  }

  @override
  String toString() {
    final List<int> mailboxFlag = [];
    for (MailboxFlag flag in flags) {
      mailboxFlag.add(flag.index);
    }
    Map mailbox = {
      "name": name,
      "path": path,
      "flags": mailboxFlag,
      "pathSeparator": pathSeparator,
    };

    return jsonEncode(mailbox);
  }

  static Mailbox getMailbox(String mailbox) {
    Map<String, dynamic> map = jsonDecode(mailbox);
    String name = map['name'];
    String path = map['path'];
    List<MailboxFlag> mailboxFlag = [];
    String pathSeparator = map['pathSeparator'];

    for (var i in map['flags']) {
      mailboxFlag.add(MailboxFlag.values[i]);
    }

    return Mailbox.setup(
      name,
      path,
      mailboxFlag,
      pathSeparator: pathSeparator,
    );
  }
}
