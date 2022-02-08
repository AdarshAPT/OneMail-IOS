import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:oneMail/Utils/credentails.dart';
import 'package:oneMail/Utils/logger.dart';

class InBetweenInterestitialsAds {
  InterstitialAd? interstitialAd;

  InBetweenInterestitialsAds() {
    init();
  }

  init() {
    InterstitialAd.load(
      adUnitId: kDebugMode
          ? InterstitialAd.testAdUnitId
          : Platform.isAndroid
              ? androidAllPageInterstitial
              : iosAllPageIntersitital,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          interstitialAd = ad;
          interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (InterstitialAd ad) {
              logWarning('$ad onAdShowedFullScreenContent.');
            },
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              logWarning('$ad onAdDismissedFullScreenContent.');
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent:
                (InterstitialAd ad, AdError error) {
              logWarning('$ad onAdFailedToShowFullScreenContent: $error');
              ad.dispose();
            },
            onAdImpression: (InterstitialAd ad) =>
                logWarning('$ad impression occurred.'),
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          logWarning('InterstitialAd failed to load: $error');
        },
      ),
    );
  }
}
