// ignore_for_file: file_names
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oneMail/Controller/base_controller.dart';
import 'package:oneMail/Model/email_model.dart';
import 'package:oneMail/Model/forward_email_model.dart';
import 'package:oneMail/Screen/Compose/compose_email_screen.dart';
import 'package:oneMail/Screen/Details/bottomModalSheet.dart';
import 'package:oneMail/Screen/Details/email_screen.dart';
import 'package:oneMail/Screen/Homepage/Components/email_tiles.dart';
import 'package:oneMail/Services/email_service.dart';
import 'package:oneMail/Utils/color_pallet.dart';
import 'package:oneMail/Utils/get_avatar.dart' as avatar;
import 'package:oneMail/Utils/navigation_route.dart';
import '../../main.dart';
import 'attachment_chip.dart';

Widget buildAttachments(List<ContentInfo> attachments, Email email) {
  return Column(
    children: [
      const SizedBox(
        height: 5,
      ),
      for (ContentInfo attachment in attachments) ...{
        AttachmentChip(info: attachment, message: email)
      }
    ],
  );
}

Widget chatUI(
  BuildContext context,
  Email email,
  String currUser,
  Mailbox? mailbox,
  bool isDark,
  BaseController controller,
  Services services,
) {
  final attachments = email.attachments;
  String from = email.mimeMessage.fromEmail!;
  if (currUser != from) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar.getAvatar(email.mimeMessage.fromEmail, isDark),
              Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () => locator<NavigationService>().navigateTo(
                    Details(
                      email: email,
                      mailbox: mailbox,
                      controller: controller,
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: 150,
                      minWidth: MediaQuery.of(context).size.width / 1.5,
                      maxWidth: MediaQuery.of(context).size.width / 1.5,
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width / 1.5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              email.mimeMessage.from!.first.personalName ??
                                  email.mimeMessage.fromEmail!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              DateFormat('hh:mm a dd-MMM-yyyy').format(
                                  email.mimeMessage.decodeDate() ??
                                      DateTime.now()),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              email.mimeMessage.decodeTextHtmlPart() != null
                                  ? parseHtmlString(
                                      email.mimeMessage.decodeTextHtmlPart()!)
                                  : email.mimeMessage.decodeContentText() ??
                                      "No Body",
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            buildAttachments(attachments, email),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    child: IconButton(
                      onPressed: () {
                        openBottomDrawer(
                          context,
                          email,
                          [],
                          isDark,
                          services,
                          mailbox,
                          controller: controller,
                          isIndividual: true,
                        );
                      },
                      icon: Icon(
                        Icons.more_vert_outlined,
                        color:
                            isDark ? Colors.white : ColorPallete.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 7,
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    child: IconButton(
                      onPressed: () {
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
                      icon: Icon(
                        Icons.reply,
                        color:
                            isDark ? Colors.white : ColorPallete.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 7,
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    child: IconButton(
                      onPressed: () {
                        List<Attachment> attachments = [];

                        for (var attachment in email.attachments) {
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
                      icon: Icon(
                        Icons.forward,
                        color:
                            isDark ? Colors.white : ColorPallete.primaryColor,
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: GestureDetector(
      onTap: () => locator<NavigationService>().navigateTo(
        Details(
          email: email,
          mailbox: mailbox,
          controller: controller,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    child: IconButton(
                      onPressed: () {
                        openBottomDrawer(
                          context,
                          email,
                          [],
                          isDark,
                          services,
                          mailbox,
                          controller: controller,
                          isIndividual: true,
                        );
                      },
                      icon: Icon(
                        Icons.more_vert_outlined,
                        color:
                            isDark ? Colors.white : ColorPallete.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 7,
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    child: IconButton(
                      onPressed: () {
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
                      icon: Icon(
                        Icons.reply,
                        color:
                            isDark ? Colors.white : ColorPallete.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 7,
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    child: IconButton(
                      onPressed: () {
                        List<Attachment> attachments = [];

                        for (var attachment in email.attachments) {
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
                      icon: Icon(
                        Icons.forward,
                        color:
                            isDark ? Colors.white : ColorPallete.primaryColor,
                      ),
                    ),
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: 150,
                    minWidth: MediaQuery.of(context).size.width / 1.5,
                    maxWidth: MediaQuery.of(context).size.width / 1.5,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email.mimeMessage.from!.first.personalName ??
                                email.mimeMessage.fromEmail!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            DateFormat('hh:mm a dd-MMM-yyyy').format(
                                email.mimeMessage.decodeDate() ??
                                    DateTime.now()),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            email.mimeMessage.decodeTextHtmlPart() != null
                                ? parseHtmlString(
                                    email.mimeMessage.decodeTextHtmlPart()!)
                                : email.mimeMessage.decodeContentText() ??
                                    "No Body",
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: buildAttachments(attachments, email),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              avatar.getAvatar(email.mimeMessage.fromEmail, isDark),
            ],
          ),
        ],
      ),
    ),
  );
}
