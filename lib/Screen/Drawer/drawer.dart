import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/cupertino.dart';
import 'package:oneMail/Utils/color_pallet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/get.dart';
import 'package:oneMail/Model/theme_model.dart';
import 'package:oneMail/Model/user_model.dart';
import 'package:oneMail/Screen/Contacts/contact_screen.dart';
import 'package:oneMail/Screen/Pin%20Screen/pin_screen.dart';
import 'package:oneMail/Screen/Settings/config.dart';
import 'package:oneMail/Screen/Settings/settings.dart';
import 'package:oneMail/Services/storage_service.dart';
import 'package:oneMail/Services/email_service.dart';
import 'package:oneMail/Utils/custom_glow_behaviour.dart';
import 'package:oneMail/Utils/get_icon.dart';
import 'package:oneMail/Screen/AddAccount/add_account.dart';
import 'package:oneMail/Screen/Drawer/drawer_list.dart';
import 'package:oneMail/Screen/Homepage/homepage.dart';
import 'package:oneMail/Screen/Labels/mail_box_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:oneMail/Utils/navigation_route.dart';
import 'package:oneMail/main.dart';
import 'show_create_mail_box_dialog.dart';
import '/Utils/navigation_route.dart';

void openFolder(BuildContext context, Mailbox mailbox) {
  locator<NavigationService>().navigateTo(
    MailboxScreen(mailbox: mailbox),
  );
}

Future<List<User>> getUsers() async {
  final SecureStorage _storage = SecureStorage();
  List<User> users = await _storage.getUser();
  return users;
}

void logout(BuildContext context) async {
  final SecureStorage _storage = SecureStorage();
  await _storage.logout(context);
}

void handleAccountChange(
    User selectedUser, Themes themes, User user, BuildContext context) async {
  if (selectedUser.emailAddress != user.emailAddress) {
    await Get.deleteAll(force: true);
    Get.put(Services(), tag: "services");
    Get.put(themes, tag: "theme");
    Get.put(Config(), tag: 'config');
    await SecureStorage().setEmailAddress(selectedUser.emailAddress);
    locator<NavigationService>().navigateTo(
      HomePage(
        user: selectedUser,
      ),
    );
  }
}

Future<bool> confirmLogout(BuildContext context,Themes themes) async {
  final User user = await User.getCurrentUser();
  bool? res = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6)
          ),
          backgroundColor: themes.isDark.value?ColorPallete.darkModeColor:Colors.white,
          title: Text(
                "Confirm",
                style:  TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: themes.isDark.value?Colors.white:Colors.black87,
                ),
              ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Are you sure you want to sign out from the account ${user.emailAddress} ?",
                textAlign: TextAlign.center,
                style:  TextStyle(
                  fontSize: 16,
                  color: themes.isDark.value?Colors.white:Colors.black87,
                ),
              ),
              const SizedBox(
                height: 10,
              )
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  MaterialButton(
                    elevation: 0,
                    highlightElevation: 0,
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    color: ColorPallete.primaryColor,
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  MaterialButton(
                    elevation: 0,
                    highlightElevation: 0,
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    color: ColorPallete.primaryColor,
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: const Text(
                      "Confirm",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      });

  if (res == null || !res) return false;

  return true;
}

showEmailTab(Function handleAccountChange, AsyncSnapshot snapshot, int index,
    bool isDark, User user) {
  return ListTile(
    onTap: () => handleAccountChange(),
    selected: snapshot.data![index].emailAddress == user.emailAddress,
    dense: true,
    selectedTileColor: Colors.grey.withOpacity(0.1),
    shape: const StadiumBorder(),
    title: Text(
      snapshot.data![index].emailAddress,
      style: TextStyle(
        fontSize: 15,
        color: isDark ? Colors.white : Colors.black,
      ),
    ),
  );
}

Widget _header(User user, Themes themes) {
  return Container(
    color: Colors.grey.withOpacity(0.2),
    child: Column(
      children: [
        const SizedBox(
          height: 20,
        ),
        ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(200),
            child: CachedNetworkImage(
              imageUrl: user.userPhotoURL,
              fit: BoxFit.fill,
              height: 80,
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.userName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: themes.isDark.value ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                user.emailAddress,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: themes.isDark.value
                      ? Colors.white70
                      : Colors.grey.shade900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 20,
        ),
      ],
    ),
  );
}

