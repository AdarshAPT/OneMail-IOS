// ignore_for_file: file_names
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:oneMail/Controller/base_controller.dart';
import 'package:oneMail/Controller/email_controller.dart';
import 'package:oneMail/Controller/pin_message_controller.dart';
import 'package:oneMail/Model/email_model.dart';
import 'package:oneMail/Model/forward_email_model.dart';
import 'package:oneMail/Model/gmail_model.dart';
import 'package:oneMail/Notification/gmailAPI.dart';
import 'package:oneMail/Screen/Compose/compose_email_screen.dart';
import 'package:oneMail/Services/email_service.dart';
import 'package:oneMail/Utils/color_pallet.dart';
import 'package:oneMail/Utils/logger.dart';
import 'package:oneMail/Utils/navigation_route.dart';
import 'package:oneMail/main.dart';
import 'package:share/share.dart';
import 'package:oneMail/Utils/get_icon.dart';

Future<bool> showDeleteConfirmationDialog(
    BuildContext context, int length, bool isDark) async {
  bool? res = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDark ? ColorPallete.darkModeColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      title: Text(
        "Delete",
        style: TextStyle(
          fontSize: 16,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$length conversations will be deleted",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
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
                    onTap: () => Navigator.of(context).pop(false),
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
                  InkWell(
                    onTap: () => Navigator.of(context).pop(true),
                    child: Text(
                      "Delete",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: ColorPallete.primaryColor),
                    ),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    ),
  );

  if (res == null) return false;

  return res;
}

showMailbox(
  Mailbox? currMailbox,
  BuildContext context,
  BaseController baseController,
  String mailboxName,
  bool isDark,
  Services services,
  Email email,
) {
  final GetEmailController emailController = Get.find(tag: "emailController");
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: isDark ? ColorPallete.darkModeColor : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Move to",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(
                height: 5,
              ),
              ListView.builder(
                  itemCount: emailController.mailboxList.length,
                  shrinkWrap: true,
                  itemBuilder: (context, i) {
                    if (!emailController.mailboxList[i].hasChildren &&
                        mailboxName !=
                            emailController.mailboxList[i].encodedName
                                .toLowerCase()) {
                      return ListTile(
                        leading: Icon(
                          getIcon(emailController.mailboxList[i].encodedName),
                          size: 22,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        minLeadingWidth: 10,
                        onTap: () => moveToMailbox(
                          currMailbox,
                          emailController.mailboxList[i],
                          context,
                          services,
                          email,
                          baseController,
                        ),
                        dense: true,
                        title: Text(
                          emailController
                              .mailboxList[i].encodedName.capitalizeFirst!,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    }
                    return Container();
                  })
            ],
          ),
        ),
      );
    },
  );
}

Future<void> deleteMessage(
  BuildContext context,
  Email email,
  Services services,
  Mailbox? mailbox,
) async {
  try {
    if (mailbox == null) {
      logSuccess("Inbox is selected");
      await services.mailClient.selectInbox();
    } else {
      logSuccess("${mailbox.encodedName} is selected");
      await services.mailClient.selectMailbox(mailbox);
    }
    await services.mailClient.deleteMessage(email.mimeMessage);
  } catch (e) {
    logError(e.toString());
  }
}

moveToMailbox(Mailbox? currMailbox, Mailbox mailbox, BuildContext context,
    Services services, Email email, BaseController emailController) async {
  Navigator.of(context).pop();
  if (currMailbox == null) {
    await services.mailClient.selectInbox();
  } else {
    await services.mailClient.selectMailbox(currMailbox);
  }
  bool result = await services.moveToMailbox(email.mimeMessage, mailbox);

  if (result) {
    int index = emailController.emails.indexWhere((element) =>
        element.mimeMessage.decodeDate() == email.mimeMessage.decodeDate() &&
        element.mimeMessage.decodeSubject() ==
            email.mimeMessage.decodeSubject());
    if (index != -1) {
      emailController.emails.removeAt(index);
    } else {
      logError("not found");
    }
    Fluttertoast.showToast(
        msg: "Email moved to ${mailbox.encodedName.capitalizeFirst}");
  } else {
    Fluttertoast.showToast(msg: "Failed to move email");
  }
}

