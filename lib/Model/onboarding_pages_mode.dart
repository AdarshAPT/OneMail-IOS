import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oneMail/Utils/logger.dart';

class OnboardingModel {
  final String image;
  final String title;

  OnboardingModel(this.image, this.title);
}

class OnboardingController extends GetxController {
  late final PageController controller;
  late final TabController tabController;
  late final Timer timer;

  RxInt currIdx = 0.obs;

  @override
  onClose() {
    timer.cancel();
    tabController.dispose();
    controller.dispose();
    logSuccess("disposed");
  }

  OnboardingController(this.controller, this.tabController) {
    timer = Timer.periodic(
      const Duration(seconds: 2),
      (timer) {
        if (currIdx < 2) {
          currIdx.value += 1;
          tabController.index += 1;
          logSuccess("onboarding");
        } else {
          currIdx.value = 0;
          tabController.index = 0;
          logSuccess("onboarding");
        }
        if (controller.hasClients) {
          controller.animateToPage(
            currIdx.value,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeIn,
          );
        }
      },
    );
  }
}
