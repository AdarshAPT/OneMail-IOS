import 'dart:collection';
import 'package:enough_mail/enough_mail.dart';
import 'package:get/get.dart';
import 'package:oneMail/Model/email_model.dart';
import 'package:oneMail/Model/user_model.dart';
import 'package:oneMail/Utils/logger.dart';
import 'package:oneMail/Utils/logging.dart';
import 'base_controller.dart';

class GetEmailController extends GetxController with BaseController {
  GetEmailController() {
    scrollController.addListener(
      () {
        if (scrollController.position.atEdge) {
          if (scrollController.position.pixels != 0) {
            fetchMoreEmails();
          }
        }
      },
    );
    emails.listen((val) {
      if (val.length < 8) {
        if (!isLoading.value) {
          fetchMoreEmails();
        }
      }
    });
    listenToIncomingMails();
    fetchCacheEmails();
    fetchAllEmails();
  }

  // Future<void> fetchCacheMailbox() async {
  //   final User user = await storage.getCurrUser();
  //   List<Mailbox> temp = await cacheManager.getCachecMailBox(user);
  //   mailboxList.addAll(temp);
  // }

  Future<void> fetchMailbox() async {
    List<Mailbox> temp = await services.mailBox();
    if (temp.isEmpty) return;
    mailboxList.clear();
    mailboxList.addAll(temp);
  }

  listenToIncomingMails() {}

  fetchCacheEmails() async {
    isLoading.value = true;
    List<Email> msg = await services.getCacheMails();
    if (msg.isNotEmpty) {
      emails.addAll(msg);
      isLoading.value = false;
    }
    return msg;
  }

  fetchAllEmails() async {
    nextEmailToken = 0.obs;
    try {
      if (mailboxList.isEmpty) {
        await fetchMailbox();
      }
      final Map result = await services.getMails(nextEmailToken.value);
      if (result['result'].isNotEmpty) {
        emails.clear();
      }
      emails.addAll(result['result']);
      emails.sort((b, a) =>
          a.mimeMessage.decodeDate()!.compareTo(b.mimeMessage.decodeDate()!));
      nextEmailToken.value = result['nextPageToken'];
      isLoading.value = false;
    } catch (e, stackTrace) {
      logToDevice(
          "GetEmailController", "fetchAllEmails", e.toString(), stackTrace);
    }
  }

  fetchMoreEmails() async {
    if (nextEmailToken.value >= 1 && !isFething.value) {
      isFething.value = true;
      final Map result = await services.getMails(nextEmailToken.value);
      emails.addAll(result['result']);
      emails.sort((b, a) =>
          a.mimeMessage.decodeDate()!.compareTo(b.mimeMessage.decodeDate()!));
      nextEmailToken.value = result['nextPageToken'];
      isFething.value = false;
    }
  }

  pullToRefresh() async {
    logSuccess("refreshing emails");
    List<Email> newEmails = await services.getNewEmails();
    HashMap<DateTime, Email> hashMap = HashMap();

    for (Email email in emails) {
      hashMap[email.mimeMessage.decodeDate() ?? DateTime.now()] = email;
    }

    for (Email email in newEmails) {
      hashMap[email.mimeMessage.decodeDate() ?? DateTime.now()] = email;
    }

    // nextEmailToken.value = result['nextPageToken'];

    // logSuccess(nextEmailToken.value.toString());

    emails.clear();

    emails.addAll(hashMap.values);

    emails.sort((b, a) =>
        a.mimeMessage.decodeDate()!.compareTo(b.mimeMessage.decodeDate()!));
  }
}
