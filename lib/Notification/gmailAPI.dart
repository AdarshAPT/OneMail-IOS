// ignore_for_file: file_names
import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dio/dio.dart';
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/foundation.dart';
import 'package:oneMail/Model/user_model.dart';
import 'package:oneMail/Services/refresh_token.dart';
import 'package:oneMail/Services/storage_service.dart';
import 'package:oneMail/Utils/auth_client.dart';
import 'package:oneMail/Utils/credentails.dart';
import 'package:oneMail/Utils/logger.dart';
import 'package:html/parser.dart';

String parseHtmlString(String htmlString) {
  final document = parse(htmlString);
  var parsedString = parse(document.body!.text)
      .documentElement!
      .text
      .replaceAll('\t', '')
      .replaceAll('\r', '')
      .replaceAll('\n', '')
      .replaceAll(RegExp(' +'), ' ')
      .trim();
  return parsedString;
}

class GmailAPI {
  final SecureStorage storage = SecureStorage();
  final Dio dio = Dio();

  Future<void> notifyGmail(int historyID, String userEmail) async {
    final List<User> user = await storage.getUser();
    logSuccess(historyID.toString());
    for (User u in user) {
      if (u.emailAddress == userEmail) {
        OauthToken? token =
            await getRefreshToken(AuthClient.Google, u.refreshToken);

        String? getHistoryID = await storage.getHistoryID(u);

        await storage.setHistoryID(u, historyID.toString());

        logInfo(token!.accessToken);

        var response;

        logSuccess(token.accessToken);

        logSuccess(
          {
            "x-android-package": "smart.email.allmail.inbox",
            "X-Android-Cert": kDebugMode
                ? "E83ACCD52724DA8242EF9B899B8350AA2ADF7E01"
                : "CA354BD44FFAF4832C884190BF7F228909E739F6",
            "Authorization": "Bearer ${token.accessToken}",
          }.toString(),
        );

        try {
          response = await Dio().get(
            "https://gmail.googleapis.com/gmail/v1/users/me/history?key=$googleAPIKEY&startHistoryId=$getHistoryID",
            options: Options(
              headers: {
                "x-android-package": "smart.email.allmail.inbox",
                "X-Android-Cert": kDebugMode
                    ? "E83ACCD52724DA8242EF9B899B8350AA2ADF7E01"
                    : "CA354BD44FFAF4832C884190BF7F228909E739F6",
                "Authorization": "Bearer ${token.accessToken}",
              },
            ),
          );
        } on DioError catch (e) {
          logError(e.response!.toString());
          return;
        } catch (e) {
          logError(e.toString());
          return;
        }

        List historyMap = response.data['history'];

        logSuccess(historyMap.last.toString());

        String messageID = historyMap.last['messages'].last['id'];

        logSuccess(messageID);

        var email = await Dio().get(
          "https://gmail.googleapis.com/gmail/v1/users/me/messages/$messageID?key=$googleAPIKEY",
          options: Options(
            headers: {
              "x-android-package": "smart.email.allmail.inbox",
              "X-Android-Cert": kDebugMode
                  ? "E83ACCD52724DA8242EF9B899B8350AA2ADF7E01"
                  : "CA354BD44FFAF4832C884190BF7F228909E739F6",
              "Authorization": "Bearer ${token.accessToken}",
            },
          ),
        );

        List headers = email.data['payload']['headers'];

        List labels = email.data['labelIds'];

        if (labels.contains("DRAFT")) {
          logWarning('is draft');
          return;
        }

        if (!labels.contains("UNREAD")) {
          logWarning('already read');
          return;
        }

        String realFrom = "";
        String from = "";
        String subject = "(No subject)";

        for (Map header in headers) {
          if (header['name'] == "Subject") {
            subject = header['value'];
          }

          if (header['name'] == 'From') {
            String fromString = header['value'];
            RegExp regex = RegExp('(?<=<)(.*?)(?=>)');
            String matched = regex.stringMatch(fromString)!;

            realFrom = fromString;
            from = matched;
          }
        }

        String displayName = from.replaceAll(realFrom, '<$realFrom>');

        displayName = displayName.isEmpty ? realFrom : displayName;

        logSuccess({
          "messageID": messageID,
          "refreshToken": u.refreshToken,
          "from": from,
          "fromField": realFrom,
          "subject": subject,
        }.toString());

        logSuccess(email.data['snippet']);

        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: email.data['snippet'].hashCode,
            channelKey: 'oneMail',
            category: NotificationCategory.Email,
            roundedLargeIcon: true,
            summary: userEmail,
            largeIcon:
                'https://ui-avatars.com/api/?bold=true&name=$from&background=0D8ABC&color=fff&size=128',
            title: displayName,
            wakeUpScreen: true,
            body: subject.replaceAll('Re: ', '').replaceAll('Fwd: ', '') +
                '<br>' +
                email.data['snippet'].toString().replaceAll('\n', '<br>'),
            payload: {
              "messageID": messageID,
              "refreshToken": u.refreshToken,
              "from": from,
              "client": "gmail",
              "fromField": realFrom,
              "subject": subject,
              "email": jsonEncode(email.data),
            },
            notificationLayout: NotificationLayout.BigText,
          ),
          actionButtons: [
            NotificationActionButton(
              key: "reply",
              label: "Reply",
            ),
            NotificationActionButton(
              key: "delete",
              label: "Delete",
              buttonType: ActionButtonType.KeepOnTop,
              autoDismissible: true,
            ),
          ],
        );
        break;
      }
    }
  }

  Future<void> deleteEmail(String id, String refreshToken) async {
    OauthToken? token = await getRefreshToken(AuthClient.Google, refreshToken);

    if (token == null) return;

    var res = await dio.post(
      "https://gmail.googleapis.com/gmail/v1/users/me/messages/$id/trash",
      data: {},
      options: Options(
        headers: {
          "Authorization": "Bearer ${token.accessToken}",
        },
      ),
    );

    logInfo(res.data.toString());
  }

  void reply() {}
}
