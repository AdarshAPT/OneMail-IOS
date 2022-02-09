import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:get/get.dart';
import 'package:oneMail/Utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:oneMail/Controller/base_controller.dart';
import 'package:oneMail/Email%20Viewer/mime_message_viewer.dart';
import 'package:oneMail/Model/email_model.dart';
import 'package:oneMail/Model/theme_model.dart';
import 'package:oneMail/Screen/Compose/compose_email_screen.dart';
import 'package:oneMail/Screen/Details/attachment_chip.dart';
import 'package:oneMail/Screen/Details/bottomModalSheet.dart';
import 'package:oneMail/Screen/Settings/config.dart';
import 'package:oneMail/Services/email_service.dart';
import 'package:oneMail/Utils/color_pallet.dart';
import 'package:oneMail/Utils/custom_glow_behaviour.dart';
import 'package:oneMail/Utils/email_tag.dart';
import 'package:oneMail/Utils/navigation_route.dart';
import 'package:oneMail/main.dart';

class Details extends StatelessWidget {
  Details({
    Key? key,
    required this.email,
    required this.controller,
    this.mailbox,
  }) : super(key: key);
  final Email email;
  final Mailbox? mailbox;
  final BaseController controller;
  final Rx<bool> isTapped = false.obs;
  final Services _services = Get.find(tag: "services");
  final Themes themes = Get.find(tag: "theme");
  final Config config = Get.find(tag: "config");
  final RxBool showMore = false.obs;

