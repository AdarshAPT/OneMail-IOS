import 'dart:convert';
import 'dart:io';
import 'package:enough_html_editor/enough_html_editor.dart' as editor;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:oneMail/Model/compose_email_model.dart';
import 'package:oneMail/Model/forward_email_model.dart';
import 'package:oneMail/Model/template_model.dart';
import 'package:oneMail/Model/theme_model.dart';
import 'package:oneMail/Model/user_model.dart';
import 'package:oneMail/Screen/Compose/read_more.dart';
import 'package:oneMail/Screen/Homepage/Components/email_tiles.dart';
import 'package:oneMail/Screen/Template/template.dart';
import 'package:oneMail/Services/mail_service.dart';
import 'package:oneMail/Services/remoteConfig_service.dart';
import 'package:oneMail/Services/storage_service.dart';
import 'package:oneMail/Utils/color_pallet.dart';
import 'package:oneMail/Utils/custom_glow_behaviour.dart';
import 'package:oneMail/Utils/file_info.dart';
import 'package:oneMail/Utils/file_size.dart';
import 'package:oneMail/Utils/get_avatar.dart';
import 'package:oneMail/Utils/logger.dart';
import 'package:oneMail/main.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thumbnailer/thumbnailer.dart';

class ComposeEmail extends StatefulWidget {
  final bool isReply;
  final String subject;
  final List<String> to;
  final List<String> cc;
  final List<String> bcc;
  final ForwardModel? forwardMail;
  final List<File>? shareAttachments;
  final String? mailTo;
  const ComposeEmail({
    Key? key,
    this.isReply = false,
    this.subject = "",
    this.to = const [],
    this.cc = const [],
    this.bcc = const [],
    this.forwardMail,
    this.shareAttachments,
    this.mailTo,
  }) : super(key: key);

  @override
  _ComposeEmailState createState() => _ComposeEmailState();
}

class _ComposeEmailState extends State<ComposeEmail> {
  final RxList<File> _attachments = <File>[].obs;
  final ImagePicker _picker = ImagePicker();
  final SendMail _sendMail = SendMail();
  final TextEditingController _subjectController = TextEditingController();
  final Rx<bool> _isSending = false.obs;
  final RxList<String> _to = <String>[].obs;
  final RxList<String> _cc = <String>[].obs;
  final RxList<String> _bcc = <String>[].obs;
  final RxList<User> _allUser = <User>[].obs;
  final RxList<String> _listOfContacts = <String>[].obs;
  final Themes _themes = Get.find(tag: "theme");
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _ccController = TextEditingController();
  final TextEditingController _bccController = TextEditingController();
  final FocusNode _fromNode = FocusNode();
  final FocusNode _ccNode = FocusNode();
  final FocusNode _bccNode = FocusNode();
  final RxList<TemplateModel> _templates = RxList();
  final _keyEditor = GlobalKey<editor.HtmlEditorState>();
  late final FirebaseRemoteConfig _remoteConfigService;
  late editor.HtmlEditorApi _editorApi;
  bool isInit = false;
  RxBool expandAttachment = true.obs;
  RxInt remainingSize = 26214400.obs;
  final totalSizeAllowed = 26214400;

