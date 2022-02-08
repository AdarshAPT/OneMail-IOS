import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oneMail/Services/storage_service.dart';
import 'package:oneMail/Utils/color_pallet.dart';

class Themes extends GetxController {
  final RxBool isDark = false.obs;

  Themes() {
    init();
  }

  init() async {
    isDark.value = await SecureStorage().isDarkMode();
  }

  Future<bool> isDarkMode() async {
    bool isDark = await SecureStorage().isDarkMode();
    return isDark;
  }

  static final darkMode = ThemeData.dark().copyWith(
    primaryColor: ColorPallete.primaryColor,
    dialogBackgroundColor: const Color(0xff121212),
    canvasColor: const Color(0xff121212),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: ColorPallete.primaryColor,
    ),
    buttonTheme: const ButtonThemeData(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    ),
    applyElevationOverlayColor: false,
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(elevation: MaterialStateProperty.all(0))),
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
    backgroundColor: const Color(0xff121212),
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: Colors.grey.withOpacity(0.2),
      cursorColor: Colors.white,
      selectionHandleColor: Colors.white,
    ),
    textTheme: Platform.isAndroid
        ? GoogleFonts.workSansTextTheme().apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          )
        : null,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xff121212),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
      ),
      iconTheme: IconThemeData(
        color: Colors.white,
      ),
    ),
  );

  static final lightMode = ThemeData.light().copyWith(
    primaryColor: ColorPallete.primaryColor,
    canvasColor: Colors.white,
    dialogBackgroundColor: Colors.white,
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: ColorPallete.primaryColor,
    ),
    textTheme: Platform.isAndroid
        ? GoogleFonts.workSansTextTheme().apply(
            bodyColor: Colors.black87,
            displayColor: Colors.black87,
          )
        : null,
    iconTheme: const IconThemeData(color: Colors.black),
    backgroundColor: Colors.white,
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: ColorPallete.primaryColor.withOpacity(0.2),
      cursorColor: ColorPallete.primaryColor,
      selectionHandleColor: ColorPallete.primaryColor,
    ),
    appBarTheme: AppBarTheme(
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
      ),
      backgroundColor: ColorPallete.primaryColor,
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
    ),
  );

  toggle(bool isDark) async {
    this.isDark.value = isDark;
    await SecureStorage().setDarkMode(isDark);
  }

  ThemeData get currTheme => isDark.value ? darkMode : lightMode;
}
