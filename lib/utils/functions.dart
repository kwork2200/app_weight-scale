import 'package:app_weight_scale/ads/interstitial_ad_manager.dart';
import 'package:app_weight_scale/ads/qureka_interstitial.dart';
import 'package:flutter/material.dart';
import '../services/ad_service.dart';
import '../services/fb_ad_service.dart';
import '../services/remote_config_service.dart';

Future<bool> showManagedInterstitialAd(BuildContext context, {bool alwaysShow = false}) async {
  try {
    debugPrint('🎬 [SHOW AD] showManagedInterstitialAd called (alwaysShow: $alwaysShow)');
    
    final bool googleEnabled = AdService.instance.shouldShowInterstitialAds;
    final bool facebookEnabled = FbAdService.instance.shouldShowInterstitialAds;
    final bool thirdPartyEnabled = RemoteConfigService.instance.showThirdPartyInterstitialAds && ENABLE_THIRD_PARTY_ADS;

    debugPrint('🔍 [SHOW AD] Ad Networks Status:');
    debugPrint('   - Google: $googleEnabled');
    debugPrint('   - Facebook: $facebookEnabled');
    debugPrint('   - Third-party: $thirdPartyEnabled');

    if (!googleEnabled && !facebookEnabled && thirdPartyEnabled) {
      debugPrint('🎯 [SHOW AD] Both Google & Facebook ads disabled - trying third-party ad');
      
      if (alwaysShow) {
        if (context.mounted) {
          await showQurekaInterstitialAd(context);
          return true;
        }
      } else {
        final shouldShow = await InterstitialAdManager.instance.showAdIfAvailable();
        debugPrint('📊 [SHOW AD] Third-party ad decision: $shouldShow');
        if (shouldShow && context.mounted) {
          await showQurekaInterstitialAd(context);
          return true;
        }
      }
      return false;
    }
    
    if (alwaysShow) {
      debugPrint('🚀 [SHOW AD] Calling showAdAlways() - bypassing frequency');
      await InterstitialAdManager.instance.showAdAlways();
      return true;
    } else {
      debugPrint('🎯 [SHOW AD] Calling showAdIfAvailable() - with frequency control');
      final shouldShow = await InterstitialAdManager.instance.showAdIfAvailable();
      debugPrint('📊 [SHOW AD] showAdIfAvailable returned: $shouldShow');
      return shouldShow;
    }
  } catch (e) {
    debugPrint('❌ [SHOW AD] Error in showManagedInterstitialAd: $e');
    return false;
  }
}

/// Pehle interstitial ad dikhata hai (Remote Config ki frequency ke hisaab se),
/// ad band hone ke baad [page] par navigate karta hai. Ad na ho to turant
/// navigate kar deta hai.
Future<void> showInterstitialThenNavigate(BuildContext context, Widget page) async {
  try {
    await showManagedInterstitialAd(context, alwaysShow: false);
  } catch (e) {
    debugPrint('❌ [SHOW AD] Error before navigation: $e');
  }

  if (!context.mounted) return;

  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => page),
  );
}

/// Pehle interstitial ad dikhata hai (Remote Config ki frequency ke hisaab se),
/// ad band hone ke baad pichhli screen par wapas jaata hai. Ad na ho to turant
/// pop karta hai. [popToFirst] true hone par Home (first route) tak pop karta hai.
Future<void> showInterstitialThenPop(BuildContext context,
    {bool popToFirst = false}) async {
  try {
    await showManagedInterstitialAd(context, alwaysShow: false);
  } catch (e) {
    debugPrint('❌ [SHOW AD] Error before pop: $e');
  }

  if (!context.mounted) return;

  if (popToFirst) {
    Navigator.of(context).popUntil((r) => r.isFirst);
  } else {
    Navigator.pop(context);
  }
}



