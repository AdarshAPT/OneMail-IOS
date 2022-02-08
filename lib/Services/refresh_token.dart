import 'dart:async';
import 'dart:io';

import 'package:enough_mail/enough_mail.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:oneMail/Utils/auth_client.dart';
import 'package:oneMail/Utils/credentails.dart';

Future<OauthToken?> refresh(
    MailClient mailClient, OauthToken expiredToken) async {
  if (mailClient.account.name == 'gmail.com') {
    final response = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      body: {
        'client_id': googleClientID,
        'redirect_uri': '$googleCallbackURL:/',
        'refresh_token': expiredToken.refreshToken,
        'grant_type': 'refresh_token',
      },
    );

    return OauthToken.fromText(response.body);
  } else if (mailClient.account.name == 'outlook.com') {
    final response = await http.post(
      Uri.parse('https://login.microsoftonline.com/common/oauth2/v2.0/token'),
      body: {
        'client_id': outlookClientID,
        'scope': outlookScope,
        'refresh_token': expiredToken.refreshToken,
        'grant_type': 'refresh_token',
      },
    );
    return OauthToken.fromText(response.body);
  } else if (mailClient.account.name == 'yandex.com') {
    final response = await http.post(
      Uri.parse('https://oauth.yandex.com/token'),
      body: {
        'client_id': yandexClientID,
        'client_secret': yandexClientSecret,
        'refresh_token': expiredToken.refreshToken,
        'grant_type': 'refresh_token',
      },
    );

    return OauthToken.fromText(response.body);
  } else {
    return OauthToken.fromText("");
  }
}

Future<OauthToken?> getRefreshToken(
    AuthClient client, String refreshToken) async {
  if (client == AuthClient.Google) {
    try {
      final response = await http.post(
        Uri.parse('https://www.googleapis.com/oauth2/v4/token'),
        body: {
          'client_id': googleClientID,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
          'valid_for': '2592000'
        },
      ).timeout(
        const Duration(seconds: 2),
      );

      return OauthToken.fromText(response.body);
    } on TimeoutException catch (e) {
      Fluttertoast.showToast(msg: "Timeout");
    } on SocketException catch (e) {
      Fluttertoast.showToast(msg: "You are not connected to internet");
    }
  } else if (client == AuthClient.Microsoft) {
    try {
      final response = await http.post(
        Uri.parse('https://login.microsoftonline.com/common/oauth2/v2.0/token'),
        body: {
          'client_id': outlookClientID,
          'scope': outlookScope,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
        },
      ).timeout(const Duration(seconds: 2));
      return OauthToken.fromText(response.body);
    } on TimeoutException catch (e) {
      Fluttertoast.showToast(msg: "Timeout");
    } on SocketException catch (e) {
      Fluttertoast.showToast(msg: "You are not connected to internet");
    }
  } else if (client == AuthClient.Yandex) {
    try {
      final response = await http.post(
        Uri.parse('https://oauth.yandex.com/token'),
        body: {
          'client_id': yandexClientID,
          'client_secret': yandexClientSecret,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
        },
      ).timeout(
        const Duration(seconds: 2),
      );

      return OauthToken.fromText(response.body);
    } on TimeoutException catch (e) {
      Fluttertoast.showToast(msg: "Timeout");
    } on SocketException catch (e) {
      Fluttertoast.showToast(msg: "You are not connected to internet");
    }
  }
  return null;
}
