import 'package:app_weight_scale/services/remote_config_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_helper.dart';

class AppOpenAdManager {
  static AppOpenAdManager? _instance;
  static AppOpenAdManager get instance => _instance ??= AppOpenAdManager._();

  AppOpenAdManager._();

  final Duration maxCacheDuration = Duration(hours: 4);
  DateTime? _appOpenLoadTime;
  AppOpenAd? _appOpenAd;
  bool appopenredy = false;
  bool _isLoading = false;
  Function()? onAdDismissedCallback;

  void loadAd() {
    if (!RemoteConfigService.instance.showOpenAds) {
      print('🚫 App Open Ads disabled via Remote Config');
      return;
    }
    
    if (_appOpenAd != null) {
      print('✅ App Open Ad already loaded');
      return;
    }
    if (_isLoading) {
      print('⏳ App Open Ad already loading...');
      return;
    }
    
    _isLoading = true;
    print('🔄 Starting to load App Open Ad...');
    
    AppOpenAd.load(
      adUnitId: AdHelper.appOpenUnitId,
      request: AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ AppOpenAd loaded successfully');
          _appOpenLoadTime = DateTime.now();
          _appOpenAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          print('❌ AppOpenAd failed to load: $error');
          _appOpenAd = null;
          _isLoading = false;
        },
      ),
    );
  }

  bool get isAdAvailable => _appOpenAd != null;
  bool get isLoading => _isLoading;

  void showAdIfAvailable({Function()? onAdDismissed}) {
    onAdDismissedCallback = onAdDismissed;

    if (!RemoteConfigService.instance.showOpenAds) {
      print('🚫 App Open Ads disabled via Remote Config');
      onAdDismissedCallback?.call();
      return;
    }

    if (!isAdAvailable) {
      print('⚠️ App Open Ad not available');
      onAdDismissedCallback?.call();
      loadAd();
      return;
    }
    if (appopenredy) {
      print('⚠️ App Open Ad already showing, skipping duplicate request');
      return;
    }
    if (_appOpenLoadTime != null &&
        DateTime.now().subtract(maxCacheDuration).isAfter(_appOpenLoadTime!)) {
      print('⚠️ App Open Ad expired, disposing and reloading');
      _appOpenAd!.dispose();
      _appOpenAd = null;
      onAdDismissedCallback?.call();
      loadAd();
      return;
    }

    print('📺 Attempting to show App Open Ad...');
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        appopenredy = true;
        print('📺 AppOpenAd showing');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ AppOpenAd failed to show: $error');
        appopenredy = false;
        ad.dispose();
        _appOpenAd = null;
        onAdDismissedCallback?.call();
        loadAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        print('✅ AppOpenAd dismissed');
        appopenredy = false;
        ad.dispose();
        _appOpenAd = null;
        onAdDismissedCallback?.call();
        loadAd();
      },
    );
    _appOpenAd!.show();
  }

  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isLoading = false;
  }
}