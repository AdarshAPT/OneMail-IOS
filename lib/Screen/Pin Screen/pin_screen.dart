import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/get.dart';
import 'package:oneMail/Model/email_model.dart';
import 'package:oneMail/Model/theme_model.dart';
import 'package:oneMail/Screen/Homepage/Components/email_tiles.dart';
import 'package:oneMail/Controller/pin_message_controller.dart';
import 'package:oneMail/Utils/color_pallet.dart';

class PinMessageScreen extends StatefulWidget {
  const PinMessageScreen({Key? key}) : super(key: key);

  @override
  _PinMessageScreenState createState() => _PinMessageScreenState();
}

class _PinMessageScreenState extends State<PinMessageScreen> {
  final PinMessagesController controller = PinMessagesController();
  final Themes themes = Get.find(tag: 'theme');
  RxInt count = 0.obs;

  @override
  void initState() {
    count.listen((val) {
      if (val == 0) {
        controller.selectionModeEnable.value = false;
      }
    });

    controller.getPinMessage();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        backgroundColor:
            themes.isDark.value ? ColorPallete.darkModeColor : Colors.white,
        appBar: AppBar(
          backgroundColor: themes.isDark.value
              ? themes.isDark.value
                  ? ColorPallete.darkModeColor
                  : Colors.white
              : ColorPallete.primaryColor,
          elevation: 0.5,
          title: const Text(
            "Pinned Mails",
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          actions: [
            controller.selectionModeEnable.value
                ? Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          controller.selectionModeEnable.value = false;
                          for (Email email in controller.emails) {
                            email.isSelect.value = false;
                          }
                        },
                        icon: const Icon(Entypo.cross),
                      ),
                      IconButton(
                        onPressed: () {
                          controller.deletePinMessages();
                          controller.selectionModeEnable.value = false;
                        },
                        icon: const Icon(Feather.trash),
                      ),
                    ],
                  )
                : Container(),
          ],
        ),
        body: controller.emails.isNotEmpty
            ? ListView.builder(
                itemCount: controller.emails.length,
                itemBuilder: (context, index) {
                  return emailTiles(
                    context,
                    controller,
                    index,
                    themes.isDark.value,
                    count,
                    null,
                    openChat: false,
                  );
                },
              )
            : SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/product_not_found.png",
                      height: 250,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      "No pin emails found",
                      style: TextStyle(
                        fontSize: 20,
                        color: themes.isDark.value
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
      );
    });
  }
}
