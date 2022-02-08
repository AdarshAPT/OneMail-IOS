import 'dart:convert';
import 'package:oneMail/Services/storage_service.dart';
import 'package:oneMail/Utils/auth_client.dart';

class User {
  final String userName;
  final String emailAddress;
  final AuthClient client;
  final String refreshToken;
  final String imapSetting;
  final String smtpSetting;
  final String userPhotoURL;
  final String userID;

  User({
    required this.userName,
    required this.emailAddress,
    required this.client,
    required this.refreshToken,
    required this.imapSetting,
    required this.smtpSetting,
    required this.userPhotoURL,
    required this.userID,
  });

  factory User.fromJSON(String json) {
    Map userConfig = jsonDecode(json);

    return User(
      userName: userConfig['userName'],
      emailAddress: userConfig['emailAddress'],
      client: AuthClient.values[userConfig['client']],
      refreshToken: userConfig['refreshToken'],
      imapSetting: userConfig['imapSetting'],
      smtpSetting: userConfig['smtpSetting'],
      userPhotoURL: userConfig['userPhotoURL'],
      userID: userConfig['userID'],
    );
  }

  static User getUser({
    required String refreshToken,
    required String emailAddress,
    required String userName,
    required AuthClient emailClient,
    required String photoURL,
    required String userID,
  }) {
    String imapConfig = getIMAPSetting(emailClient);
    String smtpConfig = getSMTPConfig(emailClient);
    return User(
      userName: userName,
      emailAddress: emailAddress,
      client: emailClient,
      refreshToken: refreshToken,
      imapSetting: imapConfig,
      smtpSetting: smtpConfig,
      userPhotoURL: photoURL,
      userID: userID,
    );
  }

  @override
  String toString() {
    Map userConfig = {
      "userName": userName,
      "refreshToken": refreshToken,
      "emailAddress": emailAddress,
      "client": client.index,
      "imapSetting": imapSetting,
      "smtpSetting": smtpSetting,
      "userPhotoURL": userPhotoURL,
      "userID": userID,
    };

    return jsonEncode(userConfig);
  }

  static Future<User> getCurrentUser() async {
    final SecureStorage _storage = SecureStorage();
    User user = await _storage.getCurrUser();
    return user;
  }

  bool get isGmail => client == AuthClient.Google;

  bool get isOutlook => client == AuthClient.Microsoft;

  bool get isYandex => client == AuthClient.Yandex;
}
