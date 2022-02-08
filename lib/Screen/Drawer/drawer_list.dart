import 'package:flutter/material.dart';

Widget drawerList(
  Widget icon,
  Function fn,
  String title,
  bool isDark,
) {
  TextStyle _textStyle = TextStyle(
    fontSize: 14,
    color: isDark ? Colors.white : Colors.black,
    fontWeight: FontWeight.w500,
  );
  return ListTile(
      leading: icon,
      title: Text(
        title,
        style: _textStyle,
      ),
      onTap: () => fn());
}

Widget drawerMailBox(IconData icon, Function fn, String title, bool isDark,
    {int count = 0}) {
  TextStyle _textStyle = TextStyle(
    fontSize: 14,
    color: isDark ? Colors.white : Colors.black,
    fontWeight: FontWeight.w500,
  );
  return ListTile(
      leading: Icon(
        icon,
        size: 22,
        color: isDark ? Colors.white : Colors.black,
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: _textStyle,
          ),
          if (count != 0) ...{
            if (count > 99) ...{
              Text(
                "99+",
                style: _textStyle,
              ),
            } else ...{
              Text(
                count.toString(),
                style: _textStyle,
              )
            }
          }
        ],
      ),
      onTap: () => fn());
}
