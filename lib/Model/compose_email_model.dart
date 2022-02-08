import 'dart:io';
import 'package:oneMail/Model/user_model.dart';

class ComposeMailModel {
  final User from;
  final List<String> to;
  final String subject;
  final List<String> cc;
  final List<String> bcc;
  final List<File> files;
  final String textBody;
  final String htmlBody;
  ComposeMailModel(
    this.from,
    this.to,
    this.cc,
    this.bcc,
    this.files,
    this.subject,
    this.htmlBody,
    this.textBody,
  );
}
