import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:iconly/iconly.dart';

IconData getIcon(String mailBoxName) {
  if (mailBoxName.toLowerCase() == "inbox") {
    return IconlyLight.message;
  } else if (mailBoxName.toLowerCase() == "draft" ||
      mailBoxName.toLowerCase() == "drafts") {
    return Feather.box;
  } else if (mailBoxName.toLowerCase() == "trash" ||
      mailBoxName.toLowerCase() == "bin" ||
      mailBoxName.toLowerCase() == "deleted") {
    return Feather.trash;
  } else if (mailBoxName.toLowerCase() == "archive") {
    return Feather.archive;
  } else if (mailBoxName.toLowerCase().contains("sent")) {
    return IconlyLight.send;
  } else if (mailBoxName.toLowerCase() == "flag" ||
      mailBoxName.toLowerCase() == "starred") {
    return AntDesign.staro;
  } else if (mailBoxName.toLowerCase() == "spam" ||
      mailBoxName.toLowerCase() == "junk") {
    return Ionicons.warning_outline;
  } else if (mailBoxName.toLowerCase() == "important") {
    return MaterialIcons.label_important_outline;
  } else if (mailBoxName.toLowerCase() == "notes") {
    return MaterialIcons.notes;
  }

  return Feather.folder;
}
