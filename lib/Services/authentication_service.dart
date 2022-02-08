import 'package:dio/dio.dart';
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:oneMail/Exception/authentication_exception.dart';
import 'package:oneMail/Model/user_model.dart';
import 'package:oneMail/Services/get_user_info.dart';
import 'package:oneMail/Services/mail_client.dart';
import 'package:oneMail/Services/oauth.dart';
import 'package:oneMail/Utils/logger.dart';

class Authentication {
  final AccountClient _accountClient = AccountClient();
  final ImapClient client = ImapClient(isLogEnabled: true);
  final Oauth _oauth = Oauth();
  final GetUserInfo _userInfo = GetUserInfo();
  late MailAccount mailAccount;
  late User user;
  late OauthToken token;

  Future<bool?> getmailAccount({String email = ""}) async {}
}

class OutlookAuthentication extends Authentication {
  final bool addAccount;

  OutlookAuthentication({this.addAccount = false});

  @override
  Future<bool?> getmailAccount({String email = ""}) async {
    BuildContext context = Get.context!;
    try {
      Map? res =
          await _oauth.outlookSignin(context, email, addAccount: addAccount);
      if (res == null) {
        Navigator.of(context).pop();
        return false;
      }
      user = res['user'];
      token = res['token'];
    } on AuthException catch (e) {
      Fluttertoast.showToast(msg: e.message);
      return false;
    } on PlatformException catch (e) {
      Fluttertoast.showToast(msg: e.message!);
      return false;
    } on DioError catch (e) {
      Fluttertoast.showToast(msg: e.message);
      return false;
    } catch (e) {
      Fluttertoast.showToast(msg: "Network error");
      return false;
    }

    await client.connectToServer("imap-mail.outlook.com", 993, isSecure: true);
    await client.authenticateWithOAuth2(user.emailAddress, token.accessToken);
    mailAccount = _accountClient.outlookAccount(user.emailAddress, token);
    return true;
  }
}

class GmailAuthentication extends Authentication {
  final bool addAccount;

  GmailAuthentication({this.addAccount = false});

  @override
  Future<bool?> getmailAccount({String email = ""}) async {
    BuildContext context = Get.context!;
    final Map? res;
    try {
      res = await _oauth.googleSignin(context, addAccount: addAccount);

      if (res == null) {
        Navigator.of(context).pop();
        return false;
      }
      user = res['user'];
      token = res['token'];
    } on AuthException catch (e) {
      Fluttertoast.showToast(msg: e.message);
      return false;
    } on PlatformException catch (e) {
      Fluttertoast.showToast(msg: e.message!);
      return false;
    } on DioError catch (e) {
      Fluttertoast.showToast(msg: e.message);
      return false;
    } catch (e) {
      Fluttertoast.showToast(msg: "Network error");
      return false;
    }
    await client.connectToServer("imap.gmail.com", 993, isSecure: true);
    await client.authenticateWithOAuth2(user.emailAddress, token.accessToken);
    mailAccount = _accountClient.googleAccount(user.emailAddress, token);
    return true;
  }
}

class YandexAuthentication extends Authentication {
  final bool addAccount;

  YandexAuthentication({this.addAccount = false});

  @override
  Future<bool?> getmailAccount({String email = ""}) async {
    BuildContext context = Get.context!;

    try {
      Map? res = await _oauth.yandexlogin(context, addAccount: addAccount);
      if (res == null) {
        Fluttertoast.showToast(msg: "Authenticated failed");
        return false;
      }
      user = res['user'];
      token = res['token'];
    } on AuthException catch (e) {
      Fluttertoast.showToast(msg: e.message);
      return false;
    } on PlatformException catch (e) {
      Fluttertoast.showToast(msg: e.message!);
      return false;
    } on DioError catch (e) {
      Fluttertoast.showToast(msg: e.message);
      return false;
    } catch (e) {
      Fluttertoast.showToast(msg: "Network error");
      return false;
    }

    await client.connectToServer("imap.yandex.com", 993, isSecure: true);
    await client.authenticateWithOAuth2(user.emailAddress, token.accessToken);
    mailAccount =
        await _accountClient.yandexMailAcount(user.emailAddress, token);
    await _userInfo.getUserInfoYANDEX(token.accessToken);
    return true;
  }
}
