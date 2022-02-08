import 'dart:convert';
import 'dart:typed_data';

class Address {
  final String? personalName;
  final String email;

  Address(this.personalName, this.email);
}

class Gmail {
  final Map email;
  final String from;
  final String subject;
  final List parts = [];
  final List headers = [];
  final String refreshToken;

  Gmail(
    this.email,
    this.from,
    this.subject,
    this.refreshToken,
  ) {
    headers.addAll(email['payload']['headers']);
    parts.addAll(email['payload']['parts']);
  }

  String get id {
    return email['id'];
  }

  bool get isFlag {
    return true;
  }

  List<Address> getCc() {
    String emailString = '';

    for (Map header in headers) {
      if (header['name'] == 'Cc') {
        emailString = header['value'];
        break;
      }
    }

    if (emailString.isEmpty) return [];

    List<String> emails = emailString.split(',');
    List<Address> address = [];

    for (String email in emails) {
      String? personalName;
      String extractEmail = getEmailRegex(email);
      String extractPersonalName =
          email.replaceAll('<$extractEmail>', '').trim();
      personalName = extractPersonalName.isEmpty ? null : extractPersonalName;
      address.add(Address(personalName, extractEmail));
    }

    return address;
  }

  List<Address> getBcc() {
    String emailString = '';

    for (Map header in headers) {
      if (header['name'] == 'Bcc') {
        emailString = header['value'];
        break;
      }
    }

    if (emailString.isEmpty) return [];

    List<String> emails = emailString.split(',');
    List<Address> address = [];

    for (String email in emails) {
      String? personalName;
      String extractEmail = getEmailRegex(email);
      String extractPersonalName =
          email.replaceAll('<$extractEmail>', '').trim();
      personalName = extractPersonalName.isEmpty ? null : extractPersonalName;
      address.add(Address(personalName, extractEmail));
    }

    return address;
  }

  List<Address> getFrom() {
    String emailString = '';

    for (Map header in headers) {
      if (header['name'] == 'From') {
        emailString = header['value'];
        break;
      }
    }

    if (emailString.isEmpty) return [];

    List<String> emails = emailString.split(',');
    List<Address> address = [];

    for (String email in emails) {
      String? personalName;
      String extractEmail = getEmailRegex(email);
      String extractPersonalName =
          email.replaceAll('<$extractEmail>', '').trim();
      personalName = extractPersonalName.isEmpty ? null : extractPersonalName;
      address.add(Address(personalName, extractEmail));
    }

    return address;
  }

  List<Address> getTo() {
    String emailString = '';

    for (Map header in headers) {
      if (header['name'] == 'To') {
        emailString = header['value'];
        break;
      }
    }

    if (emailString.isEmpty) return [];

    List<String> emails = emailString.split(',');
    List<Address> address = [];

    for (String email in emails) {
      String? personalName;
      String extractEmail = getEmailRegex(email);
      String extractPersonalName =
          email.replaceAll('<$extractEmail>', '').trim();
      personalName = extractPersonalName.isEmpty ? null : extractPersonalName;
      address.add(Address(personalName, extractEmail));
    }

    return address;
  }

  DateTime get time {
    String internalDate = email['internalDate'];

    int internalTime = int.parse(internalDate);

    DateTime time = DateTime.fromMillisecondsSinceEpoch(internalTime);
    return time;
  }

  String? get textPart {
    for (Map part in parts) {
      if (part['mimeType'] == "text/plain") {
        Map? textPartMap = part['body'];
        if (textPartMap == null) return null;

        Uint8List decodeByte = base64Decode(textPartMap["data"]);
        return utf8.decode(decodeByte);
      }
    }

    return null;
  }

  String? get htmlPart {
    if (parts.first['parts'] != null) {
      List part1 = parts.first['parts'];
      for (Map part in part1) {
        if (part['mimeType'] == "text/html") {
          Map? htmlPartMap = part['body'];
          if (htmlPartMap == null) return null;
          Uint8List decodeByte = base64Decode(htmlPartMap["data"]);
          String temp = utf8.decode(decodeByte);
          return temp;
        }
      }
    } else {
      for (Map part in parts) {
        if (part['mimeType'] == "text/html") {
          Map? htmlPartMap = part['body'];
          if (htmlPartMap == null) return null;

          Uint8List decodeByte = base64Decode(htmlPartMap["data"]);
          String temp = utf8.decode(decodeByte);
          return temp;
        }
      }
    }

    return null;
  }

  String get fromEmail {
    RegExp regex = RegExp('(?<=<)(.*?)(?=>)');
    String matched = regex.stringMatch(from)!;
    return matched;
  }

  String get senderName {
    RegExp regex = RegExp('(?<=<)(.*?)(?=>)');
    String matched = regex.stringMatch(from)!;

    return from.replaceAll('<$matched>', '');
  }

  String getEmailRegex(String field) {
    RegExp regex = RegExp('(?<=<)(.*?)(?=>)');
    String matched = regex.stringMatch(field) ?? field;
    return matched;
  }
}
