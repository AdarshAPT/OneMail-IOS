import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:oneMail/Ads/native_ads.dart';
import 'package:oneMail/Model/user_model.dart';
import 'package:oneMail/Screen/Homepage/homepage.dart';
import 'package:oneMail/Services/storage_service.dart';
import 'package:oneMail/Services/email_service.dart';
import 'package:oneMail/Utils/auth_client.dart';
import 'package:oneMail/Utils/color_pallet.dart';
import 'package:oneMail/Utils/logger.dart';
import 'package:oneMail/Utils/logging.dart';

class AddClientScreen extends StatefulWidget {
  const AddClientScreen({Key? key}) : super(key: key);

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final Services services = Get.find(tag: "services");
  final NativeAds nativeAdsTop = NativeAds();
  final NativeAds nativeAdsBottom = NativeAds();

  @override
  void initState() {
    nativeAdsTop.loadAd();
    nativeAdsBottom.loadAd();
    super.initState();
  }

  @override
  void dispose()
  {
    super.dispose();
  }

  void outlookLogin() async{
    final TextEditingController editingController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    String? result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return SizedBox(
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6)
            ),
            title: const Text("Enter Email Id",style: TextStyle(
              color: Colors.black,
              fontSize: 17,
            ),),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width*8,
                    child: TextFormField(
                      controller: editingController,
                      validator: (String? val){
                        if(val != null)
                        {
                          if(!val.trim().isEmail) return "Enter valid Email ID";
                        }
                      },
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      cursorColor: Colors.black,
                    decoration: InputDecoration(
                      filled: true,
                      isDense: true,
                      
                      errorStyle: const TextStyle(
                        fontSize: 15,
                      ),
                      fillColor: Colors.grey.shade100,
                      border: const OutlineInputBorder(borderSide: BorderSide.none,),
                    ),
                    ),
                  ),
                  const SizedBox(height: 10,),
                  MaterialButton(
                    color: ColorPallete.primaryColor,
                    onPressed: (){
                      if(_formKey.currentState!.validate())
                      {
                        logSuccess(editingController.text);
                        Navigator.of(context).pop(editingController.text.trim());
                      }
                    },
                    
                    elevation: 0,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: const Center(child: Text("Sign in",style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white
                    )
                    ,),),
                  ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );

    if(result != null && result.trim().isEmail)
    {
await handleAuth(context, AuthClient.Microsoft,emailID: result.trim());
    }
  }

  AppBar _appBar() {
    return AppBar(
      backgroundColor: ColorPallete.primaryColor,
      systemOverlayStyle: Platform.isAndroid
          ? SystemUiOverlayStyle(
              statusBarColor: ColorPallete.primaryColor,
              statusBarBrightness: Brightness.light,
              statusBarIconBrightness: Brightness.light,
            )
          : null,
      title: const Text(
        "Add Account",
        style: TextStyle(
          fontSize: 18,
        ),
      ),
      elevation: 0.5,
    );
  }

  Future<void> handleAuth(BuildContext context, AuthClient client,{String emailID = ""}) async {
    try {
      bool res = await services.init(client,email: emailID);
      if (res) {
        final User user = await SecureStorage().getCurrUser();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) {
              return HomePage(
                user: user,
              );
            },
          ),
          (Route<dynamic> route) => false,
        );
      }
      else
      {
        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      logToDevice("AddClientScreen", "handleAuth", e.toString(), stackTrace);
    }
  }

  showPrivacyDialog() async {
    bool? res = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.white
          title: const Text(
            "Disclosure",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(children: [
                  const TextSpan(
                    text:
                        "OneMail use and transfer to any other app of information received from Google APIs will adhere to ",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  TextSpan(
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        await launch(
                            'https://developers.google.com/terms/api-services-user-data-policy#additional_requirements_for_specific_api_scopes');
                      },
                    text: 'Google API Services User Data Policy',
                    style: TextStyle(
                      fontSize: 15,
                      color: ColorPallete.primaryColor,
                    ),
                  ),
                  const TextSpan(
                    text: ", including the Limited Use requirements.",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
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
                    "Continue",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
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
    const TextStyle _style = TextStyle(fontSize: 16, color: Colors.black87);

    if (client == AuthClient.Google) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: ListTile(
          onTap: () => showPrivacyDialog(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          tileColor: Colors.white,
          leading: SizedBox(
            child: Image.asset("assets/gmail.png"),
            width: 50,
          ),
          title: const Text(
            "Sign in with Google",
            style: _style,
          ),
          trailing: InkWell(
            onTap: () async => showPrivacyDialog(),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: ColorPallete.backgroundColor,
              child: Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: ColorPallete.primaryColor,
              ),
            ),
          ),
        ),
      );
    } else if (client == AuthClient.Microsoft) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: ListTile(
          onTap: () async =>  outlookLogin(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          tileColor: Colors.white,
          leading: SizedBox(
            width: 50,
            child: Image.asset(
              "assets/outlook.png",
              height: 50,
            ),
          ),
          title: const Text(
            "Sign in with Outlook",
            style: _style,
          ),
          trailing: InkWell(
            onTap: () async =>  outlookLogin(),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: ColorPallete.backgroundColor,
              child: Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: ColorPallete.primaryColor,
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
          tileColor: Colors.white,
          leading: SizedBox(
            width: 50,
            child: Image.asset(
              "assets/yandex.png",
              height: 40,
            ),
          ),
          title: const Text(
            "Sign in with Yandex",
            style: _style,
          ),
          trailing: InkWell(
            onTap: () async => await handleAuth(context, client),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: ColorPallete.backgroundColor,
              child: Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: ColorPallete.primaryColor,
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
        backgroundColor: ColorPallete.backgroundColor,
        appBar: _appBar(),
        bottomNavigationBar: nativeAdsBottom.isAdLoaded.value
            ? Container(
                child: AdWidget(ad: nativeAdsBottom.nativeAd!),
                height: 72.0,
                color: Theme.of(context).backgroundColor,
                alignment: Alignment.center,
              )
            : Container(
                height: 0,
              ),
        body: Column(
          children: [
            nativeAdsTop.isAdLoaded.value
                ? Container(
                    child: AdWidget(ad: nativeAdsTop.nativeAd!),
                    height: 72.0,
                    color: Theme.of(context).backgroundColor,
                    alignment: Alignment.center,
                  )
                : Container(),
            const SizedBox(height: 10),
            _emailClientTile(AuthClient.Google, context),
            _emailClientTile(AuthClient.Microsoft, context),
            _emailClientTile(AuthClient.Yandex, context),
          ],
        ),
      ),
    );
  }
}
