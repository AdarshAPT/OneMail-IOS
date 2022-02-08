import 'dart:convert';
import 'package:enough_mail/enough_mail.dart';
import 'package:get/get.dart';
import 'package:oneMail/Cache/cache_manager.dart';
import 'package:oneMail/Model/contacts_model.dart';
import 'package:http/http.dart' as http;
import 'package:oneMail/Model/user_model.dart';
import 'package:oneMail/Services/refresh_token.dart';

class ContactsController extends GetxController {
  final RxBool isFetching = false.obs;
  final RxList<Contacts> contacts = <Contacts>[].obs;
  final CacheManager manager = CacheManager();

  ContactsController() {
    fetchCache();
    fetchContacts();
  }

  fetchCache() async {
    contacts.addAll(await manager.getCacheContacts());
    contacts.sort((a, b) => a.name.compareTo(b.name));
  }

  fetchContacts() async {
    final User user = await User.getCurrentUser();
    if (user.isGmail) {
      final OauthToken? token =
          await getRefreshToken(user.client, user.refreshToken);

      if (token == null) return;

      var response = await http.get(
          Uri.parse(
            "https://people.googleapis.com/v1/people/me/connections?personFields=names,emailAddresses,photos",
          ),
          headers: {
            "Authorization": "Bearer ${token.accessToken}",
            "Accept": "application/json"
          });

      if (response.statusCode == 200) {
        var res = jsonDecode(response.body)['connections'];

        contacts.clear();

        for (Map resMap in res) {
          if (resMap['emailAddresses'] != null &&
              resMap['photos'] != null &&
              resMap['names'] != null) {
            contacts.add(Contacts.fromJSON(resMap));
          }
        }
      }

      contacts.sort((a, b) => a.name.compareTo(b.name));

      await manager.cacheContacts(contacts.toList());
    }
  }
}
