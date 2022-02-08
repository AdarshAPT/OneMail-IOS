import 'dart:io';

import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oneMail/Controller/email_controller.dart';
import 'package:oneMail/Model/theme_model.dart';
import 'package:oneMail/Model/user_model.dart';
import 'package:oneMail/Screen/Homepage/Components/shimmer_email_tiles.dart';
import 'package:oneMail/Utils/color_pallet.dart';
import 'package:oneMail/Utils/custom_glow_behaviour.dart';
import 'Components/email_tiles.dart';

class InboxScreen extends StatefulWidget {
  final User user;
  final Mailbox? mailbox;
  final RxInt count;
  const InboxScreen(
      {Key? key, required this.user, this.mailbox, required this.count})
      : super(key: key);

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen>
    with AutomaticKeepAliveClientMixin {
  final GetEmailController _emailController = Get.find(tag: 'emailController');
  final Themes themes = Get.find(tag: "theme");

  @override
  bool get wantKeepAlive => true;

  _showFetchingStatus() => Obx(
        () => _emailController.isFething.value
            ? Column(
                children: [
                  Platform.isAndroid
                      ? Transform.scale(
                          scale: 0.7,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : const CupertinoActivityIndicator(),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              )
            : Container(),
      );

  Widget _listOfEmails() {
    return Obx(
      () => !_emailController.isLoading.value
          ? _emailController.emails.isNotEmpty
              ? ListView.builder(
                  shrinkWrap: true,
                  itemCount: _emailController.emails.length,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (_, idx) {
                    return emailTiles(
                      context,
                      _emailController,
                      idx,
                      themes.isDark.value,
                      widget.count,
                      widget.mailbox,
                      openChat: true,
                    );
                  })
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
    );
  }

  @protected
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor:
          themes.isDark.value ? ColorPallete.darkModeColor : Colors.white,
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: CustomBehavior(),
          child: RefreshIndicator(
            onRefresh: () async => await _emailController.pullToRefresh(),
            color: ColorPallete.primaryColor,
            child: CupertinoScrollbar(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _emailController.scrollController,
                child: Column(
                  children: [
                    _listOfEmails(),
                    _showFetchingStatus(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
