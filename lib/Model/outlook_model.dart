import 'package:get/get.dart';
import 'package:oneMail/Model/gmail_model.dart';

class OutlookModel {
  final Map email;
  final String from;
  final String subject;
  final String refreshToken;
  final RxBool isFlag = false.obs;

  OutlookModel(this.email, this.from, this.subject, this.refreshToken) {
    isFlag.value = email['flag']['flagStatus'] != 'notFlagged';
  }

  String get id => email['id'];

  DateTime get time => DateTime.parse(email['createdDateTime']);

  String get body => email['body']['content'];

  String get senderName =>
      email['from']['emailAddress']['name'] ??
      email['from']['emailAddress']['address'];

  List<Address> getFrom() {
    List<Address> address = [];

    address.add(
      Address(
        email['from']['emailAddress']['name'],
        email['from']['emailAddress']['address'],
      ),
    );

    return address;
  }

  List<Address> getTo() {
    List<Address> address = [];

    for (Map json in email['toRecipients']) {
      address.add(
        Address(
          json['emailAddress']['name'],
          json['emailAddress']['address'],
        ),
      );
    }
    return address;
  }

  List<Address> getCc() {
    List<Address> address = [];

    for (Map json in email['ccRecipients']) {
      address.add(
        Address(
          json['emailAddress']['name'],
          json['emailAddress']['address'],
        ),
      );
    }
    return address;
  }

  List<Address> getBcc() {
    List<Address> address = [];

    for (Map json in email['bccRecipients']) {
      address.add(
        Address(
          json['emailAddress']['name'],
          json['emailAddress']['address'],
        ),
      );
    }
    return address;
  }
}
