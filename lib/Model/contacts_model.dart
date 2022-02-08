import 'dart:convert';

class Contacts {
  final String email;
  final String? photoURL;
  final String name;

  Contacts(this.email, this.photoURL, this.name);

  factory Contacts.fromJSON(Map json) {
    return Contacts(
      json['emailAddresses'][0]['value'],
      json['photos'][0]['url'],
      json['names'][0]['displayName'],
    );
  }

  factory Contacts.fromCache(String str) {
    Map json = jsonDecode(str);
    return Contacts(
      json['email'],
      json['photoURL'],
      json['name'],
    );
  }

  @override
  String toString() {
    Map json = {
      "email": email,
      "photoURL": photoURL,
      "name": name,
    };
    return jsonEncode(json);
  }
}
