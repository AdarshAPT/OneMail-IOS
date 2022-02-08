import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:oneMail/Screen/Settings/config.dart';
import 'package:oneMail/Services/remoteConfig_service.dart';
import 'package:oneMail/Utils/navigation_route.dart';
import '../main.dart';

Future<void> setupLocator() async {
  await Firebase.initializeApp();
  await MobileAds.instance.initialize();

  locator.registerLazySingleton(() => NavigationService());
  locator.registerLazySingleton(() => RemoteConfigService());
  Get.put(Config(), tag: "config");
}
