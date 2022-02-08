import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:intl/intl.dart';
import 'package:oneMail/Controller/base_controller.dart';
import 'package:oneMail/Model/email_model.dart';
import 'package:oneMail/Screen/Details/chat_screen.dart';
import 'package:oneMail/Screen/Details/email_screen.dart';
import 'package:oneMail/Services/email_service.dart';
import 'package:oneMail/Utils/color_pallet.dart';
import 'package:oneMail/Utils/get_avatar.dart';
import 'email_tiles_action.dart';
import 'package:html/parser.dart';
import 'package:get/get.dart';

_openMail(
  Email email,
  BuildContext context,
  Services services,
  int index,
  BaseController controller, {
  Mailbox? mailbox,
  required bool openChat,
}) async {
  if (openChat) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          email: email,
          index: index,
          mailbox: mailbox,
          controller: controller,
        ),
      ),
    );
  } else {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Details(
          email: email,
          mailbox: mailbox,
          controller: controller,
        ),
      ),
    );
  }
  services.setSeen(email.mimeMessage, true);
  email.isSeen.value = true;
}

_displayTime(Email email, bool isDark) {
  DateTime time = email.mimeMessage.decodeDate() ?? DateTime.now();
  return (time.day == DateTime.now().day &&
          time.month == DateTime.now().month &&
          time.year == DateTime.now().year)
      ? Text(
          DateFormat('hh:mm a').format(time),
          style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black,
              fontWeight:
                  !email.isSeen.value ? FontWeight.w600 : FontWeight.normal),
        )
      : Text(
          DateFormat('d MMM').format(email.mimeMessage.decodeDate()!),
          style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black,
              fontWeight:
                  !email.isSeen.value ? FontWeight.w600 : FontWeight.normal),
        );
}

Future<bool?> _confirmDismiss(
    DismissDirection direction,
    Services services,
    BuildContext context,
    Email email,
    BaseController controller,
    int index,
    bool isDark,
    RxInt count,
    Mailbox? mailbox) async {
  if (direction == DismissDirection.endToStart) {
    controller.emails.removeAt(index);
    delete(email, services, mailbox, context, isDark, controller, index);
    count.value--;
    return true;
  } else {
    bool isSeen = email.isSeen.value;
    email.isSeen.value = !isSeen;
    services.setSeen(email.mimeMessage, !isSeen);
    return false;
  }
}

delete(Email email, Services services, Mailbox? mailbox, BuildContext context,
    bool isDark, BaseController controller, int index) {
  services.deleteMessage(email.mimeMessage, mailbox).then(
    (result) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: isDark ? const Color(0xff1E1E1E) : Colors.white,
            content: Text(
              "Moved to Trash",
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            duration: const Duration(seconds: 5),
            dismissDirection: DismissDirection.horizontal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            action: SnackBarAction(
              label: "UNDO",
              textColor: ColorPallete.primaryColor,
              onPressed: () {
                services.mailClient.undoDeleteMessages(result);
                controller.emails.insert(index, email);
              },
            ),
          ),
        );
      }
    },
  );
}

_selectTiles(BaseController controller, int index, RxInt count) {
  controller.selectionModeEnable.value = true;
  if (controller.emails[index].isSelect.value) {
    count.value += -1;
    controller.emails[index].isSelect.value = false;
    return;
  } else {
    count.value += 1;
    controller.emails[index].isSelect.value = true;
  }
}

Widget _leading(
        bool isDark, Email email, BaseController controller, int index) =>
    getAvatar(email.mimeMessage.fromEmail, isDark);

Widget _title(Email email, bool isDark) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            email.mimeMessage.decodeSender().first.personalName ??
                email.mimeMessage.fromEmail ??
                "",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              color: !isDark ? Colors.black : Colors.white,
              fontWeight:
                  !email.isSeen.value ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Row(
          children: [
            _displayTime(email, isDark),
            email.mimeMessage.hasAttachments()
                ? const Padding(
                    padding: EdgeInsets.only(left: 10.0),
                    child: Icon(
                      MaterialCommunityIcons.attachment,
                      size: 25,
                    ),
                  )
                : Container()
          ],
        )
      ],
    );

Widget emailTiles(
  BuildContext context,
  BaseController controller,
  int index,
  bool isDark,
  RxInt count,
  Mailbox? mailbox, {
  bool isSelectable = true,
  required bool openChat,
}) {
  final Email email = controller.emails[index];
  return Obx(
    () => _body(
      email,
      context,
      controller,
      index,
      isDark,
      count,
      mailbox,
      isSelectable: isSelectable,
      openChat: openChat,
    ),
  );
}

