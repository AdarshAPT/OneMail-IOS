// ignore_for_file: unused_local_variable

import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/get.dart';
import 'package:oneMail/Model/onboarding_pages_mode.dart';
import 'package:oneMail/Screen/AuthScreen/add_client.dart';
import 'package:oneMail/Services/email_service.dart';
import 'package:oneMail/Utils/color_pallet.dart';
import 'package:oneMail/Utils/custom_glow_behaviour.dart';
import 'package:oneMail/Utils/navigation_route.dart';
import 'package:oneMail/main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final Services services = Get.put(Services(), tag: "services");

  final PageController controller = PageController();
  late final OnboardingController onBoardingController;
  late final TabController tabController;

  @override
  void initState() {
    tabController = TabController(length: 3, vsync: this);
    onBoardingController = OnboardingController(controller, tabController);
    super.initState();
  }

  @override
  void dispose() {
    onBoardingController.onClose();
    super.dispose();
  }

  final List<OnboardingModel> pages = [
    OnboardingModel("assets/newsletter.png", "Manage your Tasks directly"),
    OnboardingModel("assets/working.png", "All Mail in One App"),
    OnboardingModel("assets/growth.png", "Get Quick Mail Views"),
  ];

  Widget _images(BuildContext context, PageController controller) {
    return SizedBox(
      height: 410,
      child: PageView.builder(
        itemCount: pages.length,
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Column(
            children: [
              Image.asset(
                pages[index].image,
                height: 270,
              ),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  pages[index].title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    color: ColorPallete.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _addAccountBtn(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: MaterialButton(
        elevation: 0.5,
        shape: const StadiumBorder(),
        color: ColorPallete.primaryColor,
        onPressed: () => locator<NavigationService>().navigateTo(
          const AddClientScreen(),
        ),
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Ionicons.add_circle_outline,
                  color: Colors.white,
                  size: 30,
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  "Add an Account",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _title() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "One",
          style: TextStyle(
            color: ColorPallete.primaryColor,
            fontSize: 50,
          ),
        ),
        Text(
          "Mail ",
          style: TextStyle(
            color: ColorPallete.primaryColor,
            fontSize: 50,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _termsAndCondition() {
    const TextStyle _textStyle = TextStyle(
      fontSize: 16,
      color: Color(0xff4a4a4a),
    );
    TextStyle _customStyle = TextStyle(
      fontSize: 16,
      color: ColorPallete.primaryColor,
    );
    return Column(
      children: [
        const Text(
          "By Continuing you agree to our",
          style: _textStyle,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              child: Text("privacy policy", style: _customStyle),
              onTap: () async =>
                  launch("https://onemail.today/privacyPolicy.html"),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          elevation: 0,
          systemOverlayStyle: Platform.isAndroid
              ? const SystemUiOverlayStyle(
                  statusBarColor: Colors.white,
                  statusBarBrightness: Brightness.dark,
                  statusBarIconBrightness: Brightness.dark,
                )
              : null,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ScrollConfiguration(
            behavior: CustomBehavior(),
            child: SingleChildScrollView(
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  _title(),
                  const SizedBox(
                    height: 40,
                  ),
                  _images(
                    context,
                    controller,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  _addAccountBtn(context),
                  const SizedBox(
                    height: 25,
                  ),
                  _termsAndCondition(),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
