import 'dart:io';
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:oneMail/Controller/search_by_query_controller.dart';
import 'package:oneMail/Model/theme_model.dart';
import 'package:oneMail/Services/email_service.dart';
import 'package:oneMail/Screen/Homepage/Components/email_tiles.dart';
import 'package:oneMail/Utils/color_pallet.dart';
import 'package:oneMail/Utils/custom_glow_behaviour.dart';

class SearchPage extends StatefulWidget {
  final Mailbox? mailbox;
  const SearchPage({Key? key, this.mailbox}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _editingController = TextEditingController();

  late final SearchEmailByQueryController _searchEmailController;

  final Services services = Get.find(tag: "services");

  final Themes themes = Get.find(tag: "theme");
  final RxString searchText = "".obs;
  final RxList<String> contactHeader = <String>[].obs;
  final RxInt count = 0.obs;

  @override
  initState() {
    count.listen((count) {
      if (count == 0) {
        _searchEmailController.selectionModeEnable.value = false;
      }
    });
    _searchEmailController = SearchEmailByQueryController(widget.mailbox);
    super.initState();
  }

  @override
  dispose() {
    _editingController.dispose();
    _searchEmailController.dispose();
    count.close();
    super.dispose();
  }

  _seachBox() {
    return TextField(
      controller: _editingController,
      onSubmitted: (val) => searchMail(),
      autofocus: true,
      onChanged: (val) => searchText.value = val,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: const InputDecoration(
        border: InputBorder.none,
        hintText: "Search Mails",
        hintStyle: TextStyle(
          color: Colors.white70,
        ),
      ),
    );
  }

  searchMail() async {
    if (_editingController.text.isNotEmpty) {
      _searchEmailController.searchMail(_editingController.text.trim());
    }
  }

  _searchResults(context) {
    return Obx(
      () => ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _searchEmailController.emails.length,
        shrinkWrap: true,
        itemBuilder: (_, idx) {
          return emailTiles(
            context,
            _searchEmailController,
            idx,
            themes.isDark.value,
            count,
            null,
            isSelectable: false,
            openChat: false,
          );
        },
      ),
    );
  }

  _trailing(BuildContext context) {
    return Obx(
      () => _searchEmailController.isLoading.value
          ? SizedBox(
              child: Center(
                child: Platform.isAndroid
                    ? Transform.scale(
                        scale: 0.5,
                        child: const CircularProgressIndicator(
                          strokeWidth: 4,
                          color: Colors.white,
                        ),
                      )
                    : const CupertinoActivityIndicator(),
              ),
            )
          : IconButton(
              onPressed: () => searchMail(),
              icon: const Icon(
                Icons.search,
                color: Colors.white,
              ),
            ),
    );
  }

  _showFetchingStatus() => Obx(
        () => _searchEmailController.isFething.value
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          themes.isDark.value ? const Color(0xff121212) : Colors.white,
      appBar: AppBar(
        systemOverlayStyle: Platform.isAndroid
            ? SystemUiOverlayStyle(
                statusBarColor: !themes.isDark.value
                    ? ColorPallete.primaryColor
                    : ColorPallete.darkModeColor,
                statusBarBrightness: Brightness.light,
                statusBarIconBrightness: Brightness.light,
              )
            : null,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: themes.isDark.value
            ? ColorPallete.darkModeColor
            : ColorPallete.primaryColor,
        title: _seachBox(),
        elevation: 1,
        actions: [
          _trailing(context),
        ],
      ),
      body: CupertinoScrollbar(
        child: ScrollConfiguration(
          behavior: CustomBehavior(),
          child: SingleChildScrollView(
            controller: _searchEmailController.scrollController,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Obx(
                  () => searchText.value.isEmpty
                      ? Container()
                      : _searchResults(context),
                ),
                _showFetchingStatus(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
