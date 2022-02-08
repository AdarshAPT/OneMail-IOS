import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:oneMail/Utils/credentails.dart';

class NativeAds {
  NativeAd? nativeAd;
  final RxBool isAdLoaded = false.obs;

  NativeAds() {
    init();
  }

  init() {
    nativeAd = NativeAd(
      adUnitId: kDebugMode
          ? NativeAd.testAdUnitId
          : Platform.isAndroid
              ? androidHomeNative
              : iosHomeNative,
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          isAdLoaded.value = true;
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
  }

  void loadAd() async {
    if (nativeAd != null) {
      nativeAd?.load();
    } else {
      init();
      nativeAd?.load();
    }
  }
}
