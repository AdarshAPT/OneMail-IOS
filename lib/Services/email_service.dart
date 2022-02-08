import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:enough_mail/enough_mail.dart';
import 'package:oneMail/Cache/cache_manager.dart';
import 'package:oneMail/Controller/base_controller.dart';
import 'package:oneMail/Model/email_model.dart';
import 'package:oneMail/Model/user_model.dart';
import 'package:oneMail/Services/authentication_service.dart' as auth;
import 'package:oneMail/Services/refresh_token.dart';
import 'package:oneMail/Services/storage_service.dart';
import 'package:oneMail/Utils/auth_client.dart';
import 'package:oneMail/Utils/logger.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:oneMail/Utils/logging.dart';

class Services {
  final CacheManager _cacheManager = CacheManager();
  final SecureStorage _storage = SecureStorage();
  ImapClient client = ImapClient(isLogEnabled: true);
  late MailClient mailClient;

  Future<bool> init(AuthClient authClient, {String email = ""}) async {
    late auth.Authentication authentication;
    try {
      if (authClient == AuthClient.Microsoft) {
        authentication = auth.OutlookAuthentication();
      } else if (authClient == AuthClient.Google) {
        authentication = auth.GmailAuthentication();
      } else if (authClient == AuthClient.Yandex) {
        authentication = auth.YandexAuthentication();
      }

      bool? result = await authentication.getmailAccount(email: email);

      if (result == null || !result) {
        return false;
      }

      mailClient = MailClient(
        authentication.mailAccount,
        logName: authentication.mailAccount.name,
        refresh: refresh,
      );

      authentication.client.selectInbox();
      authentication.client.idleStart();

      mailClient.eventBus.on<ImapConnectionLostEvent>().listen((event) {
        reInit(authClient);
      });

      mailClient.eventBus.on<MailException>().listen((event) {
        reInit(authClient);
      });

      mailClient.eventBus.on<MailConnectionLostEvent>().listen((event) {
        reInit(authClient);
      });

      mailClient.eventBus.on<MailVanishedEvent>().listen((event) {
        logSuccess("email removed ${event.sequence}");
      });

      mailClient.eventBus.on<MailUpdateEvent>().listen((event) {
        logSuccess("email removed ${event.message}");
      });

      try {
        await mailClient.connect();
      } on MailException catch (e) {
        if (authentication.user.isYandex) {
          Fluttertoast.showToast(msg: "msg");
        } else {
          Fluttertoast.showToast(msg: "Mail Client failed");
        }
        return false;
      } catch (e) {
        return false;
      }

      await _storage.setEmailAddress(authentication.user.emailAddress);
      await _storage.setLoggedin();

      if (!(await userAlreadyExist(authentication.user))) {
        await _storage.setNewUser(authentication.user);
      }

      Services.sendFCMToken();
    } catch (e) {
      if (authentication.user.isYandex) {
        Fluttertoast.showToast(msg: "Invalid credentials or IMAP is disabled");
        Navigator.of(Get.context!).pop();
      } else {
        Navigator.of(Get.context!).pop();
        Fluttertoast.showToast(msg: "Mail Client failed");
      }
      return false;
    }
    return true;
  }

  Future<void> reInit(AuthClient authClient) async {
    logInfo("refreshing");
    late auth.Authentication authentication;
    if (authClient == AuthClient.Microsoft) {
      authentication = auth.OutlookAuthentication();
    } else if (authClient == AuthClient.Google) {
      authentication = auth.GmailAuthentication();
    } else if (authClient == AuthClient.Yandex) {
      authentication = auth.YandexAuthentication();
    }

    await authentication.getmailAccount();

    mailClient = MailClient(
      authentication.mailAccount,
      logName: authentication.mailAccount.name,
      refresh: refresh,
    );

    authentication.client.selectInbox();
    authentication.client.idleStart();

    await mailClient.connect();
  }

  Future<List<Mailbox>> mailBox() async {
    final User user = await _storage.getCurrUser();

    List<Mailbox> listmailbox = await mailClient.listMailboxes();

    HashMap<String, Mailbox> setOfMailbox = HashMap<String, Mailbox>();

    for (Mailbox mailbox in listmailbox) {
      if (!setOfMailbox.containsKey(mailbox.encodedName)) {
        setOfMailbox[mailbox.encodedName] = mailbox;
      }
    }

    await _cacheManager.cacheMailBox(listmailbox, user);
    return setOfMailbox.values.toList();
  }

  Future<List<Email>> getCacheMails() async {
    final User user = await _storage.getCurrUser();
    List<Email> mimeMsg = await _cacheManager.getCacheMails(user);
    if (mimeMsg.isEmpty) return [];
    return mimeMsg.reversed.toList();
  }