Widget _body(
  Email email,
  BuildContext context,
  BaseController controller,
  int index,
  bool isDark,
  RxInt count,
  Mailbox? mailbox, {
  bool? isSelectable,
  required openChat,
}) {
  if (isSelectable != null && isSelectable) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
      child: Dismissible(
        background: slideRightBackground(),
        secondaryBackground: slideLeftBackground(),
        key: Key(
          email.mimeMessage.toString(),
        ),
        confirmDismiss: (DismissDirection direction) => _confirmDismiss(
          direction,
          controller.services,
          context,
          email,
          controller,
          index,
          isDark,
          count,
          mailbox,
        ),
        child: InkWell(
          onTap: () => controller.selectionModeEnable.value
              ? _selectTiles(
                  controller,
                  index,
                  count,
                )
              : _openMail(
                  email,
                  context,
                  controller.services,
                  index,
                  controller,
                  mailbox: mailbox,
                  openChat: openChat,
                ),
          onLongPress: () {
            count.value = 0;

            _selectTiles(
              controller,
              index,
              count,
            );
          },
          highlightColor: Colors.grey.withOpacity(0.2),
          splashColor: Colors.grey.withOpacity(0.2),
          hoverColor: Colors.grey.withOpacity(0.2),
          focusColor: Colors.grey.withOpacity(0.2),
          child: ListTile(
            tileColor: isDark ? ColorPallete.darkModeColor : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            enableFeedback: true,
            leading: _leading(isDark, email, controller, index),
            title: _title(email, isDark),
            subtitle: _subtitle(email, isDark, controller, context),
            selected:
                controller.selectionModeEnable.value && email.isSelect.value,
            selectedTileColor: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
    );
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        onTap: () => controller.selectionModeEnable.value
            ? _selectTiles(controller, index, count)
            : _openMail(email, context, controller.services, index, controller,
                mailbox: mailbox, openChat: openChat),
        leading: _leading(
          isDark,
          email,
          controller,
          index,
        ),
        title: _title(
          email,
          isDark,
        ),
        subtitle: _subtitle(
          email,
          isDark,
          controller,
          context,
        ),
        selected: controller.selectionModeEnable.value && email.isSelect.value,
        selectedTileColor: Colors.grey.withOpacity(0.2),
      ),
    ),
  );
}

String parseHtmlString(String htmlString) {
  final document = parse(htmlString);
  var parsedString = parse(document.body!.text)
      .documentElement!
      .text
      .replaceAll('\t', '')
      .replaceAll('\r', '')
      .replaceAll('\n', '')
      .replaceAll(RegExp(' +'), ' ')
      .trim();
  return parsedString;
}

Widget _subtitle(
  Email email,
  bool isDark,
  BaseController controller,
  BuildContext context,
) {
  return Padding(
    padding: const EdgeInsets.only(top: 0.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 3,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: SizedBox(
                width: MediaQuery.of(context).size.width / 1.4,
                child: Text(
                  email.mimeMessage.decodeSubject() != null
                      ? email.mimeMessage.decodeSubject()!.isNotEmpty
                          ? email.mimeMessage.decodeSubject()!.trim()
                          : "(No Subject)"
                      : "(No Subject)",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: !email.isSeen.value
                        ? FontWeight.w500
                        : FontWeight.normal,
                    color: !isDark ? Colors.black87 : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 2,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                email.mimeMessage.decodeTextPlainPart() != null &&
                        email.mimeMessage.decodeTextPlainPart()!.isNotEmpty
                    ? email.mimeMessage
                        .decodeTextPlainPart()!
                        .replaceAll('\n', ' ')
                        .replaceAll('\r', ' ')
                        .replaceAll('\t', ' ')
                        .replaceAll(RegExp(' +'), ' ')
                        .trim()
                    : email.mimeMessage.decodeTextHtmlPart() != null &&
                            email.mimeMessage.decodeTextHtmlPart()!.isNotEmpty
                        ? parseHtmlString(
                            email.mimeMessage.decodeTextHtmlPart()!)
                        : "No Body",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: !isDark ? Colors.black87 : Colors.white70,
                ),
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            Obx(
              () => InkWell(
                onTap: () async {
                  final bool isFlag = email.isFlag.value;
                  email.isFlag.value = !email.isFlag.value;
                  await controller.services.setFlagged(
                    email.mimeMessage,
                    isFlag,
                  );
                },
                child: !email.isFlag.value
                    ? Icon(
                        AntDesign.staro,
                        size: 22,
                        color: isDark ? Colors.white : Colors.black87,
                      )
                    : Icon(
                        AntDesign.star,
                        color: ColorPallete.primaryColor,
                        size: 22,
                      ),
              ),
            )
          ],
        )
      ],
    ),
  );
}
