import 'package:enough_mail/enough_mail.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:oneMail/Controller/base_controller.dart';
import 'package:oneMail/Model/email_model.dart';
import 'package:oneMail/Utils/logger.dart';
import 'package:oneMail/Utils/logging.dart';

class SearchByUserController extends GetxController with BaseController {
  RxList<MimeMessage> messages = RxList();
  RxInt fetchedMsg = 0.obs;

  SearchByUserController() {
    scrollController.addListener(() {
      if (scrollController.position.atEdge) {
        if (scrollController.position.pixels != 0) {
          fetchMore();
        }
      }
    });
  }

  Future<void> searchMail(String query) async {
    try {
      isLoading.value = true;
      MailSearchResult mailSearchResult =
          await services.mailClient.searchMessages(
        MailSearch(
          query,
          SearchQueryType.fromOrTo,
          pageSize: 99999999999999,
          fetchPreference: FetchPreference.envelope,
        ),
      );

      if (mailSearchResult.isEmpty) {
        isLoading.value = false;
        Fluttertoast.showToast(msg: "No Mails found.");
        return;
      }

      messages.addAll(mailSearchResult.messages);

      messages.sort((b, a) => a.decodeDate()!.compareTo(b.decodeDate()!));

      if (messages.length >= 10) {
        for (int i = 0; i <= 10; i++) {
          MimeMessage message =
              await services.mailClient.fetchMessageContents(messages[i]);

          emails.add(Email(message, message.isFlagged.obs, message.isSeen.obs));
        }
        fetchedMsg.value = 10;
      } else {
        for (MimeMessage msg in messages) {
          try {
            MimeMessage message =
                await services.mailClient.fetchMessageContents(msg);

            emails
                .add(Email(message, message.isFlagged.obs, message.isSeen.obs));
          } catch (e) {
            return;
          }
        }
        fetchedMsg.value = messages.length;
      }

      logError(fetchedMsg.string);
      isLoading.value = false;

      emails.sort((b, a) =>
          a.mimeMessage.decodeDate()!.compareTo(b.mimeMessage.decodeDate()!));
    } catch (e, trace) {
      isLoading.value = false;

      logToDevice("Services", "searchMail", e.toString(), trace);
    }
  }

  Future<void> fetchMore() async {
    if (!isFething.value && fetchedMsg.value < messages.length) {
      isFething.value = true;

      int rem = messages.length - fetchedMsg.value;

      if (rem >= 10) {
        rem = fetchedMsg.value + 10;
      } else {
        rem = fetchedMsg.value + rem;
      }

      for (int i = fetchedMsg.value + 1; i <= rem; i++) {
        try {
          MimeMessage message =
              await services.mailClient.fetchMessageContents(messages[i]);
          emails.add(Email(message, message.isFlagged.obs, message.isSeen.obs));
        } catch (e) {
          return;
        }
      }
      emails.sort((b, a) =>
          a.mimeMessage.decodeDate()!.compareTo(b.mimeMessage.decodeDate()!));

      isFething.value = false;
      fetchedMsg.value += rem;
    }
  }
}
