import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:oneMail/Utils/credentails.dart';
import 'package:oneMail/Utils/logger.dart';

class BannerAds {
  BannerAd? bannerAd;

  BannerAds() {
    init();
  }

  init() {
    bannerAd = BannerAd(
      adUnitId: kDebugMode
          ? Platform.isAndroid
              ? androidBanner
              : iosBanner
          : BannerAd.testAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: listener,
    );
  }

  final BannerAdListener listener = BannerAdListener(
    onAdLoaded: (Ad ad) => logWarning('Ad loaded.'),
    onAdFailedToLoad: (Ad ad, LoadAdError error) {
      ad.dispose();
      logWarning('Ad failed to load: $error');
    },
    onAdOpened: (Ad ad) => logWarning('Ad opened.'),
    onAdClosed: (Ad ad) => logWarning('Ad closed.'),
    onAdImpression: (Ad ad) => logWarning('Ad impression.'),
  );

  void loadAd() async {
    if (bannerAd != null) {
      bannerAd?.load();
    } else {
      init();
      bannerAd?.load();
    }
  }
}
