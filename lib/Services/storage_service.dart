import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oneMail/Exception/authentication_exception.dart';
import 'package:oneMail/Model/theme_model.dart';
import 'package:oneMail/Model/user_model.dart';
import 'package:oneMail/Services/email_service.dart';
import 'package:oneMail/Screen/AuthScreen/login_screen.dart';
import 'package:oneMail/Screen/Homepage/homepage.dart';
import 'package:oneMail/Utils/logger.dart';
import 'package:oneMail/Utils/navigation_route.dart';
import 'package:oneMail/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class SecureStorage {
  Future<bool> isLoggedin() async {
    final SharedPreferences _pref = await SharedPreferences.getInstance();

    if (_pref.containsKey("islogged")) {
      if (_pref.getBool("islogged")!) {
        return true;
      } else {
        return false;
      }
    }
    return false;
  }

  Future<void> setNewUser(User user) async {
    final SharedPreferences _pref = await SharedPreferences.getInstance();
    List<String> users = _pref.getStringList("users") ?? [];
    List<User> userList = users.map<User>((e) => User.fromJSON(e)).toList();
    userList.add(user);
    var uniques = <String, User>{};
    for (User u in userList) {
      uniques[u.emailAddress] = u;
    }

    List<String> str = [];

    for (User map in uniques.values) {
      str.add(map.toString());
    }
    await _pref.setStringList("users", str);
  }

  Future<User> getCurrUser() async {
    String email = (await getEmailAddress())!;
    final SharedPreferences _pref = await SharedPreferences.getInstance();

    List<String> allUser = (_pref.getStringList("users")) ?? [];
    List<User> users =
        allUser.map<User>((json) => User.fromJSON(json)).toList();

    for (User u in users) {
      if (u.emailAddress == email) {
        return u;
      }
    }

    throw AuthException(ExceptionType.UserNotFound, "User not found");
  }

  Future<void> removeCurrUser(BuildContext context) async {
    final SharedPreferences _pref = await SharedPreferences.getInstance();
    final User user = await getCurrUser();
    final List<String> users = _pref.getStringList("users") ?? [];

    if (user.isOutlook && Platform.isAndroid) {
      await Workmanager().cancelByUniqueName(user.userID);
    }

    List<User> userList = users.map<User>((e) => User.fromJSON(e)).toList();

    userList
        .removeWhere((element) => element.emailAddress == user.emailAddress);

    if (userList.isEmpty) {
      await _pref.clear();
      logSuccess("shared preference has been cleared");
      Get.deleteAll(force: true);
      Navigator.of(context).pop();
      locator<NavigationService>().navigateToReplacement(const LoginScreen());
      return;
    }

    List<String> str = [];

    for (User map in userList) {
      str.add(map.toString());
    }
    await _pref.setStringList("users", str);
    await _pref.setStringList('cacheMail${user.emailAddress}', []);
    await setEmailAddress(userList.first.emailAddress);
    Get.put(Services(), tag: "services");

    locator<NavigationService>().navigateToReplacement(
      HomePage(
        user: userList.first,
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    await Get.deleteAll(force: true);
    await removeCurrUser(context);
    Themes().dispose();
    Get.put(Themes(), tag: "theme");
  }

  Future<void> setLoggedin() async {
    final SharedPreferences _pref = await SharedPreferences.getInstance();
    await _pref.setBool("islogged", true);
  }

  Future<String?> getEmailAddress() async {
    final SharedPreferences _pref = await SharedPreferences.getInstance();
    return _pref.getString("email");
  }

  Future<void> setEmailAddress(String email) async {
    final SharedPreferences _pref = await SharedPreferences.getInstance();
    _pref.setString("email", email);
  }

  Future<List<User>> getUser() async {
    final SharedPreferences _pref = await SharedPreferences.getInstance();
    List<User> users = [];

    List<String> listofstringifyUser = _pref.getStringList("users") ?? [];

    for (String user in listofstringifyUser) {
      users.add(User.fromJSON(user));
    }

    return users;
  }

  Future<bool> isDarkMode() async {
    final SharedPreferences _pref = await SharedPreferences.getInstance();

    if (_pref.containsKey("isDark")) {
      bool isDark = _pref.getBool("isDark")!;
      return isDark;
    }
    return false;
  }

  Future<void> setDarkMode(bool isDark) async {
    final SharedPreferences _pref = await SharedPreferences.getInstance();
    await _pref.setBool("isDark", isDark);
  }

  Future<String?> getHistoryID(User user) async {
    final SharedPreferences _pref = await SharedPreferences.getInstance();
    String? historyId = _pref.getString("historyID${user.emailAddress}");

    return historyId;
  }

  Future<void> setHistoryID(User user, String historyID) async {
    final SharedPreferences _pref = await SharedPreferences.getInstance();
    await _pref.setString("historyID${user.emailAddress}", historyID);
  }

  Future<void> setOutlookToken(String email, String token) async {
    final SharedPreferences _pref = await SharedPreferences.getInstance();
    await _pref.setString('OutlookToken$email', token);
    logSuccess("token set successfully");
  }

  Future<String?> getOutlookToken(String email) async {
    final SharedPreferences _pref = await SharedPreferences.getInstance();
    String? token = _pref.getString('OutlookToken$email');
    return token;
  }
}
