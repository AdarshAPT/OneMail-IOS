import 'dart:io';
import 'package:get/get.dart';
import 'package:oneMail/Download%20Manager/download_manager.dart';
import 'package:oneMail/Model/download_model.dart';
import 'package:oneMail/Model/user_model.dart';
import 'package:oneMail/Services/storage_service.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadController {
  final RxList<DownloadFileModel> downloads = <DownloadFileModel>[].obs;
  final RxList<DownloadFileModel> result = <DownloadFileModel>[].obs;
  final RxList<DownloadFileModel> documents = <DownloadFileModel>[].obs;
  final RxList<DownloadFileModel> audio = <DownloadFileModel>[].obs;
  final RxList<DownloadFileModel> image = <DownloadFileModel>[].obs;
  final RxList<DownloadFileModel> video = <DownloadFileModel>[].obs;
  final RxList<String> users = <String>[].obs;
  final RxList<bool> isSelected = <bool>[].obs;
  final RxList<User> user = <User>[].obs;
  final RxBool isFetching = false.obs;

  DownloadController() {
    getAllFiles();
    getAllUser();
  }

  getAllUser() async {
    user.addAll(await SecureStorage().getUser());
    User currUser = await SecureStorage().getCurrUser();
    users.add("All");
    isSelected.add(false);

    for (User user in user) {
      users.add(user.emailAddress);
      if (user.emailAddress == currUser.emailAddress) {
        isSelected.add(true);
      } else {
        isSelected.add(false);
      }
    }
  }

  toggle(String emailId, List<bool> filterByFiles) {
    result.clear();
    if (emailId == "All") {
      if (!filterByFiles[0] &&
          !filterByFiles[1] &&
          !filterByFiles[2] &&
          !filterByFiles[3]) {
        result.addAll(downloads);
      } else {
        if (filterByFiles[0]) {
          result.addAll(image);
        }

        if (filterByFiles[1]) {
          result.addAll(video);
        }

        if (filterByFiles[2]) {
          result.addAll(documents);
        }

        if (filterByFiles[3]) {
          result.addAll(audio);
        }
      }
    } else {
      if (!filterByFiles[0] &&
          !filterByFiles[1] &&
          !filterByFiles[2] &&
          !filterByFiles[3]) {
        for (var doc in downloads) {
          if (doc.emailAddress == emailId) {
            result.add(doc);
          }
        }
      } else {
        if (filterByFiles[0]) {
          for (var doc in image) {
            if (doc.emailAddress == emailId) {
              result.add(doc);
            }
          }
        }

        if (filterByFiles[1]) {
          for (var doc in video) {
            if (doc.emailAddress == emailId) {
              result.add(doc);
            }
          }
        }

        if (filterByFiles[2]) {
          for (var doc in documents) {
            if (doc.emailAddress == emailId) {
              result.add(doc);
            }
          }
        }

        if (filterByFiles[3]) {
          for (var doc in audio) {
            if (doc.emailAddress == emailId) {
              result.add(doc);
            }
          }
        }
      }
    }
  }

  Future<void> getAllFiles() async {
    bool checkPermission = await Permission.storage.isGranted;

    if (!checkPermission) {
      PermissionStatus status = await Permission.storage.request();
      if (!status.isGranted) return;
    }

    isFetching.value = true;

    User user = await User.getCurrentUser();

    List<DownloadFileModel> res = await DownloadManager().getFile();

    for (DownloadFileModel dm in res) {
      if (await File(dm.filePath).exists()) {
        downloads.add(dm);
        if (dm.emailAddress == user.emailAddress) {
          result.add(dm);
        }
      }

      if (dm.isAudio) {
        audio.add(dm);
      }

      if (dm.isFile) {
        documents.add(dm);
      }

      if (dm.isImage) {
        image.add(dm);
      }

      if (dm.isVideo) {
        video.add(dm);
      }
    }

    isFetching.value = false;
  }

  changeType(List<bool> filterType) {
    result.clear();

    if (!filterType[0] && !filterType[1] && !filterType[2] && !filterType[3]) {
      for (int i = 0; i < isSelected.length; i++) {
        isSelected[i] = false;
      }
      isSelected[0] = true;
      result.addAll(downloads);
    } else {
      if (filterType[0]) {
        result.addAll(image);
      }

      if (filterType[1]) {
        result.addAll(video);
      }

      if (filterType[2]) {
        result.addAll(documents);
      }

      if (filterType[3]) {
        result.addAll(audio);
      }
    }
  }
}
