import 'package:oneMail/Model/download_model.dart';
import 'package:oneMail/Utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadManager {
  Future<void> addToDownload(DownloadFileModel file) async {
    final _prefs = await SharedPreferences.getInstance();
    List<DownloadFileModel> list = [];

    if (_prefs.containsKey("download")) {
      List<String> result = _prefs.getStringList("download")!;

      for (String stringJSON in result) {
        list.add(DownloadFileModel.fromJSON(stringJSON));
      }
    }

    list.add(file);

    List<String> convertToString =
        list.map<String>((file) => file.toString()).toList();

    _prefs.setStringList("download", convertToString);
    logSuccess("added to download");
  }

  Future<List<DownloadFileModel>> getFile() async {
    final _prefs = await SharedPreferences.getInstance();
    List<DownloadFileModel> downloadList = [];

    if (_prefs.containsKey("download")) {
      List<String> downloadListString = _prefs.getStringList("download")!;

      for (String stringJSON in downloadListString) {
        downloadList.add(DownloadFileModel.fromJSON(stringJSON));
      }
    }

    return downloadList;
  }
}
