import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:oneMail/Model/contacts_model.dart';
import 'package:oneMail/Model/theme_model.dart';
import 'package:oneMail/Screen/Contacts/get_all_contact_email_screen.dart';
import 'package:oneMail/Utils/color_pallet.dart';
import 'package:oneMail/Utils/get_avatar.dart';
import 'package:oneMail/Utils/navigation_route.dart';
import 'package:oneMail/main.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({Key? key}) : super(key: key);

  @override
  _ContactsState createState() => _ContactsState();
}

class _ContactsState extends State<ContactScreen> {
  final Themes themes = Get.find(tag: 'theme');
  final RxList<String> contactHeader = <String>[].obs;
  final RxMap<String, RxList<Contacts>> contactMap =
      <String, RxList<Contacts>>{}.obs;

  @override
  initState() {
    getContacts();
    super.initState();
  }

  @override
  dispose() {
    contactHeader.clear();
    contactMap.clear();
    super.dispose();
  }

  Widget contactTiles() {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              "Search by Contacts",
              style: TextStyle(
                fontSize: 16.5,
                color: themes.isDark.value ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ListView.builder(
            itemCount: contactHeader.length,
            shrinkWrap: true,
            itemBuilder: (context, idx) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.grey.withOpacity(0.15),
                    width: MediaQuery.of(context).size.width,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 20.0,
                        top: 2.0,
                        bottom: 2.0,
                      ),
                      child: Text(
                        contactHeader[idx].toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          color: themes.isDark.value
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: contactMap[contactHeader[idx]]!.length,
                    itemBuilder: (context, index) {
                      return contactTile(
                        contactMap[contactHeader[idx]]![index],
                      );
                    },
                  )
                ],
              );
            },
          ),
        ],
      );
    });
  }

  getContacts() async {
    bool checkPermission = await Permission.contacts.isGranted;

    if (!checkPermission) {
      PermissionStatus status = await Permission.contacts.request();
      if (!status.isGranted) return;
    }

    List<Contact> contacts = await FlutterContacts.getContacts(
      withProperties: true,
    );

    List<Contacts> cacheContacts = [];
    for (Contact contact in contacts) {
      if (contact.emails.isNotEmpty) {
        cacheContacts.add(
          Contacts(
            contact.emails.first.address,
            contact.photoOrThumbnail.toString(),
            contact.displayName,
          ),
        );
      }
    }

    for (Contacts contact in cacheContacts) {
      if (contactMap.containsKey(contact.name[0].toLowerCase())) {
        contactMap[contact.name[0].toLowerCase()]!.add(contact);
      } else {
        contactMap[contact.name[0].toLowerCase()] = <Contacts>[].obs;
        contactMap[contact.name[0].toLowerCase()]!.add(contact);
      }
    }
    contactHeader.addAll(contactMap.keys);
    contactHeader.sort((a, b) => a.compareTo(b));
  }

  Widget contactTile(Contacts contacts) {
    TextStyle titleStyle = TextStyle(
      fontSize: 16,
      color: themes.isDark.value ? Colors.white : Colors.black,
    );

    return ListTile(
      dense: true,
      onTap: () => locator<NavigationService>().navigateTo(
        GetAllContacts(
          contacts: Contacts(
            contacts.email,
            null,
            contacts.name,
          ),
        ),
      ),
      leading: CircleAvatar(
        backgroundColor: colors[contacts.email.hashCode % colors.length],
        child: Text(
          contacts.email[0].toUpperCase(),
          style: TextStyle(
            color: textColors[contacts.email.hashCode % textColors.length],
            fontSize: 20,
          ),
        ),
      ),
      title: Text(
        contacts.name,
        style: titleStyle,
      ),
      subtitle: Text(
        contacts.email,
        style: titleStyle.copyWith(
          fontSize: 15.5,
          color: themes.isDark.value ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          "Contacts",
          style: TextStyle(
            fontSize: 16,
            color: themes.isDark.value ? Colors.white : Colors.black,
          ),
        ),
        iconTheme: IconThemeData(
          color: themes.isDark.value ? Colors.white : Colors.black,
        ),
      ),
      body: contactTiles(),
    );
  }
}
