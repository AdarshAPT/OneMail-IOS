import 'package:flutter/material.dart';
import 'package:oneMail/Utils/color_pallet.dart';

showSnackBar(BuildContext context, {String msg = ""}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        msg,
        style: const TextStyle(fontSize: 16),
      ),
      backgroundColor: ColorPallete.primaryColor,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
