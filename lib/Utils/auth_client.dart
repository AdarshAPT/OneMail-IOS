// ignore_for_file: constant_identifier_names

enum AuthClient {
  Google,
  Microsoft,
  Yandex,
}

String getIMAPSetting(AuthClient emailClient) {
  switch (emailClient) {
    case AuthClient.Google:
      return "imap.gmail.com";
    case AuthClient.Microsoft:
      return "imap-mail.outlook.com";
    case AuthClient.Yandex:
      return "imap.yandex.com";
    default:
      throw ("Invalid Email Client");
  }
}

String getSMTPConfig(AuthClient emailClient) {
  switch (emailClient) {
    case AuthClient.Google:
      return "smtp.gmail.com";
    case AuthClient.Microsoft:
      return "smtp-mail.outlook.com";
    case AuthClient.Yandex:
      return "smtp.yandex.com";
    default:
      throw ("Invalid Email Client");
  }
}
