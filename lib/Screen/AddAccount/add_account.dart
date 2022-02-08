import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:oneMail/Ads/native_ads.dart';
import 'package:oneMail/Model/theme_model.dart';
import 'package:oneMail/Model/user_model.dart';
import 'package:oneMail/Screen/Settings/config.dart';
import 'package:oneMail/Services/rating_service.dart';
import 'package:oneMail/Services/email_service.dart';
import 'package:oneMail/Services/storage_service.dart';
import 'package:oneMail/Utils/auth_client.dart';
import 'package:oneMail/Utils/credentails.dart';
import 'package:oneMail/Screen/Homepage/homepage.dart';
import 'package:oneMail/Utils/color_pallet.dart';
import 'package:oneMail/Utils/logger.dart';
import 'package:oneMail/Utils/review_tile.dart';
import 'package:url_launcher/url_launcher.dart';

class AddAccount extends StatefulWidget {
  const AddAccount({Key? key}) : super(key: key);

  @override
  State<AddAccount> createState() => _AddAccountState();
}

class _AddAccountState extends State<AddAccount> {
  final Services services = Get.find(tag: "services");
  final Themes themes = Get.find(tag: "theme");
  final NativeAds nativeAdsTop = NativeAds();
  final NativeAds nativeAdsBottom = NativeAds();
  final Rating rating = Rating();
  InterstitialAd? interstitialAd;

  @override
  void initState() {
    nativeAdsTop.loadAd();
    nativeAdsBottom.loadAd();
    initAds();
    super.initState();
  }

  initAds() {
    InterstitialAd.load(
      adUnitId: kDebugMode
          ? InterstitialAd.testAdUnitId
          : Platform.isAndroid
              ? androidSlashInterstitial
              : iosSplashIntersitital,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          interstitialAd = ad;
          interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (InterstitialAd ad) {
              logError('$ad onAdShowedFullScreenContent.');
              initAds();
            },
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              logError('$ad onAdDismissedFullScreenContent.');
              initAds();
            },
            onAdFailedToShowFullScreenContent:
                (InterstitialAd ad, AdError error) {
              logError('$ad onAdFailedToShowFullScreenContent: $error');
              ad.dispose();
            },
            onAdImpression: (InterstitialAd ad) =>
                logError('$ad impression occurred.'),
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          logError('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  AppBar _appBar() {
    return AppBar(
      backgroundColor: themes.isDark.value
          ? const Color(0xff121212)
          : ColorPallete.primaryColor,
      title: const Text(
        "Add Account",
        style: TextStyle(
          fontSize: 18,
        ),
      ),
      elevation: 0.5,
    );
  }

  Future<void> handleAuth(
    BuildContext context,
    AuthClient client, {
    String email = "",
  }) async {
    try {
      await interstitialAd?.show();
      bool? result = await services.addAccount(
        client,
        email: email,
      );
      if (result == null || !result) {
        Navigator.of(context).pop();
        return;
      }
      final User user = await SecureStorage().getCurrUser();
      Get.put(themes, tag: "theme");
      Get.put(services, tag: "services");
      Get.put(Config(), tag: 'config');

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => HomePage(
            user: user,
            isAddAccount: true,
          ),
        ),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      Get.put(themes, tag: "theme");
      Get.put(services, tag: "services");
      Get.put(Config(), tag: 'config');
    }
  }