Widget moreOptionList(
    BuildContext context, bool isDark, List<Mailbox> moreOption) {
  return moreOption.isNotEmpty
      ? Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(
              "More",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            iconColor: isDark ? Colors.white : Colors.black,
            collapsedIconColor: isDark ? Colors.white : Colors.black,
            controlAffinity: ListTileControlAffinity.leading,
            children: [
              for (Mailbox mailbox in moreOption) ...{
                drawerMailBox(
                  getIcon(mailbox.encodedName),
                  () => openFolder(context, mailbox),
                  mailbox.encodedName.capitalizeFirst!,
                  isDark,
                  count: mailbox.messagesExists,
                )
              },
            ],
          ),
        )
      : Container();
}

Widget drawer(
    BuildContext context, RxList<Mailbox> mailBox, User user, Themes themes) {
  final isDark = themes.isDark.value;
  final List<Mailbox> moreOption = <Mailbox>[];
  if (user.isGmail) {
    for (Mailbox mailbox in mailBox) {
      if (!mailbox.isInbox &&
          !mailbox.isSent &&
          !mailbox.isTrash &&
          !mailbox.isDrafts) {
        if (!mailbox.hasChildren) {
          moreOption.add(mailbox);
        }
      }
    }
  }

  return SizedBox(
    child: Theme(
      data: Theme.of(context).copyWith(
        canvasColor: isDark ? const Color(0xff121212) : Colors.white,
      ),
      child: Drawer(
        child: SafeArea(
          child: ScrollConfiguration(
            behavior: CustomBehavior(),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _header(user, themes),
                  drawerList(
                      SvgPicture.asset(
                        "assets/pin.svg",
                        height: 22,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      () => locator<NavigationService>().navigateTo(
                            const PinMessageScreen(),
                          ),
                      "Pinned Mails",
                      isDark),
                  drawerList(
                    Icon(
                      Ionicons.ios_create_outline,
                      size: 22,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    () async {
                      showDialog(
                        context: context,
                        builder: (context) => errorDialog(context, isDark),
                      );
                    },
                    "Create Mailbox",
                    isDark,
                  ),
                  drawerList(
                    Icon(
                      CupertinoIcons.collections,
                      size: 22,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    () => locator<NavigationService>()
                        .navigateTo(const ContactScreen()),
                    "Contacts",
                    isDark,
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: mailBox.length,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (_, idx) {
                      final String mailBoxName = mailBox[idx].encodedName;
                      if (user.isGmail) {
                        return mailBox[idx].isInbox ||
                                mailBox[idx].isSent ||
                                mailBox[idx].isTrash
                            ? drawerMailBox(
                                getIcon(mailBoxName),
                                () => openFolder(context, mailBox[idx]),
                                mailBoxName.capitalizeFirst!,
                                isDark,
                                count: mailBox[idx].messagesExists,
                              )
                            : Container();
                      }
                      return drawerMailBox(
                        getIcon(mailBoxName),
                        () => openFolder(context, mailBox[idx]),
                        mailBoxName.capitalizeFirst!,
                        isDark,
                        count: mailBox[idx].messagesExists,
                      );
                    },
                  ),
                  moreOptionList(context, isDark, moreOption),
                  drawerList(
                    Icon(
                      MaterialIcons.add,
                      size: 22,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    () => locator<NavigationService>()
                        .navigateTo(const AddAccount()),
                    "Add Account",
                    isDark,
                  ),
                  Container(
                    color: Colors.grey.withOpacity(0.1),
                    child: Column(
                      children: [
                        drawerList(
                          Icon(
                            Ionicons.settings_outline,
                            size: 22,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          () => locator<NavigationService>().navigateTo(
                            const Settings(),
                          ),
                          "Settings",
                          isDark,
                        ),
                        drawerList(
                          Icon(
                            Feather.info,
                            size: 22,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          () async => await launch(
                              "https://onemail.today/privacyPolicy.html"),
                          "Privacy Policy",
                          isDark,
                        ),
                        drawerList(
                          Icon(
                            Ionicons.ios_exit_outline,
                            size: 22,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          () async {
                            bool result = await confirmLogout(context,themes);
                            if (result) {
                              logout(context);
                            }
                          },
                          "Sign out",
                          isDark,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
