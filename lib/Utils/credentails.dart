// callback URL
import 'dart:io';

const callbackURL = "onemail://oauth";

// Google Credentials
String googleAPIKEY = Platform.isAndroid
    ? "AIzaSyCBgbvAcK3oHrjWkUX1lKostGkebGwxZFg"
    : "AIzaSyDAaNRG7egIGUJ03ZmYkhN9xwq02Jz4lO8";
const googleClientID =
    "332032277449-jlujr16c34uotir87cri95v55rqc06a1.apps.googleusercontent.com";
const googleCallbackURL =
    "com.googleusercontent.apps.332032277449-jlujr16c34uotir87cri95v55rqc06a1";
const googleScope =
    "http://mail.google.com/ https://www.googleapis.com/auth/userinfo.profile openid email profile https://www.googleapis.com/auth/contacts";

// Outlook Credentails
const outlookClientID = "89fe37b2-02a6-4799-8e22-bd93396b50bc";
const outlookClientSecret = "407dd4aa-a249-45d6-bc18-51c63279ba9d";
const outlookScope =
    "https://outlook.office.com/IMAP.AccessAsUser.All https://outlook.office.com/SMTP.Send offline_access";

// yandexCredentails
const yandexClientID = "25d9fde77c36427a8245758b9ec1c484";
const yandexClientSecret = "a433572a428442fca7f225ae25b2976f";

// constDefaultProfileURL
const defaultAvatar =
    "https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y";

// ADS

// SmartMailer-Splash-Interstitial
const androidSlashInterstitial = "ca-app-pub-4310459535775382/9736285068";

// SmartMailer-Home-Native
const androidHomeNative = "ca-app-pub-4310459535775382/6869420907";

// SmartMailer-AllPage-Interstitial
const androidAllPageInterstitial = "ca-app-pub-4310459535775382/2297435289";

// SmartMailer-AllPage-Native
const androidAllPageNative = "ca-app-pub-4310459535775382/8231631707";

// SmartMailer-AllPage-Banner
const androidBanner = "ca-app-pub-4310459535775382/7358190274";

const androidExitInterstitialKey = "ca-app-pub-4310459535775382/9054415329";

const androidAppOpen = "ca-app-pub-4310459535775382/8964460576";

// IOS

const iosSplashIntersitital = "ca-app-pub-4310459535775382/4047741439";

const iosHomeNative = "ca-app-pub-4310459535775382/5169251410";

const iosAllPageIntersitital = "ca-app-pub-4310459535775382/4777535026";

const iosAllPageNative = "ca-app-pub-4310459535775382/4280332268";

const iosBanner = "ca-app-pub-4310459535775382/2487904290";

const iosExitInterstitialKey = "ca-app-pub-4310459535775382/1421578099";

const iosAppOpen = "ca-app-pub-4310459535775382/2734659764";

// Privacy Policy
const privacyPolicy = "https://onemail.today/privacyPolicy.html";
