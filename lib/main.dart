import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_admob_app_open/flutter_admob_app_open.dart';
import 'package:get/get.dart';
import 'package:oneMail/Controller/email_controller.dart';
import 'package:oneMail/Model/gmail_model.dart';
import 'package:oneMail/Model/outlook_model.dart';
import 'package:oneMail/Notification/gmailAPI.dart';
import 'package:oneMail/Notification/outlookAPI.dart';
import 'package:oneMail/Screen/Compose/compose_email_screen.dart';
import 'package:oneMail/Screen/Details/gmail_details.dart';
import 'package:oneMail/Screen/Details/outlook_details.dart';
import 'package:oneMail/Screen/Splash%20Screen/splash_screen.dart';
import 'package:oneMail/Services/storage_service.dart';
import 'package:oneMail/Utils/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'Model/theme_model.dart';
import 'Services/locator_service.dart';
import 'Utils/collect_shared_data.dart';
import 'Utils/credentails.dart';
import 'Utils/navigation_route.dart';
import 'package:quick_actions/quick_actions.dart';
import 'Utils/shared_file.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Map json = jsonDecode(message.data['data']);

  if (json['outlook']) {
    final OutlookAPI outlookAPI = OutlookAPI();

    outlookAPI.notifyOutlook(json['resource'], json['emailAddress']);
  } else if (json['gmail']) {
    final GmailAPI gmailAPI = GmailAPI();
    try {
      await gmailAPI.notifyGmail(json['historyId'], json['emailAddress']);
    } catch (e) {
      logError(e.toString());
    }
  }

  try {
    final GetEmailController emailController = Get.find(tag: 'emailController');
    emailController.pullToRefresh();
  } catch (e) {
    logError(e.toString());
    logError("error occured while fetching new email.");
  }
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final response = await http.post(
      Uri.parse('https://login.microsoftonline.com/common/oauth2/v2.0/token'),
      body: {
        'client_id': outlookClientID,
        'scope': 'Mail.Read Mail.ReadWrite',
        'refresh_token': inputData!['refreshToken'],
        'grant_type': 'refresh_token',
      },
    );

    final OauthToken? token = OauthToken.fromText(response.body);

    if (token == null) return Future.value(false);

    Map body = {
      "changeType": "created",
      "notificationUrl": "https://emailgo.apyhi.com/outlook/push/notification",
      "resource": "/me/mailfolders('inbox')/messages",
      "expirationDateTime":
          (DateTime.now().add(const Duration(hours: 10))).toIso8601String() +
              'Z',
    };

    await Dio().post(
      "https://graph.microsoft.com/v1.0/subscriptions",
      options: Options(headers: {
        "Authorization": "Bearer ${token.accessToken}",
      }),
      data: body,
    );
    return Future.value(true);
  });
}

GetIt locator = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  AdRequestAppOpen targetingInfo = const AdRequestAppOpen();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen((event) {
    try {
      final GetEmailController emailController =
          Get.find(tag: 'emailController');
      emailController.pullToRefresh();
    } catch (e) {
      logError("error occured while fetching new email.");
    }
  });

  Workmanager().initialize(
    callbackDispatcher,
  );

  /// Init App Open Ads
  await FlutterAdmobAppOpen.instance.initialize(
    appAppOpenAdUnitId: kDebugMode
        ? FlutterAdmobAppOpen.testAppId
        : Platform.isAndroid
            ? androidAppOpen
            : iosAppOpen,
    targetingInfo: targetingInfo,
  );

  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });

  AwesomeNotifications().initialize(
    'resource://drawable/ic_stat_email',
    [
      NotificationChannel(
        channelKey: 'oneMail',
        channelName: 'one Mail',
        channelDescription: 'Notification channel for basic tests',
        playSound: true,
        soundSource: 'resource://raw/pop',
        ledColor: Colors.white,
      ),
    ],
    debug: true,
  );

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  const QuickActions quickActions = QuickActions();
  quickActions.initialize(
    (shortcutType) async {
      GetIt locator = GetIt.instance;
      bool isLoggedIn = await SecureStorage().isLoggedin();
      if (shortcutType == 'action_main' && isLoggedIn) {
        locator<NavigationService>().navigateTo(
          const ComposeEmail(),
        );
      }
    },
  );

  quickActions.setShortcutItems(
    <ShortcutItem>[
      const ShortcutItem(
        type: 'action_main',
        localizedTitle: 'Compose Mail',
        icon: 'ic_stat_email',
      ),
    ],
  );

  AwesomeNotifications().actionStream.listen(
    (ReceivedNotification receivedNotification) async {
      GetIt locator = GetIt.instance;

      Map response = receivedNotification.toMap();
      logSuccess(receivedNotification.toMap().toString());

      if (response['buttonKeyPressed'] == "delete") {
        if (receivedNotification.payload != null) {
          if (receivedNotification.payload!['client'] == 'gmail') {
            final GmailAPI gmailAPI = GmailAPI();
            String messageID = receivedNotification.payload!['messageID']!;
            String refreshToken =
                receivedNotification.payload!['refreshToken']!;
            await gmailAPI.deleteEmail(messageID, refreshToken);
          } else if (receivedNotification.payload!['client'] == 'outlook') {
            final OutlookAPI outlookAPI = OutlookAPI();
            String messageID = receivedNotification.payload!['messageID']!;
            String refreshToken =
                receivedNotification.payload!['refreshToken']!;
            await outlookAPI.deleteEmail(messageID, refreshToken);
          }
        }
        return;
      } else if (response['buttonKeyPressed'] == "reply") {
        String from = receivedNotification.payload!['from']!;
        String subject = receivedNotification.payload!['subject']!;

        locator<NavigationService>().navigateTo(
          ComposeEmail(
            isReply: true,
            subject: subject,
            to: [from],
          ),
        );
        return;
      }

      if (receivedNotification.payload!['client'] == 'gmail') {
        locator<NavigationService>().navigateTo(
          GmailDetails(
            email: Gmail(
              jsonDecode(receivedNotification.payload!['email']!),
              receivedNotification.payload!['fromField']!,
              receivedNotification.payload!['subject']!,
              receivedNotification.payload!['refreshToken']!,
            ),
          ),
        );
      } else if (receivedNotification.payload!['client'] == 'outlook') {
        locator<NavigationService>().navigateTo(
          OutlookDetails(
            email: OutlookModel(
              jsonDecode(receivedNotification.payload!['email']!),
              receivedNotification.payload!['fromField']!,
              receivedNotification.payload!['subject']!,
              receivedNotification.payload!['refreshToken']!,
            ),
          ),
        );
      }
    },
  );

  SystemChannels.lifecycle.setMessageHandler((msg) async {
    if (msg == AppLifecycleState.resumed.toString()) {
      bool isLoggedIn = await SecureStorage().isLoggedin();
      const _platform = MethodChannel('app.channel.shared.data');
      if (Platform.isAndroid && isLoggedIn) {
        final shared = await _platform.invokeMethod("getSharedData");
        if (shared != null) {
          final sharedData = await collectSharedData(shared);
          final firstData = sharedData.first;
          if (sharedData.isEmpty) {
            return;
          }
          if (firstData is SharedMailto) {
            logSuccess(firstData.mailto.path);
            locator<NavigationService>().navigateTo(
              ComposeEmail(
                mailTo: firstData.mailto.path,
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
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Themes themes = Get.put(Themes(), tag: "theme");
    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: themes.isDark.value ? Themes.darkMode : Themes.lightMode,
        title: "OneMail",
        home: const SplashScreen(),
        navigatorKey: locator<NavigationService>().navigatorKey,
      ),
    );
  }
}
