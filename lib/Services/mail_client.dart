import 'package:enough_mail/enough_mail.dart';

class AccountClient {
  MailAccount googleAccount(String userName, OauthToken? token) {
    MailAccount mailAccount = MailAccount.fromManualSettingsWithAuth(
      "gmail.com",
      userName,
      "imap.gmail.com",
      "smtp.gmail.com",
      OauthAuthentication(userName, token),
    );
    return mailAccount;
  }

  MailAccount outlookAccount(String userName, OauthToken? token) {
    MailAccount mailAccount = MailAccount.fromManualSettingsWithAuth(
      "outlook.com",
      userName,
      "imap-mail.outlook.com",
      "smtp-mail.outlook.com",
      OauthAuthentication(userName, token),
    );
    return mailAccount;
  }

  Future<MailAccount> yahooMailAccount(
      String userName, OauthToken? token) async {
    MailAccount mailAccount = MailAccount.fromManualSettingsWithAuth(
      "yahoo.com",
      userName,
      "imap.mail.yahoo.com",
      "smtp.mail.yahoo.com",
      OauthAuthentication(userName, token),
    );

    return mailAccount;
  }

  Future<MailAccount> yandexMailAcount(
      String userName, OauthToken? token) async {
    ClientConfig? clientConfig = await Discover.discover(userName);

    MailAccount mailAccount = MailAccount.fromDiscoveredSettingsWithAuth(
      "yandex.com",
      userName,
      OauthAuthentication(userName, token),
      clientConfig!,
    );
    return mailAccount;
  }
}
