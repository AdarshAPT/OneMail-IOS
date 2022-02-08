import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:oneMail/Controller/base_controller.dart';
import 'package:oneMail/Model/email_model.dart';
import 'package:oneMail/Model/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinMessagesController extends GetxController with BaseController {
  Future<void> getPinMessage() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final User user = await User.getCurrentUser();

    if (preferences.containsKey("pinMessage${user.emailAddress}")) {
      List<String> list =
          preferences.getStringList("pinMessage${user.emailAddress}")!;

      Map<DateTime, Email> hashMap = {};

      for (int i = 0; i < list.length; i++) {
        Email email = Email.fromJSON(jsonDecode(list[i]));
        hashMap[email.mimeMessage.decodeDate()!] = email;
      }

      emails.addAll(hashMap.values);
    }

    emails.sort((b, a) =>
        a.mimeMessage.decodeDate()!.compareTo(b.mimeMessage.decodeDate()!));
  }

  Future<void> addPinMessage(List<Email> emails) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final User user = await User.getCurrentUser();
    List<String> stringifyEmail = [];

    if (preferences.containsKey("pinMessage${user.emailAddress}")) {
      stringifyEmail
          .addAll(preferences.getStringList("pinMessage${user.emailAddress}")!);
    }

    for (int i = 0; i < emails.length; i++) {
      if (emails[i].isSelect.value) {
        stringifyEmail.add(emails[i].toString());
        emails[i].isSelect.value = false;
      }
    }

    Map<DateTime, Email> hashMap = {};

    for (int i = 0; i < stringifyEmail.length; i++) {
      Email email = Email.fromJSON(jsonDecode(stringifyEmail[i]));
      hashMap[email.mimeMessage.decodeDate()!] = email;
    }

    List<String> finalRes = hashMap.values.map((e) => e.toString()).toList();

    await preferences.setStringList("pinMessage${user.emailAddress}", finalRes);
    Fluttertoast.showToast(msg: "Mail pinned successfully");
  }

  Future<void> deletePinMessage(int index) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final User user = await User.getCurrentUser();

    emails.removeAt(index);

    List<String> stringList =
        emails.map<String>((element) => element.toString()).toList();

    await preferences.setStringList(
        "pinMessage${user.emailAddress}", stringList);
  }

  Future<void> deletePinMessages() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final User user = await User.getCurrentUser();

    List<Email> deleteIndex = [];

    for (int i = 0; i < emails.length; i++) {
      if (emails[i].isSelect.value) {
        deleteIndex.add(emails[i]);
      }
    }

    for (Email email in deleteIndex) {
      emails.remove(email);
    }

    List<String> stringList =
        emails.map<String>((element) => element.toString()).toList();

    await preferences.setStringList(
        "pinMessage${user.emailAddress}", stringList);
    Fluttertoast.showToast(msg: "Mail unpinned successfully");
  }

  Future<void> addIndividualPinMessage(Email email) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final User user = await User.getCurrentUser();
    List<String> stringifyEmail = [];

    if (preferences.containsKey("pinMessage${user.emailAddress}")) {
      stringifyEmail
          .addAll(preferences.getStringList("pinMessage${user.emailAddress}")!);
    }

    stringifyEmail.add(email.toString());

    Map<DateTime, Email> hashMap = {};

    for (int i = 0; i < stringifyEmail.length; i++) {
      Email email = Email.fromJSON(jsonDecode(stringifyEmail[i]));
      hashMap[email.mimeMessage.decodeDate()!] = email;
    }

    List<String> finalRes = hashMap.values.map((e) => e.toString()).toList();

    await preferences.setStringList("pinMessage${user.emailAddress}", finalRes);
    Fluttertoast.showToast(msg: "Mail pinned successfully");
  }
}
