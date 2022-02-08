import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:oneMail/Model/theme_model.dart';
import 'package:oneMail/Utils/color_pallet.dart';
import 'package:oneMail/Utils/get_avatar.dart';

Widget emailField(String email, Themes themes) {
  return email.isNotEmpty
      ? PopupMenuButton<int>(
          color: themes.isDark.value
              ? ColorPallete.darkModeSecondary
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          enableFeedback: true,
          elevation: 1,
          tooltip: email,
          onSelected: (val) {
            if (val == 0) {
              Clipboard.setData(
                ClipboardData(text: email),
              ).then(
                (_) {
                  Fluttertoast.showToast(msg: 'Copied to clipboard');
                },
              );
            }
          },
          itemBuilder: (context) {
            return [
              PopupMenuItem(
                value: 0,
                child: Text(
                  email,
                  style: TextStyle(
                    color: themes.isDark.value ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
            ];
          },
          // onLongPress: () {
          // },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(500),
              color: Colors.grey.withOpacity(0.1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 15.5,
                  backgroundColor: colors[email.hashCode % colors.length],
                  child: Text(
                    email[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColors[email.hashCode % textColors.length],
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Flexible(
                  child: Text(
                    email,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 16,
                      color: themes.isDark.value ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 15,
                ),
              ],
            ),
          ),
        )
      : Container();
}

final Widget divider = Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    const SizedBox(
      height: 10,
    ),
    Container(
      width: double.infinity,
      height: 1, // Thickness
      color: Colors.grey.withOpacity(0.1),
    ),
    const SizedBox(
      height: 10,
    ),
  ],
);
