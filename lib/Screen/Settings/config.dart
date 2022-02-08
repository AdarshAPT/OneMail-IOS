import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Config {
  final RxBool isOpenInApp = true.obs;

  Future<void> init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    bool? isDisabled = prefs.getBool("isOpenInApp");

    if (isDisabled != null && isDisabled) {
      isOpenInApp.value = false;
    } else {
      isOpenInApp.value = true;
    }
  }

  Future<void> toggle(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isOpenInApp", value);
    isOpenInApp.value = value;
  }
}