openGmailDrawer(
  BuildContext context,
  Gmail email,
  bool isDark,
) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(10),
        topRight: Radius.circular(10),
      ),
    ),
    backgroundColor: isDark ? ColorPallete.darkModeColor : Colors.white,
    builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: () {
                    locator<NavigationService>().navigateTo(
                      ComposeEmail(
                        isReply: true,
                        subject: email.subject.replaceAll("Re:", ""),
                        to: [email.from],
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    child: Icon(
                      Icons.reply,
                      color: ColorPallete.primaryColor,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    await GmailAPI().deleteEmail(email.id, email.refreshToken);
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    child: Icon(
                      IconlyBold.delete,
                      color: ColorPallete.primaryColor,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () async {},
                  child: CircleAvatar(
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    child: Icon(
                      email.isFlag ? AntDesign.star : AntDesign.staro,
                      color: ColorPallete.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
              onTap: () async {
                Navigator.of(context).pop();
                bool hasHTML =
                    email.htmlPart != null && email.htmlPart!.isNotEmpty;
                if (hasHTML) {
                  await Share.share(parseHtmlString(email.htmlPart!),
                      subject: email.subject);
                } else {
                  await Share.share(
                    email.textPart!,
                    subject: email.subject,
                  );
                }
              },
              title: Row(
                children: [
                  Icon(
                    AntDesign.sharealt,
                    color: ColorPallete.primaryColor,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    "Share",
                    style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black),
                  )
                ],
              )),
        ],
      );
    },
  );
}

void deleteFromReply(Email email) {
  try {
    final RxList<Email> reply = Get.find(tag: 'replies');
    logSuccess(reply.length.toString());
    int index = reply.indexWhere((element) =>
        element.mimeMessage.decodeDate() == email.mimeMessage.decodeDate() &&
        element.mimeMessage.decodeSubject() ==
            email.mimeMessage.decodeSubject());
    reply.removeAt(index);
  } catch (e) {
    logError(e.toString());
  }
}

void removeEmailFromController(Email email, BaseController controller) {
  int index = controller.emails.indexWhere(
    (element) =>
        element.mimeMessage.decodeDate()! == email.mimeMessage.decodeDate()! &&
        element.mimeMessage.decodeSubject()! ==
            email.mimeMessage.decodeSubject()!,
  );
  if (index != -1) {
    controller.emails.removeAt(index);
  } else {
    logError("not found");
  }
}

