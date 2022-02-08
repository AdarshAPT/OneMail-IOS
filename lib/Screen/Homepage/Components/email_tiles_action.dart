import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:oneMail/Utils/color_pallet.dart';

Widget slideLeftBackground() {
  return Container(
    color: Colors.red.shade700,
    child: Align(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: const [
          Icon(
            Icons.delete,
            color: Colors.white,
            size: 30,
          ),
          SizedBox(
            width: 20,
          ),
        ],
      ),
      alignment: Alignment.centerRight,
    ),
  );
}

Widget slideRightBackground() {
  return Container(
    color: ColorPallete.primaryColor,
    child: Align(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Ionicons.ios_mail_open,
                color: Colors.white,
                size: 30,
              ),
            ],
          ),
        ],
      ),
      alignment: Alignment.centerLeft,
    ),
  );
}
