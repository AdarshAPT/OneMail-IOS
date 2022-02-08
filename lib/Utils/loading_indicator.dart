import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oneMail/Model/theme_model.dart';

import 'color_pallet.dart';

showLoaderDialog(BuildContext context, bool isLogin) {
  final Themes theme = Get.find(tag: 'theme');

  AlertDialog alert = AlertDialog(
    backgroundColor: isLogin
        ? Colors.white
        : theme.isDark.value
            ? ColorPallete.darkModeColor
            : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    ),
    content: FittedBox(
      child: Row(
        children: [
          Platform.isAndroid
              ? Transform.scale(
                  scale: 0.6,
                  child: const CircularProgressIndicator(),
                )
              : const CupertinoActivityIndicator(),
          Container(
            margin: const EdgeInsets.only(left: 10),
            child: Text(
              "Fetching Account Details",
              style: TextStyle(
                color: isLogin
                    ? Colors.black
                    : theme.isDark.value
                        ? Colors.white
                        : Colors.black,
              ),
            ),
          ),
        ],
      ),
    ),
  );
  showDialog(
    barrierDismissible: false,
    context: context,
    useRootNavigator: true,
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async => false,
        child: alert,
      );
    },
  );
}
