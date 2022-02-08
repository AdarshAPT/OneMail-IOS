import 'dart:convert';
import 'package:enough_mail/enough_mail.dart';
import 'package:oneMail/Model/contacts_model.dart';
import 'package:oneMail/Model/email_model.dart';
import 'package:oneMail/Model/mail_box_model.dart';
import 'package:oneMail/Model/user_model.dart';
import 'package:oneMail/Utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  Future<void> cacheMails(List<Email> msgs, User user) async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    Set<Email> allMimeMsg = {};
    allMimeMsg.addAll(msgs);

    Set<String> _cache = {};
    for (Email msg in allMimeMsg) {
      _cache.add(msg.toString());
    }

    await _prefs.setStringList(
        "cacheMail${user.emailAddress}", _cache.toList());
  }

  Future<List<Email>> getCacheMails(User user) async {
    logSuccess(user.emailAddress);
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    List<Email> _msg = [];
    if (_prefs.containsKey("cacheMail${user.emailAddress}")) {
      List<String> stringEmail =
          _prefs.getStringList("cacheMail${user.emailAddress}") ?? [];
      for (String email in stringEmail) {
        _msg.add(
          Email.fromJSON(
            jsonDecode(email),
          ),
        );
      }

      _msg.sort((a, b) =>
          a.mimeMessage.decodeDate()!.compareTo(b.mimeMessage.decodeDate()!));
    }
    return _msg;
  }

  Future<List<Mailbox>> getCachecMailBox(User user) async {
    final List<Mailbox> mailBox = [];
    final SharedPreferences _prefs = await SharedPreferences.getInstance();

    List<String> list =
        _prefs.getStringList("mailBox${user.emailAddress}") ?? [];

    for (String mailbox in list) {
      mailBox.add(MailboxModel.getMailbox(mailbox));
    }

    return mailBox;
  }

  Future<void> cacheMailBox(List<Mailbox> mailBox, User user) async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    final List<MailboxModel> mailboxModel = [];
    final List<String> cacheMailBox = [];

    for (Mailbox mailbox in mailBox) {
      mailboxModel.add(
        MailboxModel(
            mailbox.name, mailbox.path, mailbox.flags, mailbox.pathSeparator),
      );
    }

    for (MailboxModel mail in mailboxModel) {
      cacheMailBox.add(mail.toString());
    }

    await _prefs.setStringList("mailBox${user.emailAddress}", cacheMailBox);
  }

  Future<List<Email>> getcacheMailBoxMails(User user, Mailbox mailbox) async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    List<Email> _msg = [];
    if (_prefs.containsKey("cache${mailbox.name}${user.emailAddress}")) {
      List<String> stringEmail =
          _prefs.getStringList("cache${mailbox.name}${user.emailAddress}") ??
              [];
      for (String email in stringEmail) {
        _msg.add(
          Email.fromJSON(
            jsonDecode(email),
          ),
        );
      }

      _msg.sort((a, b) => (a.mimeMessage.decodeDate() ?? DateTime.now())
          .compareTo(b.mimeMessage.decodeDate() ?? DateTime.now()));
    }
    return _msg;
  }

  Future<void> cacheMailboxMails(
      List<Email> msgs, User user, Mailbox mailbox) async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();

    Set<String> _cache = {};

    if (msgs.isNotEmpty) {
      Set<Email> allMimeMsg = {};
      allMimeMsg.addAll(msgs);

      for (Email msg in allMimeMsg) {
        _cache.add(msg.toString());
      }
    }

    await _prefs.setStringList(
        "cache${mailbox.name}${user.emailAddress}", _cache.toList());
  }

  Future<void> deleteCacheMessage(MimeMessage message, User user) async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    if (_prefs.containsKey("cacheMail${user.emailAddress}")) {
      List<String> stringifyEmails =
          _prefs.getStringList("cacheMail${user.emailAddress}") ?? [];
      List<Email> mails = stringifyEmails
          .map<Email>((msg) => Email.fromJSON(jsonDecode(msg)))
          .toList();

      mails.removeWhere((element) => element.mimeMessage == message);

      List<String> stringMails =
          mails.map<String>((e) => e.toString()).toList();
      await _prefs.setStringList("cacheMail${user.emailAddress}", stringMails);
    }
  }

  Future<void> cacheContacts(List<Contacts> contacts) async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    List<String> stringifyContacts =
        contacts.map<String>((json) => json.toString()).toList();

    await _prefs.setStringList("contacts", stringifyContacts);
  }

  Future<List<Contacts>> getCacheContacts() async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    final List<Contacts> result = [];

    if (_prefs.containsKey("contacts")) {
      List<String> cacheContacts = _prefs.getStringList("contacts")!;

      result.addAll(cacheContacts
          .map<Contacts>((json) => Contacts.fromCache(json))
          .toList());
    }

    return result;
  }
}