  Future<Map> getMails(int startRange) async {
    final User user = await _storage.getCurrUser();
    List<Email> _results = [];
    try {
      Mailbox inbox = await mailClient.selectInbox();
      if (startRange == 0) startRange = inbox.messagesExists;

      if (inbox.messagesExists == 0) {
        await _cacheManager.cacheMails([], user);
        return {"result": _results, "nextPageToken": 0};
      }

      final fetchResult = await mailClient.fetchMessageSequence(
        MessageSequence.fromRange(
          startRange,
          startRange < 10 ? 1 : startRange - 10,
        ),
        mailbox: inbox,
      );
      for (MimeMessage msg in fetchResult) {
        _results.add(
          Email(
            msg,
            msg.isFlagged.obs,
            msg.isSeen.obs,
          ),
        );
      }
      await _cacheManager.cacheMails(_results, user);
    } catch (e, trace) {
      logToDevice("Services", "getMails", e.toString(), trace);
    }
    return {"result": _results, "nextPageToken": startRange - 10};
  }

  Future<List<Email>> getNewEmails() async {
    List<Email> _results = [];
    try {
      Mailbox inbox = await mailClient.selectInbox();
      final fetchResult =
          await mailClient.fetchMessages(mailbox: inbox, count: 5);
      for (MimeMessage msg in fetchResult) {
        _results.add(
          Email(
            msg,
            msg.isFlagged.obs,
            msg.isSeen.obs,
          ),
        );
      }
    } catch (e, trace) {
      logToDevice("Services", "getMails", e.toString(), trace);
    }
    return _results;
  }

  Future<Map?> fetchMailByFlags(Mailbox mailbox, int startRange) async {
    final User user = await _storage.getCurrUser();
    final List<Email> _results = [];
    try {
      Mailbox mail = await mailClient.selectMailbox(mailbox);
      if (startRange == 0) startRange = mail.messagesExists;

      if (mail.messagesExists == 0) {
        await _cacheManager.cacheMailboxMails([], user, mailbox);
        return {"result": _results, "nextPageToken": 0};
      }

      final List<MimeMessage> message = await mailClient.fetchMessageSequence(
        MessageSequence.fromRange(
          startRange,
          startRange < 10 ? 1 : startRange - 10,
        ),
        mailbox: mail,
      );

      for (MimeMessage msg in message) {
        _results.add(
          Email(
            msg,
            msg.isFlagged.obs,
            msg.isSeen.obs,
          ),
        );
      }
      await _cacheManager.cacheMailboxMails(_results, user, mailbox);
      return {"result": _results, "nextPageToken": startRange - 10};
    } catch (e, trace) {
      logToDevice("Services", "fetchMailByFlags", e.toString(), trace);
    }
  }

  Future<DeleteResult?> deleteMessage(
      MimeMessage message, Mailbox? mailbox) async {
    try {
      if (mailbox == null) {
        await mailClient.selectInbox();
      } else {
        await mailClient.selectMailbox(mailbox);
      }
      DeleteResult result = await mailClient.deleteMessage(message);
      return result;
    } catch (e, trace) {
      logToDevice("Services", "deleteMessage", e.toString(), trace);
    }
    return null;
  }

  Future<void> setFlagged(MimeMessage message, bool isFlagged) async {
    try {
      await mailClient.flagMessage(message, isFlagged: !isFlagged);
    } catch (e, trace) {
      logToDevice("Services", "setFlagged", e.toString(), trace);
    }
  }

  Future<void> setSeen(MimeMessage message, bool res) async {
    try {
      await mailClient.flagMessage(message, isSeen: res);
    } catch (e, trace) {
      logToDevice("Services", "setSeen", e.toString(), trace);
    }
  }

  Future<bool?> addAccount(AuthClient authClient, {String email = ""}) async {
    late auth.Authentication authentication;
    try {
      if (authClient == AuthClient.Microsoft) {
        authentication = auth.OutlookAuthentication(addAccount: true);
      } else if (authClient == AuthClient.Google) {
        authentication = auth.GmailAuthentication(addAccount: true);
      } else if (authClient == AuthClient.Yandex) {
        authentication = auth.YandexAuthentication(addAccount: true);
      }

      bool? result = await authentication.getmailAccount(
        email: email,
      );

      if (result == null || !result) return false;

      await Get.deleteAll(force: true);

      mailClient = MailClient(
        authentication.mailAccount,
        logName: authentication.mailAccount.name,
        refresh: refresh,
      );

      authentication.client.selectInbox();
      authentication.client.idleStart();

      mailClient.eventBus.on<ImapConnectionLostEvent>().listen((event) {
        reInit(authClient);
      });

      mailClient.eventBus.on<MailException>().listen((event) {
        reInit(authClient);
      });

      try {
        await mailClient.connect();
      } on MailException catch (e) {
        return false;
      }

      await _storage.setEmailAddress(authentication.user.emailAddress);
      await _storage.setLoggedin();

      if (!(await userAlreadyExist(authentication.user))) {
        await _storage.setNewUser(authentication.user);
      }
      Services.sendFCMToken();
    } catch (e) {
      if (authentication.user.isYandex) {
        Fluttertoast.showToast(msg: "Invalid credentials or IMAP is disabled");
        Navigator.of(Get.context!).pop();
      } else {
        Navigator.of(Get.context!).pop();
        Fluttertoast.showToast(msg: "Mail Client failed");
      }
      return false;
    }
    return true;
  }

