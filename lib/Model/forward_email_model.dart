import 'dart:typed_data';

class ForwardModel {
  final String from;
  final DateTime date;
  final String subject;
  final String to;
  final List<Attachment> attachments;
  final String body;
  final String cc;

  ForwardModel(this.from, this.date, this.subject, this.to, this.attachments,
      this.body, this.cc);
}

class Attachment {
  final Uint8List file;
  final String name;

  Attachment(this.file, this.name);
}
