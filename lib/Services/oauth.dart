import 'dart:io';
import 'package:dio/dio.dart';
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:oneMail/Exception/authentication_exception.dart';
import 'package:oneMail/Model/user_model.dart';
import 'package:oneMail/Services/get_user_info.dart';
import 'package:oneMail/Services/refresh_token.dart';
import 'package:oneMail/Services/storage_service.dart';
import 'package:oneMail/Utils/auth_client.dart';
import 'package:oneMail/Utils/credentails.dart';
import 'package:oneMail/Utils/loading_indicator.dart';
import 'package:oneMail/Utils/logger.dart';
import 'package:oneMail/Utils/logging.dart';
import 'package:workmanager/workmanager.dart';

Future<String> subscribeToGmail(String accessToken) async {
  Map body = {
    "topicName": "projects/onemail-333315/topics/oneMail",
    "labelFilterAction": "include",
    "labelIds": ["INBOX", "UNREAD"]
  };

  try {
    logInfo(
        "https://www.googleapis.com/gmail/v1/users/me/watch?access_token=$accessToken");
    await Dio().post(
      "https://www.googleapis.com/gmail/v1/users/me/watch?access_token=$accessToken",
      data: body,
    );
  } catch (e, trace) {
    logToDevice("Services", "subcribe", e.toString(), trace);
  }

  return '';
}

Future<String> subscribeToOutlook(String email) async {
  try {
    final url = Uri.https(
        'login.microsoftonline.com', '/common/oauth2/v2.0/authorize', {
      'response_type': 'code',
      'client_id': outlookClientID,
      'client_secret': outlookClientSecret,
      'redirect_uri': callbackURL,
      'scope': 'Mail.Read Mail.ReadWrite User.Read',
      'prompt': 'consent',
      'login_hint': email,
    });

    final result = await FlutterWebAuth.authenticate(
      url: url.toString(),
      callbackUrlScheme: "onemail",
      preferEphemeral: true,
    );

    String code = Uri.parse(result).queryParameters['code']!;

    final response = await http.post(
      Uri.parse('https://login.microsoftonline.com/common/oauth2/v2.0/token'),
      body: {
        'client_id': outlookClientID,
        'redirect_uri': callbackURL,
        'grant_type': 'authorization_code',
        'code': code,
      },
    );

    final token = OauthToken.fromText(response.body);

    logSuccess(token.toString());

    Map body = {
      "changeType": "created",
      "notificationUrl": "https://emailgo.apyhi.com/outlook/push/notification",
      "resource": "/me/mailfolders('inbox')/messages",
      "expirationDateTime":
          (DateTime.now().add(const Duration(hours: 10))).toIso8601String() +
              'Z',
    };

    await Dio().post(
      "https://graph.microsoft.com/v1.0/subscriptions",
      options: Options(headers: {
        "Authorization": "Bearer ${token.accessToken}",
      }),
      data: body,
    );

    var userInfo = await Dio().get(
      'https://graph.microsoft.com/v1.0/me',
      options: Options(headers: {
        "Authorization": "Bearer ${token.accessToken}",
      }),
    );

    return userInfo.data['id'];
  } on DioError catch (e) {
    logError(e.message);
  } catch (e) {
    logError(e.toString());
  }

  return '';
}

class Oauth {
  final SecureStorage _storage = SecureStorage();
  final GetUserInfo _userInfo = GetUserInfo();

