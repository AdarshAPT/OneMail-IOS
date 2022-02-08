// ignore_for_file: import_of_legacy_library_into_null_safe

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:oneMail/Model/theme_model.dart';
import 'package:oneMail/Model/user_model.dart';
import 'package:oneMail/Screen/AuthScreen/login_screen.dart';
import 'package:oneMail/Screen/Homepage/homepage.dart';
import 'package:oneMail/Services/storage_service.dart';
import 'package:oneMail/Services/email_service.dart';
import 'package:oneMail/Utils/color_pallet.dart';
import 'package:oneMail/Utils/credentails.dart';
import 'package:oneMail/Utils/logger.dart';
import 'package:splashscreen/splashscreen.dart' as ss;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  InterstitialAd? interstitialAd;
  final Themes theme = Get.find(tag: "theme");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          elevation: 0,
          systemOverlayStyle: Platform.isAndroid
              ? SystemUiOverlayStyle(
                  statusBarColor: ColorPallete.primaryColor,
                  statusBarBrightness: Brightness.light,
                  statusBarIconBrightness: Brightness.light,
                )
              : null,
        ),
      ),
      body: ss.SplashScreen(
        navigateAfterFuture: navigate(),
        image: Image.asset("assets/logo.png"),
        backgroundColor: ColorPallete.primaryColor,
        loaderColor: ColorPallete.primaryColor,
        useLoader: false,
        photoSize: 100.0,
        title: Text(
          "OneMail",
          style: GoogleFonts.poppins(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  initState() {
    InterstitialAd.load(
      adUnitId: kDebugMode
          ? InterstitialAd.testAdUnitId
          : Platform.isAndroid
              ? androidSlashInterstitial
              : iosSplashIntersitital,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) async {
          interstitialAd = ad;
          interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (InterstitialAd ad) {
              logError('$ad onAdShowedFullScreenContent.');
            },
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              logError('$ad onAdDismissedFullScreenContent.');
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent:
                (InterstitialAd ad, AdError error) {
              logError('$ad onAdFailedToShowFullScreenContent: $error');
              ad.dispose();
            },
            onAdImpression: (InterstitialAd ad) =>
                logError('$ad impression occurred.'),
          );
          await interstitialAd?.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          logError('InterstitialAd failed to load: $error');
        },
      ),
    );
    interstitialAd?.show();
    super.initState();
  }

  Future<Widget> navigate() async {
    final Services services = Get.put(Services(), tag: "services");
    bool isloggedIn = await SecureStorage().isLoggedin();
    if (isloggedIn) {
      User user = await SecureStorage().getCurrUser();
      await services.init(user.client);
      return HomePage(user: user);
    }
    await Future.delayed(
      const Duration(seconds: 3),
    );
    return const LoginScreen();
  }
}