  void outlookLogin() async {
    final TextEditingController editingController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    String? result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return SizedBox(
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            title: Text(
              "Enter Email Id",
              style: TextStyle(
                color: themes.isDark.value ? Colors.white : Colors.black,
                fontSize: 17,
              ),
            ),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 8,
                    child: TextFormField(
                      controller: editingController,
                      validator: (String? val) {
                        if (val != null) {
                          if (!val.trim().isEmail) {
                            return "Enter valid Email ID";
                          }
                        }
                      },
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            themes.isDark.value ? Colors.white : Colors.black87,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      cursorColor:
                          themes.isDark.value ? Colors.white : Colors.black,
                      decoration: InputDecoration(
                        filled: true,
                        isDense: true,
                        errorStyle: const TextStyle(
                          fontSize: 15,
                        ),
                        fillColor: themes.isDark.value
                            ? Colors.grey.withOpacity(0.1)
                            : Colors.grey.shade100,
                        border: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  MaterialButton(
                    color: ColorPallete.primaryColor,
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        logSuccess(editingController.text);
                        Navigator.of(context)
                            .pop(editingController.text.trim());
                      }
                    },
                    elevation: 0,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: const Center(
                        child: Text(
                          "Sign in",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result != null && result.trim().isEmail) {
      await handleAuth(
        context,
        AuthClient.Microsoft,
        email: result.trim(),
      );
    }
  }

  showPrivacyDialog() async {
    bool? res = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              themes.isDark.value ? ColorPallete.darkModeColor : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Text(
            "Disclosure",
            style: TextStyle(
              fontSize: 16,
              color: !themes.isDark.value ? Colors.black : Colors.white,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text:
                        "OneMail use and transfer to any other app of information received from Google APIs will adhere to ",
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          themes.isDark.value ? Colors.white : Colors.black87,
                    ),
                  ),
                  TextSpan(
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async => await launch(
                          'https://developers.google.com/terms/api-services-user-data-policy#additional_requirements_for_specific_api_scopes'),
                    text: 'Google API Services User Data Policy',
                    style: TextStyle(
                      fontSize: 15,
                      color: ColorPallete.primaryColor,
                    ),
                  ),
                  TextSpan(
                    text: ", including the Limited Use requirements.",
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          themes.isDark.value ? Colors.white : Colors.black87,
                    ),
                  ),
                ]),
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () async {
                          Navigator.of(context).pop(true);
                        },
                        child: Text(
                          "Continue",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: themes.isDark.value
                                ? Colors.white
                                : ColorPallete.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              )
            ],
          ),
        );
      },
    );

    if (res != null && res == true) {
      await handleAuth(context, AuthClient.Google);
    }
  }

  Widget _emailClientTile(AuthClient client, BuildContext context) {
    TextStyle _style = TextStyle(
      fontSize: 16,
      color: themes.isDark.value ? Colors.white : Colors.black,
    );

    if (client == AuthClient.Google) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: ListTile(
          onTap: () async => showPrivacyDialog(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          tileColor:
              themes.isDark.value ? Colors.grey.withOpacity(0.1) : Colors.white,
          leading: SizedBox(
            child: Image.asset("assets/gmail.png"),
            width: 50,
          ),
          title: Text(
            "Sign in with Google",
            style: _style,
          ),
          trailing: InkWell(
            onTap: () async => showPrivacyDialog(),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: themes.isDark.value
                  ? const Color(0xff121212)
                  : ColorPallete.backgroundColor,
              child: Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: themes.isDark.value
                    ? Colors.white
                    : ColorPallete.primaryColor,
              ),
            ),
          ),
        ),
      );
    } else if (client == AuthClient.Microsoft) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: ListTile(
          onTap: () async {
            outlookLogin();
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          tileColor:
              themes.isDark.value ? Colors.grey.withOpacity(0.1) : Colors.white,
          leading: SizedBox(
            width: 50,
            child: Image.asset(
              "assets/outlook.png",
              height: 50,
            ),
          ),
          title: Text(
            "Sign in with Outlook",
            style: _style,
          ),
          trailing: InkWell(
            onTap: () {
              outlookLogin();
            },
            child: CircleAvatar(
              radius: 15,
              backgroundColor: themes.isDark.value
                  ? const Color(0xff121212)
                  : ColorPallete.backgroundColor,
              child: Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: themes.isDark.value
                    ? Colors.white
                    : ColorPallete.primaryColor,

                // color: ColorPallete.primaryColor,
              ),
            ),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: ListTile(
          onTap: () async => await handleAuth(context, client),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          tileColor:
              themes.isDark.value ? Colors.grey.withOpacity(0.1) : Colors.white,
          leading: SizedBox(
            width: 50,
            child: Image.asset(
              "assets/yandex.png",
              height: 40,
            ),
          ),
          title: Text(
            "Sign in with Yandex",
            style: _style,
          ),
          trailing: InkWell(
            onTap: () async {
              await handleAuth(context, client);
            },
            child: CircleAvatar(
              radius: 15,
              backgroundColor: themes.isDark.value
                  ? const Color(0xff121212)
                  : ColorPallete.backgroundColor,
              child: Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: themes.isDark.value
                    ? Colors.white
                    : ColorPallete.primaryColor,

                // color: ColorPallete.primaryColor,
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: themes.isDark.value
            ? const Color(0xff121212)
            : ColorPallete.backgroundColor,
        appBar: _appBar(),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            nativeAdsBottom.isAdLoaded.value
                ? Container(
                    child: AdWidget(ad: nativeAdsBottom.nativeAd!),
                    height: 72.0,
                    color: themes.isDark.value
                        ? ColorPallete.darkModeColor
                        : Colors.white,
                    alignment: Alignment.center,
                  )
                : Container(
                    height: 0,
                  ),
            !rating.isRatindApplicable.value
                ? Container()
                : reviews(context, rating, themes.isDark.value),
          ],
        ),
        body: Column(
          children: [
            nativeAdsTop.isAdLoaded.value
                ? Container(
                    child: AdWidget(ad: nativeAdsTop.nativeAd!),
                    height: 72.0,
                    color: themes.isDark.value
                        ? ColorPallete.darkModeColor
                        : Colors.white,
                    alignment: Alignment.center,
                  )
                : Container(),
            const SizedBox(
              height: 10,
            ),
            _emailClientTile(AuthClient.Google, context),
            _emailClientTile(AuthClient.Microsoft, context),
            _emailClientTile(AuthClient.Yandex, context),
          ],
        ),
      ),
    );
  }
}
