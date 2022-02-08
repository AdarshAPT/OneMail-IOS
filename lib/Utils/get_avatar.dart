import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

List<Color> colors = [
  Colors.blue,
  Colors.amber.shade800,
  Colors.pink,
  Colors.red,
  Colors.purple,
  Colors.deepPurple,
  Colors.cyan,
  Colors.deepOrange,
  Colors.orange,
  Colors.green,
];

List<Color> textColors = [
  Colors.blue.shade100,
  Colors.amber.shade100,
  Colors.pink.shade100,
  Colors.red.shade100,
  Colors.purple.shade100,
  Colors.deepPurple.shade100,
  Colors.cyan.shade100,
  Colors.deepOrange.shade100,
  Colors.orange.shade100,
  Colors.green.shade100,
];

Widget getAvatar(String? email, bool isDark) {
  int length = colors.length;

  Widget placeholder = CircleAvatar(
    backgroundColor: colors[email.hashCode % length],
    child: Text(
      email == null ? "A" : email[0].toUpperCase(),
      style: TextStyle(
        color: textColors[email.hashCode % length],
        fontSize: 20,
      ),
    ),
  );

  var domain = email!.split('@')[1];

  if (domain == 'outlook.com' || domain == 'mail.onedrive.com') {
    domain = 'microsoft.com';
  }

  if (domain == "facebookmail.com") {
    return CircleAvatar(
      backgroundColor: Colors.transparent,
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: CachedNetworkImage(
            imageUrl:
                "https://upload.wikimedia.org/wikipedia/commons/0/05/Facebook_Logo_%282019%29.png",
            errorWidget: (context, url, error) => placeholder,
            placeholder: (context, url) => placeholder,
          ),
        ),
      ),
    );
  }

  if (domain == 'gmail.com' ||
      domain == 'google.com' ||
      domain == 'accounts.google.com') {
    return CircleAvatar(
      backgroundColor: Colors.transparent,
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: CachedNetworkImage(
            imageUrl:
                "https://www.freepnglogos.com/uploads/google-logo-png/google-logo-png-webinar-optimizing-for-success-google-business-webinar-13.png",
            errorWidget: (context, url, error) => placeholder,
            placeholder: (context, url) => placeholder,
          ),
        ),
      ),
    );
  }

  return CircleAvatar(
    backgroundColor: Colors.transparent,
    radius: 22,
    child: Padding(
      padding: const EdgeInsets.all(0.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: CachedNetworkImage(
          imageUrl: "https://logo.clearbit.com/$domain",
          errorWidget: (context, url, error) => placeholder,
          placeholder: (context, url) => placeholder,
        ),
      ),
    ),
  );
}