  Future<String> getSignature() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    return preferences.getString("signature")!;
  }

  @override
  initState() {
    if (widget.isReply) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        _subjectController.value = _subjectController.value.copyWith(
          text: _subjectController.text +
              "Re: " +
              widget.subject
                  .replaceAll('Re: ', '')
                  .replaceAll("Fwd: ", ' ')
                  .trim(),
        );
        _to.addAll(widget.to);
        _bcc.addAll(widget.bcc);
        _cc.addAll(widget.cc);
      });
    }
    forwardEmail();
    shareAsAttachments();
    getContacts();
    mailTo();
    getTemplates();
    super.initState();
  }

  Widget htmlEditor(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          selectionHandleColor: Colors.blue,
        ),
      ),
      child: FutureBuilder<String>(
          future: getSignature(),
          builder: (context, snapshot) {
            return snapshot.hasData
                ? editor.HtmlEditor(
                    adjustHeight: true,
                    minHeight: 200,
                    key: _keyEditor,
                    initialContent: widget.forwardMail != null
                        ? '----------Forwarded message----------<br>From: ${widget.forwardMail!.from}<br>Date:  ${DateFormat('EE, MMM d, yyyy, hh:mm a').format(widget.forwardMail!.date)}<br>Subject: ${widget.forwardMail!.subject}<br>To: ${widget.forwardMail!.to}<br>${widget.forwardMail!.cc.isNotEmpty ? 'Cc: ${widget.forwardMail!.cc}' : ''}<br><br>${widget.forwardMail!.body}<br><br>${snapshot.data!.replaceAll('\n', "<br>")}'
                        : snapshot.data!.replaceAll('\n', "<br>"),
                    onCreated: (api) {
                      setState(() {
                        _editorApi = api;
                        isInit = true;
                      });

                      _editorApi.setColorDocumentForeground(
                        _themes.isDark.value ? Colors.white : Colors.black,
                      );

                      _editorApi.setColorDocumentBackground(
                        _themes.isDark.value
                            ? ColorPallete.darkModeColor
                            : Colors.white,
                      );
                    },
                  )
                : Container();
          }),
    );
  }

  Widget htmlToolbar() {
    return Material(
      elevation: 10,
      color: _themes.isDark.value ? ColorPallete.darkModeColor : Colors.white,
      child: Container(
        height: 50,
        color:
            _themes.isDark.value ? Colors.grey.shade900 : Colors.grey.shade200,
        child: Theme(
          data: _themes.currTheme.copyWith(
            canvasColor: _themes.isDark.value
                ? Colors.grey.shade900
                : Colors.grey.shade200,
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: editor.HtmlEditorControls(
              editorApi: _editorApi,
              editorKey: _keyEditor,
            ),
          ),
        ),
      ),
    );
  }

  void getTemplates() async {
    _remoteConfigService =
        await locator<RemoteConfigService>().setupRemoteConfig();

    String result = _remoteConfigService.getString('templates');

    result = result.replaceAll('\n', '\\n');

    List list = jsonDecode(result)['data'];

    _templates.addAll(
      list.map<TemplateModel>(
        (json) => TemplateModel.fromJSON(json),
      ),
    );
    fetchTemplates();
  }

  void fetchTemplates() async {
    try {
      await _remoteConfigService.fetchAndActivate();

      String result =
          _remoteConfigService.getString('templates').replaceAll(r'\n', r'\\n');

      List list = jsonDecode(result)['data'];
      _templates.addAll(
        list.map<TemplateModel>(
          (json) => TemplateModel.fromJSON(json),
        ),
      );
    } catch (e) {
      logError(e.toString());
    }
  }

  @override
  dispose() {
    _fromNode.dispose();
    _ccNode.dispose();
    _bccNode.dispose();
    _subjectController.dispose();
    _attachments.close();
    _fromController.clear();
    _ccController.clear();
    _bccController.clear();
    _to.close();
    _cc.close();
    _bcc.close();
    super.dispose();
  }

  mailTo() {
    if (widget.mailTo != null) {
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        _to.add(widget.mailTo!);
      });
    }
  }

  shareAsAttachments() {
    if (widget.shareAttachments != null) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        for (File file in widget.shareAttachments!) {
          if (file.lengthSync() <= remainingSize.value) {
            _attachments.add(file);
            remainingSize.value = remainingSize.value - file.lengthSync();
          } else {
            Fluttertoast.showToast(
                msg: "Attachments should not be more than 25 MB");
            break;
          }
        }
      });
    }
  }

  forwardEmail() async {
    if (widget.forwardMail != null) {
      WidgetsBinding.instance!.addPostFrameCallback(
        (_) {
          _subjectController.value = _subjectController.value.copyWith(
            text: _subjectController.text +
                "Fwd: " +
                widget.forwardMail!.subject
                    .replaceAll('Re:', '')
                    .trim()
                    .replaceAll('Fwd: ', ''),
          );
        },
      );

      bool checkPermission = await Permission.storage.isGranted;

      if (!checkPermission) {
        PermissionStatus status = await Permission.storage.request();
        if (!status.isGranted) return;
      }

      for (Attachment attachment in widget.forwardMail!.attachments) {
        Directory appDocumentsDirectory = await getTemporaryDirectory();
        String appDocumentsPath = appDocumentsDirectory.path;

        final myImagePath = "$appDocumentsPath/${attachment.name}";

        File imageFile = File(myImagePath);
        if (!await imageFile.exists()) {
          imageFile.create(recursive: true);
        }

        await imageFile.writeAsBytes(attachment.file);
        _attachments.add(imageFile);
      }
    }
  }

  Future<List<User>> getUsers() async {
    final SecureStorage _storage = SecureStorage();
    List<User> users = await _storage.getUser();
    return users;
  }

  Future<User> getAllUser() async {
    final User user = await SecureStorage().getCurrUser();
    _allUser.clear();
    _allUser.addAll(await SecureStorage().getUser());
    return user;
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

    for (Contact contact in contacts) {
      if (contact.emails.isNotEmpty) {
        _listOfContacts.add(contact.emails.first.address);
      }
    }
  }

  Widget attachmentUI(File attachment, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () => OpenFile.open(attachment.path),
        child: SizedBox(
          width: MediaQuery.of(context).size.width / 2.5,
          child: Stack(
            children: [
              Container(
                height: 150,
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
                        color: _themes.isDark.value
                            ? const Color(0xff121212).withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        spreadRadius: 3,
                        blurRadius: 3,
                        offset:
                            const Offset(0, 3), // changes position of shadow
                      ),
                    ],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                    color: _themes.isDark.value
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
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 3.0),
                                  child: Text(
                                    attachment.path.split('/').last.capitalize!,
                                    maxLines: 1,
                                    overflow: TextOverflow.clip,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      color: _themes.isDark.value
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _attachments.remove(attachment);
                                },
                                child: Icon(
                                  Icons.cancel,
                                  color: _themes.isDark.value
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade400,
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
                                    color: _themes.isDark.value
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
      ),
    );
  }

  void sendEmail(BuildContext context) async {
    final User user = await SecureStorage().getCurrUser();
    try {
      _isSending.value = true;
      if (_to.isNotEmpty) {
        await _sendMail.sendMail(ComposeMailModel(
          user,
          _to.toList(),
          _cc.toList(),
          _bcc.toList(),
          _attachments.toList(),
          _subjectController.text.trim(),
          (await _editorApi.getText()),
          parseHtmlString(await _editorApi.getText()),
        ));
        Navigator.of(context).pop();
      } else {
        Fluttertoast.showToast(msg: "Please specify at least one recipient.");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }

    _isSending.value = false;
  }

  _subjectField() {
    return Row(
      children: [
        Text(
          "Subject",
          style: TextStyle(
            fontSize: 15,
            color: _themes.isDark.value ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Flexible(
          child: TextField(
            controller: _subjectController,
            style: TextStyle(
              fontSize: 16,
              color: _themes.isDark.value ? Colors.white : Colors.black,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
            ),
          ),
        )
      ],
    );
  }

  Widget emailTag(int index, BuildContext context, RxList email) {
    return Align(
      alignment: const Alignment(-2, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: Colors.grey.withOpacity(0.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 15.5,
                  backgroundColor:
                      colors[email[index].hashCode % colors.length],
                  child: Text(
                    email[index][0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color:
                          textColors[email[index].hashCode % textColors.length],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width / 1.6,
                    child: Text(
                      email[index],
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            _themes.isDark.value ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InkWell(
                onTap: () => email.removeAt(index),
                child: Icon(
                  CupertinoIcons.clear_circled_solid,
                  color: _themes.isDark.value
                      ? Colors.grey.withOpacity(0.4)
                      : ColorPallete.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget fromTag(BuildContext context, String email) {
    return Align(
      alignment: const Alignment(-2, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: Colors.grey.withOpacity(0.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 15.5,
                  backgroundColor: colors[email.hashCode % colors.length],
                  child: Text(
                    email[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    child: Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontSize: 15,
                        color:
                            _themes.isDark.value ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _emailField(
    RxList<String> list,
    String title,
    TextEditingController controller,
    FocusNode focus,
    BuildContext context,
  ) {
    return Obx(
      () => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: _themes.isDark.value ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListView.builder(
                  itemCount: list.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          if (list.isNotEmpty && index == list.length - 1) {
                            focus.requestFocus();
                            setState(() {});
                          }
                        },
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text: list[index]))
                              .then((_) {
                            Fluttertoast.showToast(msg: 'Copied to clipboard');
                          });
                        },
                        child: emailTag(index, context, list),
                      ),
                    );
                  },
                ),
                Focus(
                  focusNode: focus,
                  onFocusChange: (isFocus) {
                    if (!isFocus) {
                      if (controller.value.text.trim().isEmail) {
                        list.add(controller.value.text.trim());
                        controller.clear();
                      } else {
                        if (controller.value.text != "") {
                          Fluttertoast.showToast(
                            msg:
                                "The address <${controller.value.text.trim()}> is invalid.",
                          );
                        }
                      }

                      focus.unfocus();
                      setState(() {});
                    }
                  },
                  child: list.isEmpty || focus.hasFocus
                      ? Autocomplete<String>(
                          fieldViewBuilder: (
                            BuildContext context,
                            TextEditingController textEditingController,
                            FocusNode focusNode,
                            VoidCallback onFieldSubmitted,
                          ) {
                            controller = textEditingController;
                            return TextField(
                              controller: controller,
                              keyboardType: TextInputType.emailAddress,
                              focusNode: focusNode,
                              style: TextStyle(
                                fontSize: 16,
                                color: _themes.isDark.value
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              onChanged: (val) {
                                if (val.endsWith(",") &&
                                    val
                                        .trim()
                                        .substring(0, val.length - 1)
                                        .isEmail) {
                                  list.add(
                                      val.trim().substring(0, val.length - 1));
                                  controller.clear();
                                }
                                if (val.endsWith(" ") && val.trim().isEmail) {
                                  list.add(val.trim());
                                  controller.clear();
                                }
                              },
                              onSubmitted: (val) {
                                if (val.trim().isEmail) {
                                  list.add(val.trim());
                                  controller.clear();
                                } else {
                                  if (controller.text != "") {
                                    Fluttertoast.showToast(
                                      msg: "The address <$val> is invalid.",
                                    );
                                  }
                                }
                                focusNode.unfocus();
                              },
                              onEditingComplete: () {
                                if (controller.value.text.trim().isEmail) {
                                  list.add(controller.value.text.trim());
                                  controller.clear();
                                }
                              },
                            );
                          },
                          onSelected: (String val) {
                            list.add(val);
                            controller.clear();
                          },
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text == '') {
                              return [];
                            }
                            return _listOfContacts.where(
                              (String option) {
                                return option.toString().contains(
                                    textEditingValue.text.toLowerCase());
                              },
                            );
                          },
                        )
                      : Container(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _fromField(BuildContext context, User from) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                "From",
                style: TextStyle(
                  fontSize: 15,
                  color: _themes.isDark.value ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              fromTag(context, from.emailAddress),
            ],
          ),
          Theme(
            data: ThemeData().copyWith(dividerColor: Colors.transparent),
            child: Flexible(
                child: PopupMenuButton<User>(
              color: _themes.isDark.value
                  ? ColorPallete.darkModeSecondary
                  : Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              enableFeedback: true,
              icon: Icon(
                Icons.expand_more,
                color: _themes.isDark.value
                    ? Colors.white
                    : ColorPallete.primaryColor,
              ),
              onSelected: (User user) => setState(() {
                from = user;
              }),
              itemBuilder: (context) {
                return _allUser
                    .map<PopupMenuItem<User>>(
                      (element) => PopupMenuItem(
                        value: element,
                        child: Text(
                          element.emailAddress,
                          style: TextStyle(
                            fontSize: 16,
                            color: _themes.isDark.value
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    )
                    .toList();
              },
            )),
          ),
        ],
      ),
    );
  }

  _attachFiles(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
        topLeft: Radius.circular(10),
        topRight: Radius.circular(10),
      )),
      backgroundColor:
          _themes.isDark.value ? ColorPallete.darkModeColor : Colors.white,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              onTap: () async {
                Navigator.of(context).pop();
                final XFile? photo =
                    await _picker.pickImage(source: ImageSource.camera);

                if (photo == null) return;
                if (await photo.length() <= remainingSize.value) {
                  remainingSize.value =
                      remainingSize.value - await photo.length();
                  _attachments.add(File(photo.path));
                } else {
                  Fluttertoast.showToast(
                      msg: "Attachments should not be more than 25 MB");
                }
              },
              leading: Icon(
                Icons.camera_alt,
                color: _themes.isDark.value
                    ? Colors.white
                    : ColorPallete.primaryColor,
              ),
              title: Text(
                "Take photo",
                style: TextStyle(
                  fontSize: 16,
                  color: _themes.isDark.value ? Colors.white : Colors.black,
                ),
              ),
            ),
            ListTile(
              onTap: () async {
                Navigator.of(context).pop();
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
                    if (file.size > remainingSize.value) {
                      Fluttertoast.showToast(
                          msg: "Attachments should not be more than 25 MB");
                      break;
                    }
                    _attachments.add(File(file.path!));
                    remainingSize.value = remainingSize.value - file.size;
                  }
                }
              },
              leading: Icon(
                Icons.folder,
                color: _themes.isDark.value
                    ? Colors.white
                    : ColorPallete.primaryColor,
              ),
              title: Text(
                "File",
                style: TextStyle(
                  fontSize: 16,
                  color: _themes.isDark.value ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget divider = const Divider(
    height: 0,
    endIndent: 10,
    indent: 10,
  );

  showAttachments(BuildContext context) {
    return Obx(
      () => _attachments.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ScrollConfiguration(
                behavior: CustomBehavior(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Attachments (${getConvertedSize(totalSizeAllowed - remainingSize.value)})",
                          style: TextStyle(
                              fontSize: 16,
                              color: _themes.isDark.value
                                  ? Colors.white
                                  : Colors.black),
                        ),
                        InkWell(
                          onTap: () =>
                              expandAttachment.value = !expandAttachment.value,
                          child: !expandAttachment.value
                              ? Icon(
                                  Icons.expand_more,
                                  color: _themes.isDark.value
                                      ? Colors.white
                                      : ColorPallete.primaryColor,
                                )
                              : Icon(
                                  Icons.expand_less,
                                  color: _themes.isDark.value
                                      ? Colors.white
                                      : ColorPallete.primaryColor,
                                ),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    expandAttachment.isTrue
                        ? SizedBox(
                            height: 150,
                            width: MediaQuery.of(context).size.width,
                            child: ListView.builder(
                              itemCount: _attachments.length,
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                return attachmentUI(
                                  _attachments[index],
                                  context,
                                );
                              },
                            ),
                          )
                        : Container(),
                  ],
                ),
              ),
            )
          : Container(),
    );
  }

  openTemplateCopyDrawer(BuildContext context, TemplateModel template) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor:
              _themes.isDark.value ? ColorPallete.darkModeColor : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        template.templateHeader,
                        style: TextStyle(
                          fontSize: 16.5,
                          color: _themes.isDark.value
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.close,
                        color:
                            _themes.isDark.value ? Colors.white : Colors.black,
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ScrollConfiguration(
                    behavior: CustomBehavior(),
                    child: CupertinoScrollbar(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              template.templateBody,
                              style: TextStyle(
                                fontSize: 15,
                                color: _themes.isDark.value
                                    ? Colors.white70
                                    : Colors.black87,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                MaterialButton(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  color: _themes.isDark.value
                      ? Colors.grey.withOpacity(0.2)
                      : Colors.grey.shade200,
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text:
                            "${template.templateHeader}\n${template.templateBody}",
                      ),
                    ).then(
                      (_) {
                        Navigator.of(context).pop();
                        Fluttertoast.showToast(msg: "Copied to clipboard");
                      },
                    );
                  },
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 40,
                    child: Center(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Copy",
                            style: TextStyle(
                              fontSize: 16,
                              color: _themes.isDark.value
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget templateUI(BuildContext context, TemplateModel template) {
    return Container(
      width: MediaQuery.of(context).size.width / 2.2,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 5,
                ),
                Text(
                  template.templateHeader,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 16.5,
                    color: _themes.isDark.value ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                SizedBox(
                  height: 100,
                  child: ExpandableText(
                    template.templateBody,
                    () {
                      Navigator.of(context).pop();
                      openTemplateCopyDrawer(context, template);
                    },
                    trimLines: 5,
                    style: GoogleFonts.workSans().copyWith(
                      fontSize: 15,
                      color: _themes.isDark.value
                          ? Colors.white60
                          : Colors.black54,
                    ),
                  ),
                )
              ],
            ),
            const Spacer(),
            MaterialButton(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(
                    text:
                        "${template.templateHeader}\n${template.templateBody}",
                  ),
                ).then(
                  (_) {
                    Navigator.of(context).pop();
                    Fluttertoast.showToast(msg: "Copied to clipboard");
                  },
                );
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.grey.withOpacity(0.2),
                ),
                child: Center(
                  child: Text(
                    "Copy",
                    style: TextStyle(
                      fontSize: 16,
                      color: _themes.isDark.value ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  showTemplateModalSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor:
          _themes.isDark.value ? ColorPallete.darkModeColor : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      )),
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Templates",
                    style: TextStyle(
                      fontSize: 20,
                      color: _themes.isDark.value ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  TemplateScreen(templates: _templates),
                            ),
                          );
                        },
                        child: Text(
                          "View All",
                          style: TextStyle(
                            fontSize: 16,
                            color: !_themes.isDark.value
                                ? ColorPallete.primaryColor
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.cancel,
                          color: _themes.isDark.value
                              ? Colors.grey.withOpacity(0.4)
                              : ColorPallete.primaryColor,
                        ),
                      )
                    ],
                  ),
                ],
              ),
              const SizedBox(
                height: 5,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  templateUI(
                    context,
                    _templates[0],
                  ),
                  _templates.length >= 2
                      ? templateUI(
                          context,
                          _templates[1],
                        )
                      : Container(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor:
            _themes.isDark.value ? const Color(0xff121212) : Colors.white,
        bottomSheet: isInit ? htmlToolbar() : const SizedBox(height: 0),
        // floatingActionButton: Obx(
        //   () => Column(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       FloatingActionButton(
        //         onPressed: () => showTemplateModalSheet(context),
        //         backgroundColor: Colors.red.shade700,
        //         heroTag: "1",
        //         child: SvgPicture.asset(
        //           'assets/fab.svg',
        //         ),
        //       ),
        //       const SizedBox(
        //         height: 10,
        //       ),
        // FloatingActionButton(
        //   backgroundColor: ColorPallete.primaryColor,
        //   onPressed: () => sendEmail(context),
        //   heroTag: "2",
        //   child: !_isSending.value
        //       ? const Icon(
        //           Ionicons.send,
        //           color: Colors.white,
        //         )
        // : ,
        // ),
        //     const SizedBox(
        //       height: 60,
        //     ),
        //   ],
        // ),
        // ),
        appBar: AppBar(
          title: Text(
            widget.isReply
                ? "Reply"
                : widget.forwardMail != null
                    ? "Forward Mail"
                    : "Compose Mail",
            style: TextStyle(
              fontSize: 16,
              color: _themes.isDark.value ? Colors.white : Colors.black,
            ),
          ),
          iconTheme: IconThemeData(
            color:
                _themes.isDark.value ? Colors.white : ColorPallete.primaryColor,
          ),
          elevation: 0,
          systemOverlayStyle: Platform.isAndroid
              ? SystemUiOverlayStyle(
                  statusBarColor: !_themes.isDark.value
                      ? Colors.white
                      : ColorPallete.darkModeColor,
                  statusBarBrightness: !_themes.isDark.value
                      ? Brightness.dark
                      : Brightness.light,
                  statusBarIconBrightness: !_themes.isDark.value
                      ? Brightness.dark
                      : Brightness.light,
                )
              : null,
          backgroundColor:
              _themes.isDark.value ? ColorPallete.darkModeColor : Colors.white,
          actions: [
            IconButton(
              onPressed: () => showTemplateModalSheet(context),
              icon: Icon(
                Icons.add,
                color: _themes.isDark.value
                    ? Colors.white
                    : ColorPallete.primaryColor,
                size: 27,
              ),
            ),
            IconButton(
              onPressed: () => _attachFiles(context),
              icon: Icon(
                Ionicons.ios_attach,
                color: _themes.isDark.value
                    ? Colors.white
                    : ColorPallete.primaryColor,
                size: 27,
              ),
            ),
            Obx(
              () => !_isSending.value
                  ? IconButton(
                      onPressed: () => sendEmail(context),
                      icon: Icon(
                        IconlyBold.send,
                        color: _themes.isDark.value
                            ? Colors.white
                            : ColorPallete.primaryColor,
                      ),
                    )
                  : const SizedBox(
                      height: 30,
                      width: 30,
                      child: CupertinoActivityIndicator(),
                    ),
            )
          ],
        ),
        body: FutureBuilder<User>(
            future: getAllUser(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ScrollConfiguration(
                  behavior: CustomBehavior(),
                  child: SingleChildScrollView(
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _fromField(context, snapshot.requireData),
                            divider,
                            _emailField(
                                _to, "To", _fromController, _fromNode, context),
                            divider,
                            _emailField(
                                _cc, "Cc", _ccController, _ccNode, context),
                            divider,
                            _emailField(
                                _bcc, "Bcc", _bccController, _bccNode, context),
                            divider,
                            _subjectField(),
                            divider,
                            const SizedBox(
                              height: 10,
                            ),
                            htmlEditor(context),
                            const SizedBox(
                              height: 10,
                            ),
                            showAttachments(context),
                            const SizedBox(
                              height: 50,
                            ),
                          ],
                        )),
                  ),
                );
              } else {
                return Container();
              }
            }),
      ),
    );
  }
}
