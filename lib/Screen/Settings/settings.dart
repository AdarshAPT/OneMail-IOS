import 'dart:io';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:oneMail/Model/theme_model.dart';
import 'package:oneMail/Screen/Settings/config.dart';
import 'package:oneMail/Screen/Settings/help_and_support.dart';
import 'package:oneMail/Utils/color_pallet.dart';
import 'package:oneMail/Utils/navigation_route.dart';
import 'package:oneMail/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final Themes themes = Get.find(tag: 'theme');
  final Config config = Get.find(tag: "config");

  saveLogs() async {
    bool checkPermission = await Permission.storage.isGranted;

    if (!checkPermission) {
      PermissionStatus status = await Permission.storage.request();
      if (!status.isGranted) return;
    }

    File file = await FLog.exportLogs();

    Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
    String appDocumentsPath = appDocumentsDirectory.path;

    File logFiles = File(appDocumentsPath + '/logs.txt');

    if (!await logFiles.exists()) {
      logFiles.create(recursive: true);
    }

    await logFiles.writeAsBytes(await file.readAsBytes());

    Fluttertoast.showToast(
      msg: "Logs exported to ${logFiles.path}",
    );
  }

  updateSignature(String updatedSignature) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    await preferences.setString("signature", updatedSignature);

    Fluttertoast.showToast(msg: "Signature updated");
  }

  showSignatureDialog() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    final TextEditingController signatureController = TextEditingController(
      text: "${preferences.getString("signature")}",
    );
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor:
                themes.isDark.value ? ColorPallete.darkModeColor : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Signature",
                    style: TextStyle(
                      fontSize: 17,
                      color: themes.isDark.value ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: signatureController,
                    maxLines: 6,
                    minLines: 5,
                    cursorColor: themes.isDark.value
                        ? Colors.white
                        : ColorPallete.primaryColor,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: themes.isDark.value
                          ? Colors.grey.withOpacity(0.1)
                          : Colors.grey.shade100,
                      border: UnderlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width * 0.8,
                        maxWidth: MediaQuery.of(context).size.width * 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  MaterialButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    color: ColorPallete.primaryColor,
                    onPressed: () async {
                      await updateSignature(signatureController.text);
                      Navigator.of(context).pop();
                    },
                    elevation: 0,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: const Center(
                        child: Text(
                          "Update",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor:
            themes.isDark.value ? ColorPallete.darkModeColor : Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor:
              themes.isDark.value ? ColorPallete.darkModeColor : Colors.white,
          systemOverlayStyle: Platform.isAndroid
              ? SystemUiOverlayStyle(
                  statusBarColor: !themes.isDark.value
                      ? Colors.white
                      : ColorPallete.darkModeColor,
                  statusBarBrightness:
                      !themes.isDark.value ? Brightness.dark : Brightness.light,
                  statusBarIconBrightness:
                      !themes.isDark.value ? Brightness.dark : Brightness.light,
                )
              : null,
          title: Text(
            "Settings",
            style: TextStyle(
              fontSize: 16,
              color: themes.isDark.value ? Colors.white : Colors.black,
            ),
          ),
          iconTheme: IconThemeData(
            color: themes.isDark.value ? Colors.white : Colors.black,
          ),
        ),
        body: Column(
          children: [
            // Toggling Theme

            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: SwitchListTile(
            //     dense: true,
            //     activeColor: ColorPallete.primaryColor,
            //     value: themes.isDark.value,
            //     tileColor: Colors.grey.withOpacity(0.2),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(6),
            //     ),
            //     onChanged: (val) {
            //       themes.toggle(val);
            //     },
            //     secondary: Icon(
            //       themes.isDark.value ? FontAwesome.moon_o : Feather.sun,
            //       size: 22,
            //       color: themes.isDark.value ? Colors.white : Colors.black87,
            //     ),
            //     title: Text(
            //       "Toggle Theme",
            //       style: TextStyle(
            //         fontSize: 14,
            //         color: themes.isDark.value ? Colors.white : Colors.black,
            //         fontWeight: FontWeight.w500,
            //       ),
            //     ),
            //   ),
            // ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SwitchListTile.adaptive(
                dense: true,
                activeColor: ColorPallete.primaryColor,
                value: config.isOpenInApp.value,
                tileColor: Colors.grey.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                onChanged: (val) {
                  config.toggle(val);
                },
                secondary: Icon(
                  Ionicons.open_outline,
                  size: 22,
                  color: themes.isDark.value ? Colors.white : Colors.black87,
                ),
                title: Text(
                  "Open web links in OneMail",
                  style: TextStyle(
                    fontSize: 14,
                    color: themes.isDark.value ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Signature

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                tileColor: Colors.grey.withOpacity(0.2),
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                leading: Icon(
                  FontAwesome5Solid.signature,
                  size: 22,
                  color: themes.isDark.value ? Colors.white : Colors.black87,
                ),
                onTap: () async {
                  showSignatureDialog();
                },
                title: Text(
                  "Signature",
                  style: TextStyle(
                    fontSize: 14,
                    color: themes.isDark.value ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Export Logs

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                tileColor: Colors.grey.withOpacity(0.2),
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                leading: Icon(
                  Ionicons.help,
                  size: 22,
                  color: themes.isDark.value ? Colors.white : Colors.black87,
                ),
                onTap: () async {
                  locator<NavigationService>()
                      .navigateTo(const HelpAndSupport());
                },
                title: Text(
                  "Help and Support",
                  style: TextStyle(
                    fontSize: 14,
                    color: themes.isDark.value ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                tileColor: Colors.grey.withOpacity(0.2),
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                leading: Icon(
                  AntDesign.export,
                  size: 22,
                  color: themes.isDark.value ? Colors.white : Colors.black87,
                ),
                onTap: () async {
                  saveLogs();
                },
                title: Text(
                  "Export Logs",
                  style: TextStyle(
                    fontSize: 14,
                    color: themes.isDark.value ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Toggling open in app browser
          ],
        ),
      ),
    );
  }
}
