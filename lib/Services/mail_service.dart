import 'dart:convert';
import 'dart:io';
import 'package:enough_mail/enough_mail.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:oneMail/Model/compose_email_model.dart';
import 'package:oneMail/Services/refresh_token.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:oneMail/Utils/logger.dart';
import 'package:oneMail/Utils/logging.dart';

class SendMail {
  String _formatXoauth2Token(String userEmail, String accessToken) {
    return ascii
        .fuse(base64)
        .encode('user=$userEmail\u0001auth=Bearer $accessToken\u0001\u0001');
  }

  Future<void> sendMail(ComposeMailModel msg) async {
    try {
      final String refreshToken = msg.from.refreshToken;
      final OauthToken? token =
          await getRefreshToken(msg.from.client, refreshToken);

      if (token == null) {
        Fluttertoast.showToast(msg: "Authentication failed");
        logError("Authentication Failed");
        return;
      }

      final List<Attachment> attachments = [];

      for (File file in msg.files) {
        attachments.add(FileAttachment(file));
      }

      SmtpServer smtpServer = SmtpServer(
        msg.from.smtpSetting,
        ssl: false,
        xoauth2Token:
            _formatXoauth2Token(msg.from.emailAddress, token.accessToken),
        allowInsecure: true,
        ignoreBadCertificate: true,
      );

      Message message = Message();
      message.text = msg.textBody;
      message.html = msg.htmlBody;
      message.from = Address(msg.from.emailAddress, msg.from.userName);
      message.recipients = msg.to;
      message.subject = msg.subject.isEmpty ? "No subject" : msg.subject;
      message.attachments = attachments;
      message.ccRecipients = msg.cc;
      message.bccRecipients = msg.bcc;
      await Fluttertoast.showToast(msg: "Sending ...");
      await send(message, smtpServer);
      await Fluttertoast.showToast(msg: "Email sent successfully");
    } catch (e, stackTrace) {
      logToDevice("mailer.dart/SendMail", "sendMail", e.toString(), stackTrace);
    }
    return;
  }
}
