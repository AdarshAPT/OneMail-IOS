import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:iconly/iconly.dart';
import 'package:oneMail/Ads/in_between_interestitial.dart';
import 'package:oneMail/Controller/email_controller.dart';
import 'package:oneMail/Controller/pin_message_controller.dart';
import 'package:oneMail/Model/email_model.dart';
import 'package:oneMail/Model/theme_model.dart';
import 'package:oneMail/Model/user_model.dart';
import 'package:oneMail/Screen/AddAccount/add_account.dart';
import 'package:oneMail/Screen/Compose/compose_email_screen.dart';
import 'package:oneMail/Screen/Downloads/download_screen.dart';
import 'package:oneMail/Screen/Homepage/inbox_screen.dart';
import 'package:oneMail/Screen/Drawer/drawer.dart';
import 'package:oneMail/Screen/Search/search_email_screeen.dart';
import 'package:oneMail/Screen/Settings/config.dart';
import 'package:oneMail/Services/storage_service.dart';
import 'package:oneMail/Services/email_service.dart';
import 'package:oneMail/Utils/auth_client.dart';
import 'package:oneMail/Utils/collect_shared_data.dart';
import 'package:oneMail/Utils/color_pallet.dart';
import 'package:oneMail/Utils/credentails.dart';
import 'package:oneMail/Utils/logger.dart';
import 'package:oneMail/Utils/logging.dart';
import 'package:oneMail/Utils/navigation_route.dart';
import 'package:oneMail/Utils/shared_file.dart';
import 'package:oneMail/Utils/show_snack_bar.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:oneMail/main.dart';
import 'package:path_provider/path_provider.dart';

