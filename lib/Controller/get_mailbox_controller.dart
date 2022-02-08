import 'package:enough_mail/enough_mail.dart';
import 'package:get/get.dart';
import 'package:oneMail/Cache/cache_manager.dart';
import 'package:oneMail/Model/email_model.dart';
import 'package:oneMail/Model/user_model.dart';
import 'base_controller.dart';

class GetMailBoxController extends GetxController with BaseController {
  final Mailbox mailbox;
  final CacheManager manager = CacheManager();

  GetMailBoxController(this.mailbox) {
    scrollController.addListener(() {
      if (scrollController.position.atEdge) {
        if (scrollController.position.pixels != 0) {
          fetchMoreEmails(mailbox);
        }
      }
    });
  }

  fetchAllEmails() async {
    final User user = await storage.getCurrUser();

    List<Email> cacheMails = await manager.getcacheMailBoxMails(user, mailbox);

    if (cacheMails.isNotEmpty) {
      emails.addAll(cacheMails);
      emails.sort((b, a) => (a.mimeMessage.decodeDate() ?? DateTime.now())
          .compareTo(b.mimeMessage.decodeDate() ?? DateTime.now()));
    } else {
      isLoading.value = true;
    }

    final Map? result =
        await services.fetchMailByFlags(mailbox, nextEmailToken.value);

    if (result == null) {
      return;
    }

    emails.clear();
    isLoading.value = false;
    List<Email> _res = result['result'];
    emails.addAll(_res);
    emails.sort((a, b) => (a.mimeMessage.decodeDate() ?? DateTime.now())
        .compareTo(b.mimeMessage.decodeDate() ?? DateTime.now()));
    nextEmailToken.value = result['nextPageToken'];
    emails.value = emails.reversed.toList();
  }

  fetchMoreEmails(Mailbox mailbox) async {
    if (nextEmailToken.value >= 1 && !isFething.value) {
      isFething.value = true;
      final Map? result =
          await services.fetchMailByFlags(mailbox, nextEmailToken.value);

      if (result == null) return;

      emails.addAll(result['result']);
      nextEmailToken.value = result['nextPageToken'];
      emails.sort((a, b) => (a.mimeMessage.decodeDate() ?? DateTime.now())
          .compareTo(b.mimeMessage.decodeDate() ?? DateTime.now()));
      isFething.value = false;
      emails.value = emails.reversed.toList();
    }
  }

  pullToRefresh() async {
    final Map? result = await services.fetchMailByFlags(mailbox, 0);

    if (result == null) return;

    List<Email> _res = result['result'];
    Set<Email> hashMap = {};
    hashMap.addAll(emails);
    hashMap.addAll(_res);
    emails.sort((b, a) =>
        a.mimeMessage.decodeDate()!.compareTo(b.mimeMessage.decodeDate()!));
  }
}
