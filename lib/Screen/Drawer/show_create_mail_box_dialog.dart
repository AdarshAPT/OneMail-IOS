import 'dart:io';

import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:oneMail/Controller/email_controller.dart';
import 'package:oneMail/Model/theme_model.dart';
import 'package:oneMail/Services/email_service.dart';
import 'package:oneMail/Utils/color_pallet.dart';

Widget errorDialog(BuildContext context, bool isDark) {
  final Services services = Get.find(tag: "services");
  final TextEditingController controller = TextEditingController();
  final GetEmailController mailBoxController = Get.find(tag: "emailController");
  final RxBool isCreating = false.obs;
  final Themes themes = Get.find(tag: "theme");
  return Obx(
    () => AlertDialog(
      title: Text(
        "Create new mailbox",
        style: TextStyle(
          color: themes.isDark.value ? Colors.white : Colors.black,
          fontSize: 17,
        ),
      ),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: "Enter Mailbox name",
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: ColorPallete.primaryColor),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            "Cancel",
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
        ),
        TextButton(
          onPressed: () async {
            if (controller.text.isEmpty) {
              Fluttertoast.showToast(msg: "Mailbox Name is required");
              return;
            }
            Mailbox? mailbox =
                await services.createMailbox(controller.text.trim());
            if (mailbox == null) {
              Fluttertoast.showToast(
                  msg: "Unable to create Mailbox ${controller.text.trim()}");
            } else {
              Fluttertoast.showToast(
                  msg:
                      "Successfully created Mailbox ${controller.text.trim()}");
              mailBoxController.mailboxList.add(mailbox);
            }
            Navigator.of(context).pop();
          },
          child: !isCreating.value
              ? Text(
                  "Create",
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                )
              : Platform.isAndroid
                  ? Transform.scale(
                      scale: 0.5,
                      child: const CircularProgressIndicator(),
                    )
                  : const CupertinoActivityIndicator(),
        )
      ],
    ),
  );
}
