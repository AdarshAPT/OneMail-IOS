import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:oneMail/Screen/Settings/config.dart';
import 'package:oneMail/Services/remoteConfig_service.dart';
import 'package:oneMail/Utils/navigation_route.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

Future<void> setupLocator() async {
  final SharedPreferences preferences = await SharedPreferences.getInstance();

  if (!preferences.containsKey("signature")) {
    await preferences.setString("signature", "\n\n---\nSent with OneMail");
  }
  await Firebase.initializeApp();
  await MobileAds.instance.initialize();

  locator.registerLazySingleton(() => NavigationService());
  locator.registerLazySingleton(() => RemoteConfigService());
  Get.put(Config(), tag: "config");
}
