import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/get.dart';
import 'package:oneMail/Controller/search_by_user_controller.dart';
import 'package:oneMail/Model/contacts_model.dart';
import 'package:oneMail/Model/theme_model.dart';
import 'package:oneMail/Screen/Compose/compose_email_screen.dart';
import 'package:oneMail/Screen/Homepage/Components/email_tiles.dart';
import 'package:oneMail/Screen/Homepage/Components/shimmer_email_tiles.dart';
import 'package:oneMail/Utils/color_pallet.dart';
import 'package:oneMail/Utils/custom_glow_behaviour.dart';
import 'package:oneMail/Utils/navigation_route.dart';
import '../../main.dart';

class GetAllContacts extends StatefulWidget {
  final Contacts contacts;
  const GetAllContacts({Key? key, required this.contacts}) : super(key: key);

  @override
  _GetAllContactsState createState() => _GetAllContactsState();
}

class _GetAllContactsState extends State<GetAllContacts> {
  final SearchByUserController controller = SearchByUserController();
  final Themes themes = Get.find(tag: 'theme');
  final RxInt count = 0.obs;

  @override
  void initState() {
    count.listen((val) {
      if (val == 0) {
        controller.selectionModeEnable.value = false;
      }
    });
    controller.searchMail(widget.contacts.email);
    super.initState();
  }

  @override
  void dispose() {
    count.close();
    super.dispose();
  }

  _showFetchingStatus() => Obx(
        () => controller.isFething.value
            ? Column(
                children: [
                  Platform.isAndroid
                      ? Transform.scale(
                          scale: 0.7,
                          child:
                              const Center(child: CircularProgressIndicator()),
                        )
                      : const CupertinoActivityIndicator(),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              )
            : Container(),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          themes.isDark.value ? ColorPallete.darkModeColor : Colors.white,
      appBar: AppBar(
        elevation: 1,
        systemOverlayStyle: Platform.isAndroid
            ? SystemUiOverlayStyle(
                statusBarColor: !themes.isDark.value
                    ? ColorPallete.primaryColor
                    : ColorPallete.darkModeColor,
                statusBarBrightness: Brightness.light,
                statusBarIconBrightness: Brightness.light,
              )
            : null,
        title: Text(
          widget.contacts.name,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () =>
                locator<NavigationService>().navigateTo(const ComposeEmail()),
            icon: const Icon(Ionicons.mail),
          )
        ],
      ),
      body: Obx(() => controller.isLoading.value
          ? SizedBox(
              child: const ShimmerTile(),
              height: MediaQuery.of(context).size.height,
            )
          : controller.emails.isNotEmpty
              ? ScrollConfiguration(
                  behavior: CustomBehavior(),
                  child: CupertinoScrollbar(
                    child: SingleChildScrollView(
                      controller: controller.scrollController,
                      child: Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            itemCount: controller.emails.length,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              return emailTiles(
                                context,
                                controller,
                                index,
                                themes.isDark.value,
                                count,
                                null,
                                isSelectable: false,
                                openChat: false,
                              );
                            },
                          ),
                          _showFetchingStatus(),
                        ],
                      ),
                    ),
                  ),
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
                        "No email found for ${widget.contacts.email}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: themes.isDark.value
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                )),
    );
  }
}
