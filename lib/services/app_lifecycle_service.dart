import 'package:app_weight_scale/ads/app_open_ad_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class AppLifecycleService extends GetxController with WidgetsBindingObserver {
  static AppLifecycleService get to => Get.find();

  final isAppInBackground = false.obs;
  bool _isFirstResume = true;
  DateTime? _lastAdShownTime;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        isAppInBackground.value = true;
        if (!AppOpenAdManager.instance.isAdAvailable) {
          AppOpenAdManager.instance.loadAd();
        }
        break;

      case AppLifecycleState.resumed:
        if (_isFirstResume) {
          print('🔹 First resume - skipping ad (handled by splash)');
          _isFirstResume = false;
          return;
        }
        if (isAppInBackground.value) {
          if (_lastAdShownTime != null) {
            final timeSinceLastAd = DateTime.now().difference(_lastAdShownTime!);
            if (timeSinceLastAd.inSeconds < 10) {
              print('🔹 Ad shown recently (${timeSinceLastAd.inSeconds}s ago), skipping');
              isAppInBackground.value = false;
              return;
            }
          }
          isAppInBackground.value = false;
        }
        break;

      default:
        break;
    }
  }
}
