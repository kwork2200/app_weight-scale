import 'dart:developer';
import 'dart:io';

class AdHelper {

  static Map<String, dynamic> datamap = {
    "admobid2": "ca-app-pub-3940256099942544/9257395921",
    "admobnative": "ca-app-pub-3940256099942544/2247696110",
    "admobfull": "ca-app-pub-3940256099942544/1033173712",
  };

  static String get appOpenUnitId {
    if (Platform.isAndroid) {
      return datamap["admobid2"];
    } else if (Platform.isIOS) {
      return '<YOUR_IOS_BANNER_AD_UNIT_ID>';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

}
