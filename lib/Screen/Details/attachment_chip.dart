import 'dart:io';
import 'dart:typed_data';
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:oneMail/Download%20Manager/download_manager.dart';
import 'package:oneMail/Model/download_model.dart';
import 'package:oneMail/Model/email_model.dart';
import 'package:oneMail/Model/theme_model.dart';
import 'package:oneMail/Model/user_model.dart';
import 'package:oneMail/Services/email_service.dart';
import 'package:oneMail/Utils/file_size.dart';
import 'package:oneMail/Utils/logger.dart';
import 'package:oneMail/Utils/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AttachmentChip extends StatefulWidget {
  final ContentInfo info;
  final Email message;
  const AttachmentChip({Key? key, required this.info, required this.message})
      : super(key: key);

  @override
  _AttachmentChipState createState() => _AttachmentChipState();
}

class _AttachmentChipState extends State<AttachmentChip> {
  final DownloadManager downloadManager = DownloadManager();
  final Services services = Get.find(tag: "services");
  final RxBool _isDownloading = false.obs;
  MimePart? _mimePart;

  @override
  void initState() {
    final mimeMessage = widget.message.mimeMessage;
    _mimePart = mimeMessage.getPart(widget.info.fetchId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6.0,
        horizontal: 2.0,
      ),
      child: _buildPreviewWidget(widget.info),
    );
  }

  Widget _buildPreviewWidget(ContentInfo info) {
    final Themes themes = Get.find(tag: "theme");

    return Obx(
      () => ListTile(
        tileColor: themes.isDark.value
            ? Colors.grey.shade50.withOpacity(0.1)
            : Colors.grey[100],
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        title: Row(
          children: [
            info.isImage
                ? Image.memory(
                    (widget.message.mimeMessage.getPart(info.fetchId))!
                        .decodeContentBinary()!,
                    width: 20,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Feather.image),
                  )
                : info.isAudio
                    ? const Icon(Icons.audiotrack)
                    : info.isVideo
                        ? const Icon(Feather.video)
                        : const Icon(Ionicons.document_outline),
            const SizedBox(
              width: 15,
            ),
            Flexible(
              child: Text(
                info.fileName!,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontSize: 15,
                  color: themes.isDark.value ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: () => _isDownloading.value ? null : _download(info),
          icon: _isDownloading.value
              ? Platform.isAndroid
                  ? Transform.scale(
                      scale: 0.5,
                      child: const CircularProgressIndicator(
                        strokeWidth: 3,
                      ),
                    )
                  : const CupertinoActivityIndicator()
              : Icon(
                  SimpleLineIcons.cloud_download,
                  color: themes.isDark.value ? Colors.white : Colors.black,
                ),
        ),
      ),
    );
  }

  Future _download(ContentInfo info) async {
    if (_isDownloading.value) {
      return;
    }
    try {
      //checking for permission
      bool checkPermission = await Permission.storage.isGranted;

      if (!checkPermission) {
        PermissionStatus status = await Permission.storage.request();
        if (!status.isGranted) return;
      }

      setState(() {
        _isDownloading.value = true;
      });

      _mimePart = widget.message.mimeMessage.getPart(info.fetchId);

      Uint8List? attachment = _mimePart!.decodeContentBinary();

      // directory location

      Directory appDocumentsDirectory =
          await getApplicationDocumentsDirectory();
      String appDocumentsPath = appDocumentsDirectory.path;

      final myImagePath = "$appDocumentsPath/${info.fileName}";

      File imageFile = File(myImagePath);
      if (!await imageFile.exists()) {
        imageFile.create(recursive: true);
      }

      await imageFile.writeAsBytes(attachment!);

      DownloadFileModel downloadedFile = DownloadFileModel(
        info.fileName!,
        imageFile.absolute.path,
        info.isImage,
        info.isApplication,
        info.isVideo,
        info.isAudio,
        _mimePart!.mediaType.toString(),
        DateTime.now().toString(),
        await getFileSize(myImagePath, 1),
        (await User.getCurrentUser()).emailAddress,
      );

      logSuccess(downloadedFile.toString());

      await downloadManager.addToDownload(downloadedFile);

      Fluttertoast.showToast(msg: "Downloaded Sucessfully");
    } catch (e, stackTrace) {
      Fluttertoast.showToast(msg: "Unable to download attachment");
      logToDevice("AttachmentClip", "_download", e.toString(), stackTrace);
    } finally {
      if (mounted) {
        _isDownloading.value = false;
      }
    }
  }
}
