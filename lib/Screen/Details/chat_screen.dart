import 'dart:io';
import 'package:enough_mail/enough_mail.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oneMail/Controller/base_controller.dart';
import 'package:oneMail/Controller/email_controller.dart';
import 'package:oneMail/Controller/pin_message_controller.dart';
import 'package:oneMail/Model/compose_email_model.dart';
import 'package:oneMail/Model/email_model.dart';
import 'package:oneMail/Model/theme_model.dart';
import 'package:oneMail/Model/user_model.dart';
import 'package:oneMail/Screen/Details/bottomModalSheet.dart';
import 'package:oneMail/Screen/Details/chatTile.dart';
import 'package:oneMail/Services/mail_service.dart';
import 'package:oneMail/Services/email_service.dart';
import 'package:oneMail/Utils/color_pallet.dart';
import 'package:oneMail/Utils/custom_glow_behaviour.dart';
import 'package:oneMail/Utils/file_size.dart';
import 'package:oneMail/Utils/logger.dart';
import 'package:thumbnailer/thumbnailer.dart';
import 'package:mime/mime.dart';

class ChatScreen extends StatefulWidget {
  final Email email;
  final Mailbox? mailbox;
  final int index;
  final BaseController controller;
  const ChatScreen(
      {Key? key,
      this.mailbox,
      required this.email,
      required this.index,
      required this.controller})
      : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GetEmailController _emailController = Get.find(tag: 'emailController');
  final PinMessagesController pinMessageController = PinMessagesController();
  final TextEditingController editingController = TextEditingController();
  final ImagePicker _cameraPicker = ImagePicker();
  final Services _services = Get.find(tag: "services");
  final RxList<Email> reply = Get.put(RxList<Email>(), tag: 'replies');
  final RxBool isFetching = false.obs;
  final RxString currUser = "".obs;
  final Themes themes = Themes();
  final RxBool isSending = false.obs;
  final RxList<File> _attachments = <File>[].obs;
  final RxBool isFetchingMore = false.obs;

  Widget _loading(bool isDark) => Platform.isAndroid
      ? Transform.scale(
          scale: 0.4,
          child: CircularProgressIndicator(
            color: isDark ? Colors.white : ColorPallete.primaryColor,
            strokeWidth: 4.0,
          ),
        )
      : const CupertinoActivityIndicator();

  @override
  initState() {
    getAllUser();
    getReplies();
    super.initState();
  }

  @override
  dispose() {
    pinMessageController.dispose();
    editingController.dispose();
    _attachments.close();
    isFetching.close();
    isFetchingMore.close();
    reply.clear();
    Get.delete(tag: 'replies');
    logSuccess('disposed');
    super.dispose();
  }

  attachCamera() async {
    final XFile? photo =
        await _cameraPicker.pickImage(source: ImageSource.camera);

    if (photo == null) return;

    _attachments.add(
      File(photo.path),
    );
  }