class HomePage extends StatefulWidget {
  final User user;
  final bool isAddAccount;
  const HomePage({
    Key? key,
    required this.user,
    this.isAddAccount = false,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final GetEmailController _emailController =
      Get.put(GetEmailController(), tag: 'emailController');
  final Services services = Get.find(tag: 'services');
  final Themes themes = Get.find(tag: "theme");
  final PinMessagesController pinMessageController = PinMessagesController();
  final RxInt _currPage = 0.obs;
  final RxString _title = "Inbox".obs;
  final RxList<User> google = <User>[].obs;
  final RxList<User> outlook = <User>[].obs;
  final RxList<User> yandex = <User>[].obs;
  final Config config = Get.put(Config(), tag: 'config');
  final InBetweenInterestitialsAds inBetweenInterestitialsAds =
      InBetweenInterestitialsAds();
  InterstitialAd? interstitialAd;
  InterstitialAd? exitInterstitialAd;

  final RxInt count = 0.obs;

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

  @override
  initState() {
    count.listen((p0) {
      if (p0 == 0) {
        _emailController.selectionModeEnable.value = false;
      }
    });

    initClient();
    getListOfUsers();
    initialisedAds();
    exitInterstitial();
    checkForShare();
    super.initState();
  }

  @override
  void dispose() {
    if (interstitialAd != null) interstitialAd!.dispose();
    if (exitInterstitialAd != null) exitInterstitialAd!.dispose();
    pinMessageController.dispose();
    google.close();
    outlook.close();
    yandex.close();
    if (inBetweenInterestitialsAds.interstitialAd != null) {
      inBetweenInterestitialsAds.interstitialAd!.dispose();
    }
    logSuccess("homepage disposed");
    super.dispose();
  }

  checkForShare() async {
    const _platform = MethodChannel('app.channel.shared.data');
    if (Platform.isAndroid) {
      final shared = await _platform.invokeMethod("getSharedData");
      if (shared != null) {
        final sharedData = await collectSharedData(shared);
        final firstData = sharedData.first;
        if (sharedData.isEmpty) {
          return;
        }
        if (firstData is SharedMailto) {
          logSuccess(firstData.mailto.toString());
          locator<NavigationService>().navigateTo(
            ComposeEmail(
              mailTo: firstData.mailto.toString().split(':').last,
            ),
          );
        } else {
          List<File> files = [];

          for (var file in sharedData) {
            if (file is SharedFile) {
              files.add(file.file);
            } else if (file is SharedBinary) {
              Directory appDocumentsDirectory = await getTemporaryDirectory();
              String appDocumentsPath = appDocumentsDirectory.path;

              final myImagePath = "$appDocumentsPath/${file.filename}";

              File imageFile = File(myImagePath);
              if (!await imageFile.exists()) {
                imageFile.create(recursive: true);
              }

              await imageFile.writeAsBytes(file.data!);

              files.add(imageFile);
            }
          }

          locator<NavigationService>().navigateTo(
            ComposeEmail(
              shareAttachments: files,
            ),
          );
        }
      }
    }
  }

  initClient() async {
    User user = await User.getCurrentUser();
    logSuccess(user.emailAddress);
    if (!widget.isAddAccount) {
      if (user.isGmail) {
        await services.init(AuthClient.Google);
      } else if (user.isOutlook) {
        await services.init(AuthClient.Microsoft);
      } else {
        await services.init(AuthClient.Yandex);
      }
    } else {
      logWarning("hello");
    }

    await _emailController.fetchAllEmails();
  }

  Future<void> handleAuth(BuildContext context, AuthClient client,
      {String email = ""}) async {
    try {
      bool? result = await services.addAccount(client, email: email);
      if (result != null && result) {
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
      } else {
        Navigator.of(context).pop();
        Get.put(themes, tag: "theme");
        Get.put(services, tag: "services");
        Get.put(Config(), tag: 'config');
      }
    } catch (e) {
      Get.put(themes, tag: "theme");
      Get.put(services, tag: "services");
      Get.put(Config(), tag: 'config');
    }
  }

  exitInterstitial() {
    InterstitialAd.load(
      adUnitId: kDebugMode
          ? InterstitialAd.testAdUnitId
          : Platform.isAndroid
              ? androidExitInterstitialKey
              : iosExitInterstitialKey,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          exitInterstitialAd = ad;
          exitInterstitialAd?.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdShowedFullScreenContent: (InterstitialAd ad) {
              logError('$ad onAdShowedFullScreenContent.');
            },
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              logError('$ad onAdDismissedFullScreenContent.');
            },
            onAdFailedToShowFullScreenContent:
                (InterstitialAd ad, AdError error) {
              logError('$ad onAdFailedToShowFullScreenContent: $error');
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

  void showAd() {
    interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        logError('$ad onAdShowedFullScreenContent.');
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        logError('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        logError('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
      },
      onAdImpression: (InterstitialAd ad) =>
          logError('$ad impression occurred.'),
    );
  }

  initialisedAds() async {
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
          showAd();
        },
        onAdFailedToLoad: (LoadAdError error) {
          logError('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  void getListOfUsers() async {
    List<User> users = await getUsers();

    for (User u in users) {
      if (u.isGmail) {
        google.add(u);
      } else if (u.isOutlook) {
        outlook.add(u);
      }
      if (u.isYandex) {
        yandex.add(u);
      }
    }
  }

  Widget getCurrentPage() {
    if (_currPage.value == 0) {
      return InboxScreen(
        user: widget.user,
        mailbox: null,
        count: count,
      );
    } else {
      return const DownloadScreen();
    }
  }

  Widget _bottonNavigationBar() => BottomNavigationBar(
        backgroundColor:
            themes.isDark.value ? ColorPallete.darkModeColor : Colors.white,
        selectedItemColor: ColorPallete.primaryColor,
        elevation: 8,
        selectedFontSize: 12.0,
        unselectedFontSize: 12.0,
        unselectedItemColor: themes.currTheme.unselectedWidgetColor,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currPage.value,
        onTap: (index) {
          if (index == 0) {
            _title.value = "Inbox";
          } else {
            _title.value = "Downloads";
          }
          _currPage.value = index;
        },
        items: tabIcon,
      );

  List<BottomNavigationBarItem> tabIcon = const [
    BottomNavigationBarItem(
        icon: Icon(
          IconlyBold.home,
        ),
        label: "Inbox"),
    BottomNavigationBarItem(
      icon: Icon(
        IconlyBold.download,
      ),
      label: "Downloads",
    ),
  ];

  Widget showEmailTab(User currUser, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        google.isNotEmpty
            ? Row(
                children: [
                  Image.asset(
                    "assets/gmail.png",
                    height: 35,
                  ),
                  Text(
                    "Gmail",
                    style: TextStyle(
                      color: themes.isDark.value
                          ? Colors.white
                          : Colors.grey.shade700,
                      fontSize: 16,
                    ),
                  )
                ],
              )
            : Container(),
        for (User user in google) ...{
          emailTiles(user, currUser, isDark),
        },
        outlook.isNotEmpty
            ? Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: Image.asset(
                      "assets/outlook.png",
                      height: 35,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    "Outlook",
                    style: TextStyle(
                      color: themes.isDark.value
                          ? Colors.white
                          : Colors.grey.shade700,
                      fontSize: 16,
                    ),
                  )
                ],
              )
            : Container(),
        for (User user in outlook) ...{
          emailTiles(user, currUser, isDark),
        },
        yandex.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(left: 11.0),
                child: Row(
                  children: [
                    Image.asset(
                      "assets/yandex1.png",
                      height: 25,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      "Yandex",
                      style: TextStyle(
                        color: themes.isDark.value
                            ? Colors.white
                            : Colors.grey.shade700,
                        fontSize: 16,
                      ),
                    )
                  ],
                ),
              )
            : Container(),
        for (User user in yandex) ...{
          emailTiles(user, currUser, isDark),
        }
      ],
    );
  }

  Widget emailTiles(User user, User currUser, bool isDark) {
    return ListTile(
      onTap: () async {
        if (currUser.emailAddress != user.emailAddress) {
          interstitialAd?.show();
        }
        handleAccountChange(user, themes, currUser, context);
      },
      dense: true,
      leading: Icon(
        Feather.user,
        color: themes.isDark.value ? Colors.white : Colors.grey.shade700,
      ),
      title: Text(
        user.emailAddress,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget showModalSheetContent(bool isDark, User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          showEmailTab(user, isDark),
          ListTile(
            dense: true,
            onTap: () async {
              try {
                await inBetweenInterestitialsAds.interstitialAd?.show();
              } catch (e) {
                logError(e.toString());
              }
              Get.put(themes, tag: "theme");
              locator<NavigationService>().navigateTo(const AddAccount());
            },
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Ionicons.add_circle_outline,
                      color: ColorPallete.primaryColor,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      "Add an Account",
                      style: TextStyle(
                        color: ColorPallete.primaryColor,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () async {
                        interstitialAd?.show();
                        await handleAuth(context, AuthClient.Google);
                      },
                      child: Image.asset(
                        "assets/gmail.png",
                        height: 35,
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        await interstitialAd?.show();
                        await handleAuth(context, AuthClient.Yandex);
                      },
                      child: Image.asset(
                        "assets/yandex1.png",
                        height: 25,
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    InkWell(
                      onTap: () async {
                        await interstitialAd?.show();
                        outlookLogin();
                      },
                      child: Image.asset(
                        "assets/outlook.png",
                        height: 35,
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  _showBottomSheet(BuildContext context, bool isDark, User user) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          themes.isDark.value ? ColorPallete.darkModeColor : Colors.white,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      builder: (context) {
        return showModalSheetContent(isDark, user);
      },
    );
  }

  AppBar _customAppBar(context) {
    return AppBar(
      elevation: 0.5,
      backgroundColor: themes.isDark.value
          ? ColorPallete.darkModeColor
          : ColorPallete.primaryColor,
      systemOverlayStyle: Platform.isAndroid
          ? SystemUiOverlayStyle(
              statusBarColor: !themes.isDark.value
                  ? ColorPallete.primaryColor
                  : const Color(0xff121212),
              statusBarBrightness: Brightness.light,
              statusBarIconBrightness: Brightness.light,
            )
          : null,
      title: Text(
        _title.value,
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
      actions: [
        !_emailController.selectionModeEnable.value
            ? Row(
                children: [
                  _currPage.value == 0
                      ? IconButton(
                          onPressed: () =>
                              locator<NavigationService>().navigateTo(
                            const SearchPage(),
                          ),
                          icon: const Icon(Ionicons.search),
                        )
                      : Container(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: InkWell(
                        onTap: () => _showBottomSheet(
                            context, themes.isDark.value, widget.user),
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: CachedNetworkImage(
                            imageUrl: widget.user.userPhotoURL,
                            fit: BoxFit.contain,
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  IconButton(
                    onPressed: () {
                      _emailController.selectionModeEnable.value = false;
                      for (Email email in _emailController.emails) {
                        email.isSelect.value = false;
                      }
                      count.value = 0;
                    },
                    icon: const Icon(Entypo.cross),
                  ),
                  InkWell(
                    onTap: () {
                      pinMessageController
                          .addPinMessage(_emailController.emails);
                      _emailController.selectionModeEnable.value = false;
                    },
                    child: SvgPicture.asset(
                      "assets/pin.svg",
                      height: 22,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      try {
                        await _emailController.services
                            .deleteAllMails(_emailController);
                        count.value = 0;
                      } catch (e, stackTrace) {
                        logToDevice(
                          "Homepage",
                          "deleteAllMails",
                          e.toString(),
                          stackTrace,
                        );
                      }
                      _emailController.selectionModeEnable.value = false;
                    },
                    icon: const Icon(
                      Feather.trash,
                    ),
                  )
                ],
              )
      ],
    );
  }

  FloatingActionButton _floatingActionButton(BuildContext context) =>
      FloatingActionButton(
        onPressed: () => locator<NavigationService>().navigateTo(
          const ComposeEmail(),
        ),
        backgroundColor: ColorPallete.primaryColor,
        child: const Icon(
          IconlyBold.edit,
          color: Colors.white,
        ),
      );

  Future<bool> exitDialog() async {
    bool? res = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
            backgroundColor:
                themes.isDark.value ? ColorPallete.darkModeColor : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            title: Text(
              "Do you want Exit?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                // fontWeight: FontWeight.w600,
                color: !themes.isDark.value ? Colors.black : Colors.white,
              ),
            ),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                MaterialButton(
                  elevation: 0,
                  splashColor: Colors.transparent,
                  hoverElevation: 0,
                  highlightColor: Colors.transparent,
                  color: ColorPallete.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                    5,
                  )),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text(
                    "Yes",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                MaterialButton(
                  color: ColorPallete.primaryColor,
                  elevation: 0,
                  splashColor: Colors.transparent,
                  hoverElevation: 0,
                  highlightColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                    5,
                  )),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text(
                    "No",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ));
      },
    );

    if (res != null && res == true) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => WillPopScope(
        onWillPop: () async {
          await exitInterstitialAd?.show();
          bool res = await exitDialog();
          return res;
        },
        child: Scaffold(
          appBar: _customAppBar(context),
          backgroundColor:
              themes.isDark.value ? ColorPallete.darkModeColor : Colors.white,
          floatingActionButton: _floatingActionButton(context),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          drawer: drawer(
              context, _emailController.mailboxList, widget.user, themes),
          bottomNavigationBar: _bottonNavigationBar(),
          body: getCurrentPage(),
        ),
      ),
    );
  }
}
