import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class Rating {
  final String playStoreURL =
      "https://play.google.com/store/apps/details?id=office.hotmail.mymail.email";
  final RxBool isRatindApplicable = false.obs;
  final rating = 0.obs;

  Rating() {
    incrementRatingCount();
  }

  incrementRatingCount() async {
    final SharedPreferences _pref = await SharedPreferences.getInstance();
    if (!_pref.containsKey("isRated")) {
      if (_pref.containsKey("ratingCount")) {
        int count = _pref.getInt("ratingCount")!;
        await _pref.setInt("ratingCount", count + 1);
        if (count + 1 > 1) {
          isRatindApplicable.value = true;
        }
        return;
      }
      await _pref.setInt("ratingCount", 1);
    }
  }

  rate() async {
    final SharedPreferences _pref = await SharedPreferences.getInstance();
    final InAppReview inAppReview = InAppReview.instance;

    if (rating.value <= 3) {
      Fluttertoast.showToast(msg: "Thanks for giving your feedback");
    } else {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        await launch(playStoreURL);
      }
    }
    Fluttertoast.showToast(msg: "Thanks for giving your feedback");

    isRatindApplicable.value = false;
    _pref.setBool("isRated", true);
  }
}
