import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:oneMail/Model/gmail_model.dart';
import 'package:oneMail/Model/outlook_model.dart';
import 'package:oneMail/Model/theme_model.dart';
import 'package:oneMail/Screen/Compose/compose_email_screen.dart';
import 'package:oneMail/Screen/Settings/config.dart';
import 'package:oneMail/Utils/color_pallet.dart';
import 'package:oneMail/Utils/email_tag.dart';
import 'package:oneMail/Utils/navigation_route.dart';
import '../../main.dart';
import 'package:url_launcher/url_launcher.dart';

class OutlookDetails extends StatefulWidget {
  const OutlookDetails({Key? key, required this.email}) : super(key: key);
  final OutlookModel email;

  @override
  State<OutlookDetails> createState() => _OutlookDetailsState();
}

class _OutlookDetailsState extends State<OutlookDetails> {
  final Rx<bool> isTapped = false.obs;
  final Config config = Get.find(tag: "config");
  final Themes themes = Get.find(tag: "theme");
  final RxDouble _height = 0.0.obs;
  final RxList<Address> bcc = <Address>[].obs;
  final RxList<Address> cc = <Address>[].obs;
  final RxList<Address> from = <Address>[].obs;
  final RxList<Address> to = <Address>[].obs;

  @override
  initState() {
    WidgetsBinding.instance!.addPostFrameCallback((_) => fetchDetails());
    super.initState();
  }

  @override
  dispose() {
    bcc.close();
    cc.close();
    from.close();
    to.close();
    super.dispose();
  }

  fetchDetails() {
    cc.addAll(widget.email.getCc());
    bcc.addAll(widget.email.getBcc());
    to.addAll(widget.email.getTo());
    from.addAll(widget.email.getFrom());
  }

  _subjectText() {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.email.subject,
            maxLines: 2,
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

  Widget _showDate() {
    return Text(
      DateFormat('dd MMMM yyyy, hh:mm a').format(widget.email.time),
      style: TextStyle(
        fontSize: 15,
        color: themes.isDark.value ? Colors.white70 : Colors.black54,
      ),
    );
  }

  AppBar appBar(context, themes, String senderName) => AppBar(
        elevation: 0.5,
        title: Text(
          senderName,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        // actions: _actionList(context),
      );

  Future<NavigationActionPolicy> _shouldOverrideUrlLoading(
      InAppWebViewController controller, NavigationAction request) async {
    final requestUri = request.request.url!;
    final url = requestUri.toString();
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
    return NavigationActionPolicy.CANCEL;
  }

  Widget _showFrom(List<Address> from) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        Expanded(
          child: Wrap(
            runSpacing: 10.0,
            spacing: 5.0,
            children: from
                .map<Widget>(
                  (Address address) => emailField(
                    address.personalName ?? address.email,
                    themes,
                  ),
                )
                .toList(),
          ),
        )
      ],
    );
  }

  Widget _showBCC(List<Address> bcc) {
    return bcc.isNotEmpty
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  children: bcc
                      .map<Widget>(
                        (Address address) => emailField(
                            address.personalName ?? address.email, themes),
                      )
                      .toList(),
                ),
              ),
            ],
          )
        : Container();
  }

  Widget _showCC(List<Address> cc) {
    return cc.isNotEmpty
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  children: cc
                      .map<Widget>(
                        (Address address) => emailField(
                            address.personalName ?? address.email, themes),
                      )
                      .toList(),
                ),
              ),
            ],
          )
        : Container();
  }

  Widget _showTo(List<Address> to) {
    return to.isNotEmpty
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  children: to
                      .map<Widget>(
                        (Address address) => emailField(
                          address.personalName ?? address.email,
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
            _showFrom(from),
            divider,
            _showTo(to),
            cc.isNotEmpty ? divider : Container(),
            _showCC(cc),
            bcc.isNotEmpty ? divider : Container(),
            _showBCC(bcc),
            divider,
          ],
        ),
      ),
    );
  }

  Widget _showEmail() {
    return Obx(
      () => SizedBox(
        width: MediaQuery.of(context).size.width,
        height: _height.value,
        child: InAppWebView(
          initialData: InAppWebViewInitialData(data: widget.email.body),
          onLoadStop: (controller, url) async {
            if (true) {
              var scrollHeight = (await controller.evaluateJavascript(
                  source: 'document.body.scrollHeight'));

              if (scrollHeight != null) {
                final scrollWidth = (await controller.evaluateJavascript(
                    source: 'document.body.scrollWidth'));

                final size = MediaQuery.of(context).size;

                if (scrollWidth > size.width) {
                  var scale = (size.width / scrollWidth);
                  if (scale < 0.2) {
                    scale = 0.2;
                  }
                  await controller.zoomBy(zoomFactor: scale, iosAnimated: true);
                  scrollHeight = (scrollHeight * scale).ceil();
                }

                _height.value = (scrollHeight + 10.0);
              }
            }
          },
          shouldOverrideUrlLoading: _shouldOverrideUrlLoading,
          initialOptions: InAppWebViewGroupOptions(
            crossPlatform: InAppWebViewOptions(
              useShouldOverrideUrlLoading: true,
              verticalScrollBarEnabled: false,
              transparentBackground: themes.isDark.value,
            ),
            android: AndroidInAppWebViewOptions(
              useWideViewPort: false,
              loadWithOverviewMode: true,
              useHybridComposition: true,
              forceDark: themes.isDark.value
                  ? AndroidForceDark.FORCE_DARK_ON
                  : AndroidForceDark.FORCE_DARK_OFF,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    widget.email.getCc();
    return Scaffold(
      backgroundColor:
          themes.isDark.value ? const Color(0xff121212) : Colors.white,
      appBar: appBar(
        context,
        themes,
        widget.email.senderName,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ColorPallete.primaryColor,
        onPressed: () {
          List<String> to = [];
          List<String> bcc = [];
          List<String> cc = [];
          if (widget.email.getBcc().isNotEmpty) {
            for (var email in widget.email.getBcc()) {
              bcc.add(email.email);
            }
          }

          if (widget.email.getCc().isNotEmpty) {
            for (var email in widget.email.getCc()) {
              cc.add(email.email);
            }
          }

          if (widget.email.getFrom().isNotEmpty) {
            for (var email in widget.email.getFrom()) {
              to.add(email.email);
            }
          }
          locator<NavigationService>().navigateTo(
            ComposeEmail(
              isReply: true,
              subject: widget.email.subject.replaceAll("Re: ", ""),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _subjectText(),
                ],
              ),
            ),
            _showAdditionalDetails(),
            _showEmail(),
          ],
        ),
      ),
    );
  }
}