  attachFile() async {
    FilePickerResult? files = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'pdf',
          'doc',
          'xlxs',
          'ppt',
          'png',
          'xls',
          'xlsx',
          'xlsm',
          'txt',
          'csv',
          'mp4',
          'mp3',
        ]);

    if (files != null) {
      for (PlatformFile file in files.files) {
        _attachments.add(File(file.path!));
      }
    }
  }

  getAllUser() async {
    User user = await User.getCurrentUser();
    currUser.value = user.emailAddress;
  }

  sendReply() async {
    isSending.value = true;
    User user = await User.getCurrentUser();
    await SendMail().sendMail(
      ComposeMailModel(
        user,
        [widget.email.mimeMessage.fromEmail!],
        [],
        [],
        _attachments,
        "Re: ${widget.email.mimeMessage.decodeSubject() != null ? widget.email.mimeMessage.decodeSubject()!.replaceAll('Re: ', '') : ''}",
        editingController.text.trim(),
        editingController.text.trim(),
      ),
    );
    editingController.clear();
    isSending.value = false;
    _attachments.clear();
    Navigator.of(context).pop();
  }

  getReplies() async {
    isFetching.value = true;
    try {
      await _services.fetchReply(
          widget.email.mimeMessage.decodeSubject() ?? "No Subject",
          reply,
          widget.mailbox);

      reply.sort(
        (b, a) =>
            b.mimeMessage.decodeDate()!.compareTo(a.mimeMessage.decodeDate()!),
      );
    } catch (e) {}
    isFetching.value = false;
    await Future.delayed(const Duration(seconds: 2));
  }

  getMoreReply() async {
    isFetchingMore.value = true;
    await _services.fetchReply(
      widget.email.mimeMessage.decodeSubject() ?? "No Subject",
      reply,
      widget.mailbox,
    );
    reply.sort(
      (b, a) =>
          b.mimeMessage.decodeDate()!.compareTo(a.mimeMessage.decodeDate()!),
    );
    isFetchingMore.value = false;
  }

  Widget attachmentUI(File attachment) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 2.5,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Thumbnail(
                  mimeType: lookupMimeType(attachment.path)!,
                  widgetSize: MediaQuery.of(context).size.width / 2.5,
                  dataResolver: () async {
                    return await attachment.readAsBytes();
                  },
                  decoration: WidgetDecoration(
                    iconColor: ColorPallete.primaryColor,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                width: MediaQuery.of(context).size.width / 2.5,
                height: 60,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: themes.isDark.value
                          ? const Color(0xff121212).withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      spreadRadius: 3,
                      blurRadius: 3,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                  color: themes.isDark.value
                      ? Colors.grey.shade800
                      : Colors.grey.shade50,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                attachment.path.split('/').last.capitalize!,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  color: themes.isDark.value
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _attachments.remove(attachment);
                              },
                              child: Icon(
                                Icons.cancel,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        FutureBuilder<String>(
                          future: getFileSize(attachment.path, 1),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                snapshot.data!,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  color: themes.isDark.value
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              );
                            }
                            return Container();
                          },
                        )
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  AppBar appBar(BuildContext context, Themes themes, String senderName) =>
      AppBar(
        elevation: 0.5,
        title: Text(
          widget.email.mimeMessage
              .decodeSubject()!
              .replaceAll('Re: ', '')
              .replaceAll('Fwd: ', ''),
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        systemOverlayStyle: Platform.isAndroid
            ? SystemUiOverlayStyle(
                statusBarColor: !themes.isDark.value
                    ? ColorPallete.primaryColor
                    : const Color(0xff121212),
                statusBarBrightness: Brightness.light,
                statusBarIconBrightness: Brightness.light,
              )
            : null,
        backgroundColor: themes.isDark.value
            ? ColorPallete.darkModeColor
            : ColorPallete.primaryColor,
        actions: [
          IconButton(
            onPressed: () => openBottomDrawer(
              context,
              widget.email,
              reply,
              themes.isDark.value,
              _services,
              widget.mailbox,
              controller: widget.controller,
              isIndividual: false,
            ),
            icon: const Icon(Feather.more_vertical),
          )
        ],
      );

  Widget _bottomSheet() {
    return Obx(
      () {
        return Transform.translate(
          offset: Offset(0.0, -1 * MediaQuery.of(context).viewInsets.bottom),
          child: BottomAppBar(
            child: Container(
              decoration: BoxDecoration(
                color: themes.isDark.value
                    ? const Color(0xff292929)
                    : const Color(0xffe5e5e5),
              ),
              child: ScrollConfiguration(
                behavior: CustomBehavior(),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 15.0,
                          right: 15.0,
                          top: 15.0,
                        ),
                        child: TextField(
                          controller: editingController,
                          style: TextStyle(
                            fontSize: 15,
                            color: themes.isDark.value
                                ? Colors.white
                                : Colors.grey.shade900,
                          ),
                          maxLines: null,
                          cursorColor:
                              themes.isDark.value ? Colors.white : Colors.black,
                          decoration: InputDecoration(
                            filled: true,
                            suffixIcon: isSending.value
                                ? _loading(themes.isDark.value)
                                : IconButton(
                                    onPressed: () => sendReply(),
                                    icon: Icon(
                                      IconlyBold.send,
                                      color: themes.isDark.value
                                          ? Colors.white
                                          : ColorPallete.primaryColor,
                                    ),
                                  ),
                            hintText:
                                "Reply to ${widget.email.mimeMessage.from!.first.personalName ?? widget.email.mimeMessage.fromEmail!}",
                            hintStyle: TextStyle(
                              fontSize: 15,
                              color: themes.isDark.value
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            fillColor: themes.isDark.value
                                ? Colors.grey.withOpacity(0.3)
                                : Colors.white,
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        const SizedBox(
                          width: 15,
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          radius: 22,
                          child: IconButton(
                            icon: Icon(
                              Icons.camera_alt,
                              color: themes.isDark.value
                                  ? Colors.white
                                  : ColorPallete.primaryColor,
                            ),
                            onPressed: () => attachCamera(),
                          ),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          radius: 22,
                          child: IconButton(
                            icon: Icon(
                              Icons.folder,
                              color: themes.isDark.value
                                  ? Colors.white
                                  : ColorPallete.primaryColor,
                            ),
                            onPressed: () => attachFile(),
                          ),
                        ),
                      ],
                    ),
                    Obx(
                      () => _attachments.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: ScrollConfiguration(
                                  behavior: CustomBehavior(),
                                  child: ListView.builder(
                                    itemCount: _attachments.length,
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    itemBuilder: (context, index) {
                                      return attachmentUI(_attachments[index]);
                                    },
                                  ),
                                ),
                              ),
                            )
                          : Container(),
                    ),
                    const SizedBox(
                      height: 10,
                    )
                  ],
                ),
              ),
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
        bottomNavigationBar: _bottomSheet(),
        appBar: appBar(
          context,
          themes,
          widget.email.mimeMessage.from!.first.personalName ??
              widget.email.mimeMessage.fromEmail!,
        ),
        body: !isFetching.value && reply.isNotEmpty
            ? ScrollConfiguration(
                behavior: CustomBehavior(),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reply.length,
                        itemBuilder: (context, index) {
                          return chatUI(
                            context,
                            reply[index],
                            currUser.value,
                            widget.mailbox,
                            themes.isDark.value,
                            _emailController,
                            _services,
                          );
                        },
                      ),
                      isFetchingMore.value
                          ? Platform.isAndroid
                              ? Transform.scale(
                                  scale: 0.7,
                                  child: const SizedBox(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : const CupertinoActivityIndicator()
                          : Container(),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  chatUI(
                    context,
                    widget.email,
                    currUser.value,
                    widget.mailbox,
                    themes.isDark.value,
                    _emailController,
                    _services,
                  ),
                  isFetching.value
                      ? Platform.isAndroid
                          ? Transform.scale(
                              scale: 0.7,
                              child: const SizedBox(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : const CupertinoActivityIndicator()
                      : Container()
                ],
              ),
      ),
    );
  }
}