  _subjectText() {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            email.mimeMessage.decodeSubject() != null &&
                    email.mimeMessage.decodeSubject()!.isNotEmpty
                ? email.mimeMessage.decodeSubject()!.trim()
                : 'No Subject',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: themes.isDark.value ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          _showDate(),
        ],
      ),
    );
  }

  Widget _buildAttachments(List<ContentInfo> attachments) {
    return Wrap(
      children: [
        for (ContentInfo attachment in attachments) ...{
          Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
              ),
              child: AttachmentChip(info: attachment, message: email))
        }
      ],
    );
  }

  List<Widget> _actionList(context) {
    return [
      IconButton(
        onPressed: () {
          openBottomDrawer(
            context,
            email,
            null,
            themes.isDark.value,
            _services,
            mailbox,
            listOfAttachment: email.attachments,
            controller: controller,
            isIndividual: true,
          );
        },
        icon: const Icon(Feather.more_vertical),
      ),
    ];
  }

  AppBar appBar(BuildContext context, Themes themes, String senderName) =>
      AppBar(
        elevation: 0.5,
        backgroundColor: themes.isDark.value
            ? ColorPallete.darkModeColor
            : ColorPallete.primaryColor,
        actions: _actionList(context),
        title: Text(
          email.mimeMessage.from!.first.personalName ??
              email.mimeMessage.from!.first.email,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      );

  Widget _showDate() {
    return Text(
      DateFormat('dd MMMM yyyy, hh:mm a').format(
        email.mimeMessage.decodeDate() ?? DateTime.now(),
      ),
      style: TextStyle(
        fontSize: 15,
        color: themes.isDark.value ? Colors.white70 : Colors.black54,
      ),
    );
  }

  Widget _showFrom() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "From:",
          style: TextStyle(
            fontSize: 16,
            color: themes.isDark.value ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Flexible(
          child: emailField(
            email.mimeMessage.from!.first.email,
            themes,
          ),
        ),
        Obx(
          () => InkWell(
            onTap: () {
              showMore.value = !showMore.value;
            },
            child: !showMore.value
                ? Icon(
                    Icons.expand_more,
                    color: themes.isDark.value
                        ? Colors.white
                        : ColorPallete.primaryColor,
                  )
                : Icon(
                    Icons.expand_less,
                    color: themes.isDark.value
                        ? Colors.white
                        : ColorPallete.primaryColor,
                  ),
          ),
        )
      ],
    );
  }

  Widget _showBCC() {
    return email.mimeMessage.bcc!.isNotEmpty
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Bcc:",
                style: TextStyle(
                  fontSize: 16,
                  color: themes.isDark.value ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(
                width: 15,
              ),
              Expanded(
                child: Wrap(
                  runSpacing: 10.0,
                  spacing: 5.0,
                  children: email.mimeMessage.bcc!
                      .map<Widget>(
                        (MailAddress address) =>
                            emailField(address.email, themes),
                      )
                      .toList(),
                ),
              ),
            ],
          )
        : Container();
  }

  Widget _showCC() {
    return email.mimeMessage.cc!.isNotEmpty
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Cc:",
                style: TextStyle(
                  fontSize: 16,
                  color: themes.isDark.value ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(
                width: 25,
              ),
              Expanded(
                child: Wrap(
                  runSpacing: 10.0,
                  spacing: 5.0,
                  children: email.mimeMessage.cc!
                      .map<Widget>(
                        (MailAddress address) =>
                            emailField(address.email, themes),
                      )
                      .toList(),
                ),
              ),
            ],
          )
        : Container();
  }

  Widget _showTo() {
    return email.mimeMessage.to!.isNotEmpty
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "To:",
                style: TextStyle(
                  fontSize: 16,
                  color: themes.isDark.value ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(
                width: 30,
              ),
              Expanded(
                child: Wrap(
                  runSpacing: 10.0,
                  spacing: 5.0,
                  children: email.mimeMessage.to!
                      .map<Widget>(
                        (MailAddress address) => emailField(
                          address.email,
                          themes,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          )
        : Container();
  }

  Widget _showAdditionalDetails() {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10.0,
          vertical: 2.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 13,
            ),
            _showFrom(),
            divider,
            showMore.value
                ? Column(
                    children: [
                      _showTo(),
                      email.mimeMessage.cc!.isNotEmpty ? divider : Container(),
                      _showCC(),
                      email.mimeMessage.bcc!.isNotEmpty ? divider : Container(),
                      _showBCC(),
                      divider,
                    ],
                  )
                : Container()
          ],
        ),
      ),
    );
  }

  Widget _buildEmailViewer() {
    return Center(
      child: MimeMessageViewer(
        enableDarkMode: themes.isDark.value,
        mimeMessage: email.mimeMessage,
        urlLauncherDelegate: (url) async {
          if (config.isOpenInApp.value) {
            await FlutterWebBrowser.openWebPage(
              url: url,
              customTabsOptions: CustomTabsOptions(
                colorScheme: themes.isDark.value
                    ? CustomTabsColorScheme.dark
                    : CustomTabsColorScheme.light,
                showTitle: true,
                instantAppsEnabled: true,
                defaultColorSchemeParams: CustomTabsColorSchemeParams(
                  toolbarColor: themes.isDark.value
                      ? ColorPallete.darkModeColor
                      : ColorPallete.primaryColor,
                ),
              ),
            );
          } else {
            if (await canLaunch(url)) {
              await launch(url);
            }
          }
          return Future.value(true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attachments = email.attachments;
    return Scaffold(
      backgroundColor:
          themes.isDark.value ? const Color(0xff121212) : Colors.white,
      appBar: appBar(
        context,
        themes,
        email.mimeMessage.decodeSender().first.personalName ?? "",
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ColorPallete.primaryColor,
        onPressed: () {
          List<String> to = [];
          List<String> bcc = [];
          List<String> cc = [];
          if (email.mimeMessage.bcc != null &&
              email.mimeMessage.bcc!.isNotEmpty) {
            for (var email in email.mimeMessage.bcc!) {
              bcc.add(email.email);
            }
          }

          if (email.mimeMessage.cc != null &&
              email.mimeMessage.cc!.isNotEmpty) {
            for (var email in email.mimeMessage.cc!) {
              cc.add(email.email);
            }
          }

          if (email.mimeMessage.from != null &&
              email.mimeMessage.from!.isNotEmpty) {
            for (var email in email.mimeMessage.from!) {
              to.add(email.email);
            }
          }
          locator<NavigationService>().navigateTo(
            ComposeEmail(
              isReply: true,
              subject: email.mimeMessage
                  .decodeSubject()!
                  .replaceAll("Re:", "")
                  .trim(),
              to: to,
              bcc: bcc,
              cc: cc,
            ),
          );
        },
        child: const Icon(
          Icons.reply_all,
          color: Colors.white,
        ),
      ),
      body: ScrollConfiguration(
        behavior: CustomBehavior(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _subjectText(),
                    Obx(
                      () => IconButton(
                        onPressed: () async {
                          final bool isFlag = email.isFlag.value;
                          email.isFlag.value = !email.isFlag.value;
                          await _services.setFlagged(
                            email.mimeMessage,
                            isFlag,
                          );
                          int index = controller.emails.indexWhere(
                            (element) =>
                                element.mimeMessage.decodeDate()! ==
                                    email.mimeMessage.decodeDate()! &&
                                element.mimeMessage.decodeSubject()! ==
                                    email.mimeMessage.decodeSubject()!,
                          );

                          if (index == -1) {
                            return;
                          }

                          logSuccess("found");

                          controller.emails.elementAt(index).isFlag.value =
                              !isFlag;
                        },
                        icon: !email.isFlag.value
                            ? const Icon(AntDesign.staro)
                            : Icon(
                                AntDesign.star,
                                color: ColorPallete.primaryColor,
                              ),
                      ),
                    )
                  ],
                ),
              ),
              _showAdditionalDetails(),
              _buildAttachments(attachments),
              _buildEmailViewer(),
            ],
          ),
        ),
      ),
    );
  }
}
