import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:oneMail/Ads/native_ads.dart';
import 'package:oneMail/Controller/download_controller.dart';
import 'package:oneMail/Services/rating_service.dart';
import 'package:oneMail/Utils/color_pallet.dart';
import 'package:oneMail/Utils/custom_glow_behaviour.dart';
import 'package:oneMail/Utils/review_tile.dart';
import 'package:open_file/open_file.dart';
import 'package:get/get.dart';
import 'package:oneMail/Model/download_model.dart';
import 'package:oneMail/Model/theme_model.dart';
import 'package:share/share.dart';
import 'package:thumbnailer/thumbnailer.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({Key? key}) : super(key: key);

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final Themes themes = Get.find(tag: "theme");
  final NativeAds nativeAds = NativeAds();
  final RxBool isFetching = true.obs;
  final Rating rating = Rating();
  final DownloadController downloadController = DownloadController();

  @override
  void initState() {
    nativeAds.loadAd();
    super.initState();
  }

  RxList<bool> filterSelected = [false, false, false, false].obs;
  RxList<String> filterLabel =
      ["Images", "Video", "Documents", "Audio Files"].obs;

  Widget _filterByUser() {
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ToggleButtons(
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          borderColor: Colors.white,
          borderWidth: 0,
          renderBorder: false,
          children: [
            for (int i = 0; i < downloadController.users.length; i++) ...{
              Padding(
                padding: const EdgeInsets.all(8),
                child: MaterialButton(
                  onPressed: () {
                    for (int idx = 0;
                        idx < downloadController.isSelected.length;
                        idx++) {
                      downloadController.isSelected[idx] = false;
                    }
                    downloadController.isSelected[i] = true;
                    downloadController.toggle(
                        downloadController.users[i], filterSelected);
                  },
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  color: downloadController.isSelected[i]
                      ? ColorPallete.primaryColor
                      : Colors.grey.withOpacity(0.1),
                  child: Text(
                    downloadController.users[i],
                    style: TextStyle(
                      color: downloadController.isSelected[i]
                          ? Colors.white
                          : themes.isDark.value
                              ? Colors.white
                              : Colors.black,
                    ),
                  ),
                ),
              )
            }
          ],
          isSelected: downloadController.isSelected,
        ));
  }

  Widget _filterByFileType() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "All files",
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          IconButton(
            onPressed: () => filterDownloadsByFileType(),
            icon: const Icon(
              IconlyLight.filter,
            ),
          )
        ],
      ),
    );
  }

  List<String> docType = ['docx', 'doc', 'pdf', 'pptx', 'xlsx', 'txt'];

  Widget showDownloads() {
    List<DownloadFileModel> list = downloadController.result;

    return ScrollConfiguration(
      behavior: CustomBehavior(),
      child: ListView(
        children: [
          _filterByUser(),
          _filterByFileType(),
          Column(
            children: [
              ListView.builder(
                itemCount: list.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  if (list[index].mimeType.split('/').last.toLowerCase() ==
                      "html") {
                    return Container();
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      onTap: () => OpenFile.open(list[index].filePath),
                      title: Row(
                        children: [
                          list[index].isImage
                              ? Image.file(
                                  File(list[index].filePath),
                                  width: 25,
                                )
                              : list[index].isAudio
                                  ? const Icon(Icons.audiotrack)
                                  : list[index].isVideo
                                      ? const Icon(Feather.video)
                                      : docType.contains(list[index]
                                              .mimeType
                                              .split('/')
                                              .last
                                              .toLowerCase())
                                          ? Thumbnail(
                                              mimeType: list[index].mimeType,
                                              widgetSize: 25,
                                              decoration: WidgetDecoration(
                                                backgroundColor: themes
                                                        .isDark.value
                                                    ? ColorPallete.darkModeColor
                                                    : Colors.white,
                                              ),
                                              dataResolver: () {
                                                return File(
                                                        list[index].filePath)
                                                    .readAsBytes();
                                              },
                                            )
                                          : list[index]
                                                      .mimeType
                                                      .split('/')
                                                      .last
                                                      .toLowerCase() ==
                                                  "calendar"
                                              ? const Icon(Icons.calendar_today)
                                              : const Icon(Feather.file),
                          const SizedBox(
                            width: 15,
                          ),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  list[index].fileName,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: themes.isDark.value
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(
                                  height: 2,
                                ),
                                Text(
                                  list[index]
                                      .mimeType
                                      .split('/')
                                      .last
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: themes.isDark.value
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(
                                  height: 2,
                                ),
                                Row(
                                  children: [
                                    Text(
                                      DateFormat('hh:mm a').format(
                                          DateTime.parse(
                                              list[index].downloadDate)),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: themes.isDark.value
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      list[index].size,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: themes.isDark.value
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        onPressed: () => Share.shareFiles(
                          [list[index].filePath],
                        ),
                        icon: Icon(
                          AntDesign.sharealt,
                          color:
                              themes.isDark.value ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  filterDownloadsByFileType() {
    showBarModalBottomSheet(
      context: context,
      backgroundColor:
          themes.isDark.value ? ColorPallete.darkModeColor : Colors.white,
      builder: (context) {
        return Obx(
          () => Padding(
            padding: const EdgeInsets.all(12.0),
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Filters",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                for (int i = 0; i < 4; i++) ...{
                  ListTile(
                    onTap: () => filterSelected[i] = !filterSelected[i],
                    title: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                width: 1.5,
                                color: themes.isDark.value
                                    ? Colors.white
                                    : ColorPallete.primaryColor),
                            color: filterSelected[i]
                                ? themes.isDark.value
                                    ? Colors.white
                                    : ColorPallete.primaryColor
                                : themes.isDark.value
                                    ? ColorPallete.darkModeColor
                                    : Colors.white,
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          filterLabel[i],
                          style: TextStyle(
                            fontSize: 16,
                            color: themes.isDark.value
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                },
                const SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: SizedBox(
                    height: 40,
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            "Close",
                            style: TextStyle(
                              color: themes.isDark.value
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            downloadController.changeType(filterSelected);
                          },
                          child: Text(
                            "Apply",
                            style: TextStyle(
                              color: themes.isDark.value
                                  ? Colors.white
                                  : ColorPallete.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor:
            themes.isDark.value ? ColorPallete.darkModeColor : Colors.white,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            !rating.isRatindApplicable.value
                ? Container()
                : reviews(context, rating, themes.isDark.value),
            nativeAds.isAdLoaded.value
                ? SizedBox(
                    child: AdWidget(ad: nativeAds.nativeAd!),
                    height: 72.0,
                  )
                : Container(
                    height: 0,
                  ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
        body: Obx(() {
          if (!downloadController.isFetching.value &&
              downloadController.downloads.isNotEmpty) {
            return showDownloads();
          } else if (!downloadController.isFetching.value &&
              downloadController.downloads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/product_not_found.png",
                    height: 250,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    "No downloads Found",
                    style: TextStyle(
                      fontSize: 20,
                      color: themes.isDark.value ? Colors.white60 : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width - 20,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
