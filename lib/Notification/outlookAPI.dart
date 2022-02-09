// ignore_for_file: file_names

import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dio/dio.dart';
import 'package:enough_mail/enough_mail.dart';
import 'package:oneMail/Model/user_model.dart';
import 'package:oneMail/Services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:oneMail/Utils/credentails.dart';
import 'package:oneMail/Utils/logger.dart';

class OutlookAPI {
  final SecureStorage storage = SecureStorage();
  final Dio dio = Dio();

  void notifyOutlook(String historyID, String outlookUserId) async {
    final List<User> users = await storage.getUser();

    for (User user in users) {
      if (user.userID == outlookUserId) {
        final response = await http.post(
          Uri.parse(
              'https://login.microsoftonline.com/common/oauth2/v2.0/token'),
          body: {
            'client_id': outlookClientID,
            'scope': 'Mail.Read Mail.ReadWrite',
            'refresh_token': user.refreshToken,
            'grant_type': 'refresh_token',
          },
        );

        final OauthToken? token = OauthToken.fromText(response.body);

        if (token == null) return;

        final result = await http.get(
            Uri.parse('https://graph.microsoft.com/v1.0/$historyID'),
            headers: {'Authorization': 'Bearer ' + token.accessToken});

        Map email = jsonDecode(result.body);

        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: jsonEncode(email).hashCode,
            wakeUpScreen: true,
            channelKey: 'oneMail',
            ticker: user.emailAddress,
            roundedLargeIcon: true,
            category: NotificationCategory.Email,
            summary: user.emailAddress,
            largeIcon:
                'https://ui-avatars.com/api/?bold=true&name=${email['sender']['emailAddress']['address']}&background=0D8ABC&color=fff&size=128',
            title: email['sender']['emailAddress']['name'] ??
                email['sender']['emailAddress']['address'],
            body: email['subject'] +
                '<br>' +
                email['bodyPreview'].toString().replaceAll('\n', '<br>'),
            payload: {
              "messageID": email['id'],
              "refreshToken": user.refreshToken,
              "client": "outlook",
              "from": email['sender']['emailAddress']['address'],
              "fromField": email['sender']['emailAddress']['address'],
              "subject": email['subject'],
              "email": jsonEncode(email),
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
    final response = await http.post(
      Uri.parse('https://login.microsoftonline.com/common/oauth2/v2.0/token'),
      body: {
        'client_id': outlookClientID,
        'scope': 'Mail.Read Mail.ReadWrite',
        'refresh_token': refreshToken,
        'grant_type': 'refresh_token',
      },
    );

    final OauthToken? token = OauthToken.fromText(response.body);

    if (token == null) return;

    logSuccess('https://graph.microsoft.com/v1.0/me/messages/$id');

    logSuccess(token.toString());

    var res = await dio.post(
      "https://graph.microsoft.com/v1.0/me/messages/$id/move",
      data: {"destinationId": "deleteditems"},
      options: Options(
        headers: {
          "Authorization": "Bearer ${token.accessToken}",
        },
      ),
    );

    logInfo(res.data.toString());
  }
}
