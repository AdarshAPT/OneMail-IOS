import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oneMail/Cache/cache_manager.dart';
import 'package:oneMail/Model/email_model.dart';
import 'package:oneMail/Services/storage_service.dart';
import 'package:oneMail/Services/email_service.dart';

class BaseController {
  RxList<Email> emails = <Email>[].obs;
  RxList<Mailbox> mailboxList = <Mailbox>[].obs;
  final Services services = Get.find(tag: "services");
  final SecureStorage storage = SecureStorage();
  final ScrollController scrollController = ScrollController();
  final CacheManager cacheManager = CacheManager();
  Rx<int> nextEmailToken = 0.obs;
  Rx<bool> isLoading = false.obs;
  Rx<bool> isFething = false.obs;
  RxBool selectionModeEnable = false.obs;
}