openBottomDrawer(
  BuildContext context,
  Email email,
  List<Email>? listOfEmails,
  bool isDark,
  Services services,
  Mailbox? mailbox, {
  List<ContentInfo> listOfAttachment = const [],
  required BaseController controller,
  required bool isIndividual,
}) {
  final PinMessagesController pinMessagesController = PinMessagesController();

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(10),
        topRight: Radius.circular(10),
      ),
    ),
    backgroundColor: isDark ? ColorPallete.darkModeColor : Colors.white,
    builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          isIndividual
              ? Container(
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      InkWell(
                        onTap: () {
                          locator<NavigationService>().navigateTo(
                            ComposeEmail(
                              isReply: true,
                              subject: email.mimeMessage
                                  .decodeSubject()!
                                  .replaceAll("Re: ", ""),
                              to: [email.mimeMessage.fromEmail!],
                            ),
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          child: Icon(
                            Icons.reply,
                            color: isDark
                                ? Colors.white
                                : ColorPallete.primaryColor,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          List<Attachment> attachments = [];

                          for (var attachment in listOfAttachment) {
                            attachments.add(
                              Attachment(
                                email.mimeMessage
                                    .getPart(attachment.fetchId)!
                                    .decodeContentBinary()!,
                                attachment.fileName!,
                              ),
                            );
                          }

                          locator<NavigationService>().navigateTo(
                            ComposeEmail(
                              forwardMail: ForwardModel(
                                email.mimeMessage.from
                                    .toString()
                                    .replaceAll('[', '')
                                    .replaceAll(']', '')
                                    .replaceAll('"', ''),
                                email.mimeMessage.decodeDate()!,
                                email.mimeMessage.decodeSubject() ?? '',
                                email.mimeMessage.to
                                    .toString()
                                    .replaceAll('[', '')
                                    .replaceAll(']', '')
                                    .replaceAll('"', ''),
                                attachments,
                                email.mimeMessage.decodeTextHtmlPart() ??
                                    email.mimeMessage.decodeTextPlainPart() ??
                                    '',
                                email.mimeMessage.cc
                                    .toString()
                                    .replaceAll('[', '')
                                    .replaceAll(']', '')
                                    .replaceAll('"', ''),
                              ),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          child: Icon(
                            Icons.forward,
                            color: isDark
                                ? Colors.white
                                : ColorPallete.primaryColor,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          bool res = await showDeleteConfirmationDialog(
                            context,
                            listOfEmails != null && listOfEmails.isNotEmpty
                                ? listOfEmails.length
                                : 1,
                            isDark,
                          );
                          if (res) {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();

                            if (listOfEmails != null &&
                                listOfEmails.isNotEmpty) {
                              deleteFromReply(email);
                              for (Email email in listOfEmails) {
                                try {
                                  removeEmailFromController(email, controller);
                                } catch (e) {
                                  logError(e.toString());
                                }
                                await deleteMessage(
                                  context,
                                  email,
                                  services,
                                  mailbox,
                                );
                              }
                            } else {
                              try {
                                deleteFromReply(email);
                                removeEmailFromController(email, controller);
                              } catch (e) {
                                logError(e.toString());
                              }
                              await deleteMessage(
                                context,
                                email,
                                services,
                                mailbox,
                              );
                            }
                            Fluttertoast.showToast(msg: "Email moved to trash");
                          }
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          child: Icon(
                            IconlyBold.delete,
                            color: isDark
                                ? Colors.white
                                : ColorPallete.primaryColor,
                          ),
                        ),
                      ),
                      // Obx(
                      //   () => InkWell(
                      //     onTap: () async {
                      //       final bool isFlag = email.isFlag.value;
                      //       email.isFlag.value = !email.isFlag.value;

                      //       await services.setFlagged(
                      //         email.mimeMessage,
                      //         isFlag,
                      //       );
                      //       int index = controller.emails.indexWhere(
                      //         (element) =>
                      //             element.mimeMessage.decodeDate()! ==
                      //                 email.mimeMessage.decodeDate()! &&
                      //             element.mimeMessage.decodeSubject()! ==
                      //                 email.mimeMessage.decodeSubject()!,
                      //       );

                      //       if (index == -1) {
                      //         return;
                      //       }

                      //       logSuccess("found");

                      //       controller.emails.elementAt(index).isFlag.value =
                      //           !isFlag;
                      //     },
                      //     child: CircleAvatar(
                      //       backgroundColor: Colors.grey.withOpacity(0.2),
                      //       child: Icon(
                      //         email.isFlag.value
                      //             ? AntDesign.star
                      //             : AntDesign.staro,
                      //         color: isDark
                      //             ? Colors.white
                      //             : ColorPallete.primaryColor,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                )
              : Container(),
          ListTile(
              onTap: () async {
                Navigator.of(context).pop();
                bool hasHTML = email.mimeMessage.decodeTextHtmlPart() != null &&
                    email.mimeMessage.decodeTextHtmlPart()!.isNotEmpty;
                if (hasHTML) {
                  await Share.share(
                      parseHtmlString(email.mimeMessage.decodeTextHtmlPart()!),
                      subject:
                          email.mimeMessage.decodeSubject() ?? "(No Subject)");
                } else {
                  await Share.share(email.mimeMessage.decodeTextPlainPart()!,
                      subject:
                          email.mimeMessage.decodeSubject() ?? "(No Subject)");
                }
              },
              title: Row(
                children: [
                  Icon(
                    AntDesign.sharealt,
                    color: isDark ? Colors.white : ColorPallete.primaryColor,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    "Share",
                    style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black),
                  )
                ],
              )),
          ListTile(
              onTap: () async {
                await pinMessagesController.addIndividualPinMessage(email);
                Navigator.of(context).pop();
              },
              title: Row(
                children: [
                  SvgPicture.asset(
                    "assets/pin.svg",
                    height: 20,
                    color: isDark ? Colors.white : ColorPallete.primaryColor,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    "Pin",
                    style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black),
                  )
                ],
              )),
          ListTile(
              onTap: () {
                Navigator.of(context).pop();
                showMailbox(
                  mailbox,
                  context,
                  controller,
                  mailbox != null ? mailbox.encodedName : "inbox",
                  isDark,
                  services,
                  email,
                );
              },
              title: Row(
                children: [
                  SvgPicture.asset(
                    "assets/move.svg",
                    height: 20,
                    color: isDark ? Colors.white : ColorPallete.primaryColor,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    "Move to",
                    style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black),
                  )
                ],
              )),
        ],
      );
    },
  );
}
