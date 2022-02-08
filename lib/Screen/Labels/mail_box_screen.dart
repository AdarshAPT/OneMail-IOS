import 'dart:io';

import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:oneMail/Controller/get_mailbox_controller.dart';
import 'package:oneMail/Model/email_model.dart';
import 'package:oneMail/Model/theme_model.dart';
import 'package:oneMail/Screen/Homepage/Components/email_tiles.dart';
import 'package:oneMail/Screen/Homepage/Components/shimmer_email_tiles.dart';
import 'package:oneMail/Screen/Search/search_email_screeen.dart';
import 'package:oneMail/Utils/color_pallet.dart';
import 'package:oneMail/Utils/custom_glow_behaviour.dart';
import 'package:oneMail/Utils/navigation_route.dart';
import 'package:oneMail/main.dart';

class MailboxScreen extends StatefulWidget {
  final Mailbox mailbox;

  const MailboxScreen({Key? key, required this.mailbox}) : super(key: key);

  @override
  State<MailboxScreen> createState() => _MailboxScreenState();
}

class _MailboxScreenState extends State<MailboxScreen> {
  late final GetMailBoxController _controller;
  final Themes themes = Get.find(tag: "theme");
  final RxInt count = 0.obs;

  @override
  initState() {
    _controller = GetMailBoxController(widget.mailbox);

    count.listen((count) {
      if (count == 0) {
        _controller.selectionModeEnable.value = false;
      }
    });
    _controller.fetchAllEmails();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    count.close();
    super.dispose();
  }

  showDeleteDialog(
    BuildContext context,
    GetMailBoxController controller,
  ) {
    final RxBool isDeleted = false.obs;
    showDialog(
      context: context,
      builder: (context) {
        return Obx(
          () => AlertDialog(
            backgroundColor:
                themes.isDark.value ? ColorPallete.darkModeColor : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: Text(
              "Empty ${widget.mailbox.encodedName.capitalize}",
              style: TextStyle(
                fontSize: 16,
                color: themes.isDark.value ? Colors.white : Colors.black,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${widget.mailbox.messagesExists} emails will be permanently deleted",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color:
                        themes.isDark.value ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 5,
                        ),
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: ColorPallete.primaryColor),
                          ),
                        ),
                        const SizedBox(
                          width: 15,
                        ),
                        !isDeleted.value
                            ? InkWell(
                                onTap: () async {
                                  isDeleted.value = true;
                                  bool result = await controller.services
                                      .deleteAllTrash(widget.mailbox);
                                  if (result) {
                                    controller.emails.clear();
                                    isDeleted.value = false;
                                    Fluttertoast.showToast(
                                        msg: "Deleted successfully");
                                    Navigator.of(context).pop();
                                  } else {
                                    Fluttertoast.showToast(
                                        msg: "unable to delete emails");
                                  }
                                },
                                child: Text(
                                  "Empty",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: ColorPallete.primaryColor),
                                ))
                            : Platform.isAndroid
                                ? Transform.scale(
                                    scale: 0.4,
                                    child: CircularProgressIndicator(
                                      color: ColorPallete.primaryColor,
                                    ),
                                  )
                                : const CupertinoActivityIndicator(),
                        const SizedBox(
                          width: 5,
                        )
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  _showFetchingStatus(_controller) {
    return Obx(
      () => _controller.isFething.value
          ? ListView(
              shrinkWrap: true,
              children: [
                Platform.isAndroid
                    ? Transform.scale(
                        scale: 0.7,
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    : const CupertinoActivityIndicator(),
                const SizedBox(
                  height: 10,
                ),
              ],
            )
          : Container(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor:
            themes.isDark.value ? const Color(0xff121212) : Colors.white,
        appBar: AppBar(
          title: Text(
            widget.mailbox.encodedName.capitalizeFirst!,
          ),
          backgroundColor: themes.isDark.value
              ? ColorPallete.darkModeColor
              : ColorPallete.primaryColor,
          actions: [
            !widget.mailbox.isTrash && _controller.selectionModeEnable.value
                ? Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          _controller.selectionModeEnable.value = false;
                          for (Email email in _controller.emails) {
                            email.isSelect.value = false;
                          }
                        },
                        icon: const Icon(Feather.x),
                      ),
                      IconButton(
                        onPressed: () async {
                          await _controller.services
                              .deleteAllMails(_controller);
                        },
                        icon: const Icon(
                          Feather.trash,
                        ),
                      )
                    ],
                  )
                : Container(),
            IconButton(
              onPressed: () => locator<NavigationService>().navigateTo(
                SearchPage(
                  mailbox: widget.mailbox,
                ),
              ),
              icon: const Icon(
                Feather.search,
                color: Colors.white,
              ),
            ),
            widget.mailbox.isTrash
                ? IconButton(
                    onPressed: () {
                      showDeleteDialog(context, _controller);
                    },
                    icon: const Icon(
                      Feather.trash,
                    ),
                  )
                : Container()
          ],
          elevation: 1,
        ),
        body: RefreshIndicator(
          onRefresh: () async => _controller.pullToRefresh(),
          child: ScrollConfiguration(
            behavior: CustomBehavior(),
            child: CupertinoScrollbar(
              child: ListView(
                controller: _controller.scrollController,
                children: [
                  Obx(
                    () => !_controller.isLoading.value
                        ? _controller.emails.isNotEmpty
                            ? Column(
                                children: [
                                  _controller.isLoading.value
                                      ? Transform.scale(
                                          scale: 0.7,
                                          child:
                                              const CircularProgressIndicator(),
                                        )
                                      : Container(),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _controller.emails.length,
                                    itemBuilder: (_, idx) {
                                      return emailTiles(
                                        context,
                                        _controller,
                                        idx,
                                        themes.isDark.value,
                                        count,
                                        widget.mailbox,
                                        isSelectable: !widget.mailbox.isTrash,
                                        openChat: false,
                                      );
                                    },
                                  )
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    height: 150,
                                  ),
                                  Image.asset(
                                    "assets/product_not_found.png",
                                    height: 250,
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    "No Mails found",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: themes.isDark.value
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              )
                        : SizedBox(
                            child: const ShimmerTile(),
                            height: MediaQuery.of(context).size.height,
                          ),
                  ),
                  _showFetchingStatus(_controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
