import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:oneMail/Model/theme_model.dart';
import 'package:oneMail/Utils/color_pallet.dart';
import 'package:oneMail/Utils/page_indicator.dart';

class HelpAndSupport extends StatefulWidget {
  const HelpAndSupport({Key? key}) : super(key: key);

  @override
  _HelpAndSupportState createState() => _HelpAndSupportState();
}

class HelpAndSupportModel {
  final String image;
  final String text;

  HelpAndSupportModel(this.image, this.text);
}

class _HelpAndSupportState extends State<HelpAndSupport> {
  final CarouselController _carouselController = CarouselController();
  final Themes themes = Get.find(tag: 'theme');
  final List<HelpAndSupportModel> list = [
    HelpAndSupportModel(
      "assets/helpAndSupport/downloads.png",
      "Manage all your downloads in one place. Just download the attachments and managed them in download section.",
    ),
    HelpAndSupportModel(
      "assets/helpAndSupport/profile.png",
      "Tasks are simple and to do list are mentioned in this. All the tasks are briefly mentioned.",
    ),
    HelpAndSupportModel(
      "assets/helpAndSupport/templates.png",
      "Get list of 30+ templates, just copy and paste them, and you are good to go.",
    ),
  ];
  final RxInt currPage = 0.obs;

  @override
  initState() {
    super.initState();
  }

  Widget helpAndSupportWidget(HelpAndSupportModel helpAndSupportModel) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        height: 350,
        width: MediaQuery.of(context).size.width * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color:
              themes.isDark.value ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
        child: Column(
          children: [
            Image.asset(
              helpAndSupportModel.image,
              height: 200,
            ),
            const SizedBox(
              height: 30,
            ),
            Text(
              helpAndSupportModel.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget helpAndSupportUI() {
    return CarouselSlider(
      items: list.map<Widget>((e) => helpAndSupportWidget(e)).toList(),
      carouselController: _carouselController,
      options: CarouselOptions(
        height: 350,
        initialPage: 0,
        enableInfiniteScroll: true,
        onPageChanged: (val, res) {
          if (res == CarouselPageChangedReason.manual) {
            currPage.value = val;
          }
        },
      ),
    );
  }

  @override
  dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          themes.isDark.value ? ColorPallete.darkModeColor : Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: themes.isDark.value
            ? ColorPallete.darkModeColor
            : ColorPallete.primaryColor,
        systemOverlayStyle: Platform.isAndroid
            ? SystemUiOverlayStyle(
                statusBarColor: !themes.isDark.value
                    ? ColorPallete.primaryColor
                    : ColorPallete.darkModeColor,
                statusBarBrightness: Brightness.light,
                statusBarIconBrightness: Brightness.light,
              )
            : null,
        title: const Text(
          "Help and Support",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 20,
          ),
          helpAndSupportUI(),
          Obx(
            () => CarouselIndicator(
              count: 3,
              index: currPage.value,
              color: themes.isDark.value
                  ? Colors.grey.shade900
                  : Colors.grey.shade400,
              activeColor: themes.isDark.value
                  ? Colors.white
                  : ColorPallete.primaryColor,
            ),
          ),
          const Spacer(),
          Image.asset(
            "assets/helpAndSupport/bottom.png",
          )
        ],
      ),
    );
  }
}
