import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:oneMail/Exception/authentication_exception.dart';
import 'package:oneMail/Utils/credentails.dart';
import 'package:oneMail/Utils/logging.dart';

class GetUserInfo {
  Future<UserRes?> getUserInfoGMAIL(String accessToken) async {
    try {
      var response = await http.get(
          Uri.parse(
            "https://www.googleapis.com/oauth2/v1/userinfo?alt=json",
          ),
          headers: {
            "Authorization": "Bearer $accessToken",
            "Accept": "application/json"
          });

      if (response.statusCode == 200) {
        Map res = jsonDecode(response.body);
        UserRes user = UserRes(res['email'], res['picture'], res['name']);
        return user;
      }
    } on PlatformException catch (e) {
      rethrow;
    } on DioError catch (e) {
      rethrow;
    } catch (e) {
      throw AuthException(
          ExceptionType.APIFailed, "Unable to connect google api");
    }
  }

  Future<UserRes?> getUserInfoOUTLOOK(String accessToken) async {
    try {
      var response = await http.get(
          Uri.parse(
            "https://outlook.office.com/api/v2.0/me/",
          ),
          headers: {
            "Authorization": "Bearer $accessToken",
          });

      if (response.statusCode == 200) {
        Map user = jsonDecode(response.body);
        return UserRes(
          user['EmailAddress'],
          defaultAvatar,
          user['DisplayName'] ?? "Default",
        );
      }
    } catch (e, trace) {
      logToDevice("GetUserInfo", "getUserInfoOUTLOOK", e.toString(), trace);
    }

    return null;
  }

  Future<UserRes?> getUserInfoYANDEX(String accessToken) async {
    try {
      var response = await http.get(Uri.parse("https://login.yandex.ru/info?"),
          headers: {"Authorization": "OAuth $accessToken"});

      if (response.statusCode == 200) {
        final Map res = jsonDecode(response.body);
        UserRes user = UserRes(
            res['default_email'],
            'https://avatars.yandex.net/get-yapic/' +
                res['default_avatar_id'] +
                '/islands-200',
            res['real_name']);

        return user;
      }
    } on PlatformException catch (e) {
      rethrow;
    } on DioError catch (e) {
      rethrow;
    } catch (e) {
      throw AuthException(
          ExceptionType.APIFailed, "Unable to connect yandex api");
    }
  }
}

class UserRes {
  final String email;
  final String photoURL;
  final String userName;

  UserRes(this.email, this.photoURL, this.userName);
}