  Future<List<Email>> searchByEmail(String emailId) async {
    List<Email> emails = [];
    try {
      MailSearchResult result = await mailClient.searchMessages(
        MailSearch(
          emailId,
          SearchQueryType.fromOrTo,
          fetchPreference: FetchPreference.full,
          pageSize: 99999,
        ),
      );
      List<MimeMessage> mails = result.messages;
      for (MimeMessage mail in mails) {
        emails.add(
          Email(mail, mail.isFlagged.obs, mail.isSeen.obs),
        );
      }
    } catch (e, trace) {
      logToDevice("Services", "searchByEmail", e.toString(), trace);
    }

    return emails;
  }

  Future<Mailbox?> createMailbox(String mailboxName) async {
    try {
      Mailbox mailbox = await mailClient.createMailbox(mailboxName);
      return mailbox;
    } catch (e, trace) {
      logToDevice("Services", "createMailbox", e.toString(), trace);
    }
    return null;
  }

  Future<void> deleteAllMails(BaseController controller,
      {bool permanentDelete = false}) async {
    List<Email> itemToDelete = [];

    for (int index = 0; index < controller.emails.length; index++) {
      if (controller.emails[index].isSelect.value) {
        itemToDelete.add(controller.emails[index]);
      }
    }

    for (Email email in itemToDelete) {
      controller.emails.remove(email);
      await mailClient.deleteMessage(email.mimeMessage);
    }

    controller.selectionModeEnable.value = false;
    Fluttertoast.showToast(msg: "Email moved to trash");
  }

  Future<bool> moveToMailbox(MimeMessage msg, Mailbox mailbox) async {
    try {
      MoveResult res = await mailClient.moveMessage(msg, mailbox);
      log("${res.originalMailbox!.encodedName} -> ${res.targetMailbox!.encodedName}");
    } catch (e, trace) {
      logToDevice("Services", "moveToMailbox", e.toString(), trace);
      return false;
    }
    return true;
  }

  Future<bool> deleteAllTrash(Mailbox mailbox) async {
    try {
      await mailClient.deleteAllMessages(mailbox, expunge: true);
      return true;
    } catch (e) {
      logError(e.toString());
    }
    return false;
  }

  Future<List<Email>> fetchReply(
      String query, RxList<Email> email, Mailbox? mailbox) async {
    try {
      if (mailbox == null) {
        await mailClient.selectInbox();
      } else {
        await mailClient.selectMailbox(mailbox);
      }
      var result = await mailClient.searchMessages(
        MailSearch(
          query.replaceAll("Re:", ""),
          SearchQueryType.subject,
          fetchPreference: FetchPreference.full,
        ),
      );
      if (result.messages.isNotEmpty) {
        email.clear();
      }
      for (MimeMessage msg in result.messages) {
        email.add(
          Email(
            msg,
            msg.isFlagged.obs,
            msg.isSeen.obs,
          ),
        );
      }
      await mailClient.selectMailbox(mailClient.getMailbox(MailboxFlag.sent)!);
      var result1 = await mailClient.searchMessages(
        MailSearch(
          query.replaceAll("Re:", ""),
          SearchQueryType.subject,
          fetchPreference: FetchPreference.full,
        ),
      );

      for (MimeMessage msg in result1.messages) {
        email.add(
          Email(
            msg,
            msg.isFlagged.obs,
            msg.isSeen.obs,
          ),
        );
      }
      log(email.length.toString());
    } catch (e, stackTrace) {
      logToDevice("Services", "fetchReply", e.toString(), stackTrace);
    }

    return email;
  }

  static Future<String?> _getId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      var iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor; // unique ID on iOS
    } else {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.androidId; // unique ID on Android
    }
  }

  static Future<void> sendFCMToken() async {
    try {
      String token = (await FirebaseMessaging.instance.getToken())!;
      logInfo(token);
      List<User> users = await SecureStorage().getUser();
      List<String> gmail = [];
      List<String> outlook = [];
      List<String> outlookUserId = [];
      List<String> yandex = [];
      for (User user in users) {
        if (user.isGmail) {
          gmail.add(user.emailAddress);
        }

        if (user.isOutlook) {
          outlook.add(user.emailAddress);
          outlookUserId.add(user.userID);
        }

        if (user.isYandex) {
          yandex.add(user.emailAddress);
        }
      }

      String uniqueId = (await _getId())!;

      Map data = {
        "applicationId": "smart.email.allmail.inbox$uniqueId",
        "fcmTokens": [token],
        "gmail": gmail,
        "outlook": outlook,
        "yandex": yandex,
        "outlookUserIds": outlookUserId,
      };

      log(data.toString());

      await Dio().post(
        "https://emailgo.apyhi.com/user",
        data: jsonEncode(data),
      );
    } catch (e) {
      log(e.toString());
    }
  }

  Future<bool> userAlreadyExist(User user) async {
    List<User> users = await _storage.getUser();

    for (User u in users) {
      if (u.emailAddress == user.emailAddress) {
        return true;
      }
    }

    return false;
  }
}