  Future<Map?> googleSignin(BuildContext context, {addAccount = false}) async {
    if (await _storage.isLoggedin() && !addAccount) {
      try {
        final User user = await _storage.getCurrUser();
        final String refreshToken = user.refreshToken;
        final token = await getRefreshToken(user.client, refreshToken);
        await _userInfo.getUserInfoGMAIL(token!.accessToken);
        return {"token": token, "user": user};
      } on AuthException catch (e) {
        Fluttertoast.showToast(msg: e.message);
      } on PlatformException catch (e) {
        if (e.message != null) Fluttertoast.showToast(msg: e.message!);
      }
    } else {
      try {
        final url = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
          'response_type': 'code',
          'client_id': googleClientID,
          'redirect_uri': '$googleCallbackURL:/',
          'scope': googleScope,
          'access_type': 'offline',
        });

        final result = await FlutterWebAuth.authenticate(
          url: url.toString(),
          callbackUrlScheme: googleCallbackURL,
          preferEphemeral: true,
        );

        final code = Uri.parse(result).queryParameters['code']!;

        showLoaderDialog(context, !addAccount);

        final response = await http.post(
          Uri.parse('https://oauth2.googleapis.com/token'),
          body: {
            'client_id': googleClientID,
            'redirect_uri': '$googleCallbackURL:/',
            'grant_type': 'authorization_code',
            'code': code,
            'valid_for': '2592000'
          },
        );

        final token = OauthToken.fromText(response.body);
        final UserRes? userRes;

        try {
          userRes = await _userInfo.getUserInfoGMAIL(token.accessToken);

          if (userRes == null) {
            throw AuthException(ExceptionType.Unknown, "Network error");
          }
        } on AuthException catch (e) {
          logError(e.message);
          rethrow;
        } on PlatformException catch (e) {
          rethrow;
        } on DioError catch (e) {
          rethrow;
        } catch (e) {
          throw AuthException(ExceptionType.Unknown, "Network error");
        }

        List<User> users = await _storage.getUser();

        for (User u in users) {
          if (u.emailAddress == userRes.email) {
            throw AuthException(
                ExceptionType.UserAlreadyExist, "User already Exsist");
          }
        }

        String userID = await subscribeToGmail(token.accessToken);

        final User user = User.getUser(
          emailAddress: userRes.email,
          emailClient: AuthClient.Google,
          refreshToken: token.refreshToken,
          photoURL: userRes.photoURL,
          userName: userRes.userName,
          userID: userID,
        );
        return {"token": token, "user": user};
      } catch (e) {
        throw AuthException(ExceptionType.Unknown, "Network error");
      }
    }
  }

  Future<Map?> outlookSignin(
    BuildContext context,
    String emailId, {
    bool addAccount = false,
  }) async {
    late final String code;

    if (await _storage.isLoggedin() && !addAccount) {
      try {
        final User user = await _storage.getCurrUser();
        final String refreshToken = user.refreshToken;
        final token = await getRefreshToken(user.client, refreshToken);
        return {"token": token, "user": user};
      } on AuthException catch (e) {
        Fluttertoast.showToast(msg: e.message);
      } on PlatformException catch (e) {
        if (e.message != null) Fluttertoast.showToast(msg: e.message!);
      }
    } else {
      try {
        final url = Uri.https(
            'login.microsoftonline.com', '/common/oauth2/v2.0/authorize', {
          'response_type': 'code',
          'client_id': outlookClientID,
          'client_secret': outlookClientSecret,
          'redirect_uri': callbackURL,
          'scope': outlookScope,
          'prompt': 'login',
          'login_hint': emailId,
        });

        final result = await FlutterWebAuth.authenticate(
          url: url.toString(),
          callbackUrlScheme: "onemail",
          preferEphemeral: true,
        );

        showLoaderDialog(context, !addAccount);

        code = Uri.parse(result).queryParameters['code']!;

        final response = await http.post(
          Uri.parse(
              'https://login.microsoftonline.com/common/oauth2/v2.0/token'),
          body: {
            'client_id': outlookClientID,
            'redirect_uri': callbackURL,
            'grant_type': 'authorization_code',
            'code': code,
          },
        );

        final token = OauthToken.fromText(response.body);

        final UserRes userRes = UserRes(
          emailId,
          defaultAvatar,
          emailId.split('@').first,
        );

        List<User> users = await _storage.getUser();

        for (User u in users) {
          if (u.emailAddress == userRes.email) {
            throw AuthException(
              ExceptionType.UserAlreadyExist,
              "User Already Exist",
            );
          }
        }

        String userID = await subscribeToOutlook(userRes.email);

        if (Platform.isAndroid) {
          Workmanager().registerPeriodicTask(
            userID,
            "outlook resubscribe",
            constraints: Constraints(
              networkType: NetworkType.connected,
              requiresStorageNotLow: true,
            ),
            frequency: const Duration(hours: 10),
            inputData: {
              "refreshToken": token.refreshToken,
              "user": userRes.email,
            },
          );
        }

        final User user = User.getUser(
          refreshToken: token.refreshToken,
          emailAddress: userRes.email,
          emailClient: AuthClient.Microsoft,
          photoURL: userRes.photoURL,
          userName: userRes.userName,
          userID: userID,
        );

        return {"token": token, "user": user};
      } catch (e) {
        throw AuthException(ExceptionType.Unknown, "Network error");
      }
    }
  }

  // Future<OauthToken?> yahooSignin(String email, {addAccount = false}) async {
  //   if (await _storage.isLoggedin() && !addAccount) {
  //     final User user = await _storage.getCurrUser();
  //     final String mailClient = user.emailClient;
  //     final String refreshToken = user.refreshToken;
  //     final token = await getRefreshToken(mailClient, refreshToken);

  //     return token;
  //   } else {
  //     final url = Uri.https('api.login.yahoo.com', '/oauth2/request_auth', {
  //       'client_id': clientId,
  //       'client_secret': clientSecret,
  //       'response_type': 'code',
  //       'redirect_uri': callbackUrlScheme,
  //     });

  //     final result = await FlutterWebAuth.authenticate(
  //         url: url.toString(), callbackUrlScheme: "emaily");

  //     final code = Uri.parse(result).queryParameters['code']!;

  //     final response = await http.post(
  //       Uri.parse('https://api.login.yahoo.com/oauth2/get_token'),
  //       body: {
  //         'client_id': clientId,
  //         'client_secret': clientSecret,
  //         'redirect_uri': callbackUrlScheme,
  //         'grant_type': 'authorization_code',
  //         'code': code,
  //       },
  //     );

  //     final token = OauthToken.fromText(response.body);
  //     final User user = User.getUser(
  //         token.refreshToken,
  //         email,
  //         AuthClient.Yahoo,
  //         defaultAvatar);

  //     return token;
  //   }
  // }

  Future<Map?> yandexlogin(BuildContext context, {addAccount = false}) async {
    if (await _storage.isLoggedin() && !addAccount) {
      try {
        final User user = await _storage.getCurrUser();
        final String refreshToken = user.refreshToken;
        final token = await getRefreshToken(user.client, refreshToken);
        return {"token": token, "user": user};
      } on AuthException catch (e) {
        Fluttertoast.showToast(msg: e.message);
      } on PlatformException catch (e) {
        if (e.message != null) Fluttertoast.showToast(msg: e.message!);
      }
    } else {
      try {
        final url = Uri.https('oauth.yandex.com', '/authorize', {
          'response_type': 'code',
          'client_id': yandexClientID,
          'redirect_uri': callbackURL,
          'force_confirm': "true"
        });

        final result = await FlutterWebAuth.authenticate(
          url: url.toString(),
          callbackUrlScheme: "onemail",
          preferEphemeral: true,
        );

        final code = Uri.parse(result).queryParameters['code']!;

        showLoaderDialog(context, !addAccount);

        final response = await http.post(
          Uri.parse('https://oauth.yandex.com/token'),
          body: {
            'client_id': yandexClientID,
            'client_secret': yandexClientSecret,
            'grant_type': 'authorization_code',
            'code': code,
          },
        );

        final token = OauthToken.fromText(response.body);

        final UserRes? userRes;

        try {
          userRes = await _userInfo.getUserInfoYANDEX(token.accessToken);

          if (userRes == null) {
            throw AuthException(ExceptionType.Unknown, "Network error");
          }
        } on AuthException catch (e) {
          logError(e.message);
          rethrow;
        } on PlatformException catch (e) {
          logError(e.message!);
          rethrow;
        } on DioError catch (e) {
          logError(e.message);
          rethrow;
        } catch (e) {
          throw AuthException(ExceptionType.Unknown, "Network error");
        }

        List<User> users = await _storage.getUser();

        for (User u in users) {
          if (u.emailAddress == userRes.email) {
            throw AuthException(
                ExceptionType.UserAlreadyExist, "User already Exist");
          }
        }

        final User user = User.getUser(
          refreshToken: token.refreshToken,
          emailAddress: userRes.email,
          emailClient: AuthClient.Yandex,
          photoURL: userRes.photoURL,
          userName: userRes.userName,
          userID: '',
        );
        logSuccess("fine upto here");
        return {"token": token, "user": user};
      } catch (e) {
        throw AuthException(ExceptionType.Unknown, "Network error");
      }
    }
  }
}
