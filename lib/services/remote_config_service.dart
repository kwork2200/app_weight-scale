import 'dart:async';
import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Service to manage Firebase Remote Config for ads configuration
class RemoteConfigService {
  static RemoteConfigService? _instance;
  static RemoteConfigService get instance => _instance ??= RemoteConfigService._();

  RemoteConfigService._();

  late FirebaseRemoteConfig _remoteConfig;
  bool _isInitialized = false;
  
  final _configUpdateController = StreamController<void>.broadcast();
  
  /// Stream that emits whenever Remote Config is updated
  Stream<void> get configUpdates => _configUpdateController.stream;

  static const Map<String, dynamic> _defaults = {
    'weight_scan_show_banner_ads': true,
    'weight_scan_show_native_ads': true,
    'weight_scan_show_open_ads': true,
    
    'weight_scan_use_facebook_ads': true,
    'weight_scan_show_fb_banner_ads': true,
    'weight_scan_show_fb_native_ads': true,
    
    'weight_scan_show_third_party_banner_ads': true,
    'weight_scan_show_third_party_native_ads': true,
    'weight_scan_third_party_ad_url': '',
    'weight_scan_third_party_interstitial_ad_url_1': '',
    
    'weight_scan_show_third_party_interstitial_ads': true,
    
    'weight_scan_show_interstitial_ads': true,
    'weight_scan_show_fb_interstitial_ads': true,
    'weight_scan_interstitial_ad_frequency': 2,
    'weight_scan_android_banner_ad_id': 'ca-app-pub-3940256099942544/6300978111',
    'weight_scan_android_interstitial_ad_id': 'ca-app-pub-3940256099942544/1033173712',
    'weight_scan_android_native_ad_id': 'ca-app-pub-3940256099942544/2247696110',
    'weight_scan_android_open_ad_id': 'ca-app-pub-3940256099942544/9257395921',
    'weight_scan_android_fb_banner_ad_id': 'MG_16_9_APP_INSTALL#YOUR_PLACEMENT_ID',
    'weight_scan_android_fb_interstitial_ad_id': 'VID_HD_16_9_46S_APP_INSTALL#YOUR_PLACEMENT_ID',
    'weight_scan_android_fb_native_ad_id': 'IMG_16_9_APP_INSTALL#YOUR_PLACEMENT_ID',
  };

  /// Initialize Remote Config
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: Duration.zero,
        )
      );

      await _remoteConfig.setDefaults(_defaults);

      await _remoteConfig.fetchAndActivate();
      
      _remoteConfig.onConfigUpdated.listen((event) async {
        await _remoteConfig.activate();

        _configUpdateController.add(null);
      }, onError: (error) {
      });
      _isInitialized = true;
      _startPeriodicFetch();
    } catch (e) {
      print('❌ Remote Config initialization failed: $e');
      print('⚠️ Using default values');
    }
  }
  
  /// Start periodic fetching to detect changes quickly
  Timer? _fetchTimer;
  void _startPeriodicFetch() {
    _fetchTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        print('🔄 Checking for Remote Config updates...');
        final updated = await _remoteConfig.fetchAndActivate();
        if (updated) {
          print('✅ Remote Config updated via periodic fetch');
          _configUpdateController.add(null);
        } else {
          print('ℹ️ Remote Config already up-to-date');
        }
      } catch (e) {
        print('⚠️ Periodic fetch error: $e');
      }
    });
  }

  /// Force fetch latest config from server (useful for testing)
  Future<bool> fetchAndActivate() async {
    try {
      print('🔄 Manually fetching Remote Config...');
      final updated = await _remoteConfig.fetchAndActivate();
      if (updated) {
        print('✅ Remote Config fetched and activated');
        _configUpdateController.add(null);
        return true;
      } else {
        print('ℹ️ Remote Config already up to date');
        return false;
      }
    } catch (e) {
      print('❌ Failed to fetch Remote Config: $e');
      return false;
    }
  }
  
  /// Clean up resources
  void dispose() {
    _fetchTimer?.cancel();
    _configUpdateController.close();
  }

  /// Check if Facebook Ads should be used as primary/fallback
  bool get useFacebookAds {
    try {
      return _remoteConfig.getBool('weight_scan_use_facebook_ads');
    } catch (e) {
      print('⚠️ Error getting weight_scan_use_facebook_ads: $e');
      return _defaults['weight_scan_use_facebook_ads'] as bool;
    }
  }

  /// Check if third-party banner ads should be shown (fallback image ads)
  bool get showThirdPartyBannerAds {
    try {
      return _remoteConfig.getBool('weight_scan_show_third_party_banner_ads');
    } catch (e) {
      print('⚠️ Error getting weight_scan_show_third_party_banner_ads: $e');
      return _defaults['weight_scan_show_third_party_banner_ads'] as bool;
    }
  }

  /// Check if third-party native ads should be shown (fallback image ads)
  bool get showThirdPartyNativeAds {
    try {
      return _remoteConfig.getBool('weight_scan_show_third_party_native_ads');
    } catch (e) {
      print('⚠️ Error getting weight_scan_show_third_party_native_ads: $e');
      return _defaults['weight_scan_show_third_party_native_ads'] as bool;
    }
  }

  /// Get third-party ad click URL
  String get thirdPartyAdUrl {
    try {
      return _remoteConfig.getString('weight_scan_third_party_ad_url');
    } catch (e) {
      print('⚠️ Error getting weight_scan_third_party_ad_url: $e');
      return _defaults['weight_scan_third_party_ad_url'] as String;
    }
  }

  /// Check if third-party interstitial ads should be shown
  bool get showThirdPartyInterstitialAds {
    try {
      return _remoteConfig.getBool('weight_scan_show_third_party_interstitial_ads');
    } catch (e) {
      print('⚠️ Error getting weight_scan_show_third_party_interstitial_ads: $e');
      return _defaults['weight_scan_show_third_party_interstitial_ads'] as bool;
    }
  }

  /// Get third-party interstitial ad URL 1 (Qureka)
  String get thirdPartyInterstitialAdUrl1 {
    try {
      return _remoteConfig.getString('weight_scan_third_party_interstitial_ad_url_1');
    } catch (e) {
      print('⚠️ Error getting weight_scan_third_party_interstitial_ad_url_1: $e');
      return _defaults['weight_scan_third_party_interstitial_ad_url_1'] as String;
    }
  }

  /// Check if banner ads should be shown
  bool get showBannerAds {
    try {
      return _remoteConfig.getBool('weight_scan_show_banner_ads');
    } catch (e) {
      print('⚠️ Error getting weight_scan_show_banner_ads: $e');
      return _defaults['weight_scan_show_banner_ads'] as bool;
    }
  }

  bool get showFbBannerAds {
    try {
      return _remoteConfig.getBool('weight_scan_show_fb_banner_ads');
    } catch (e) {
      print('⚠️ Error getting weight_scan_show_fb_banner_ads: $e');
      return _defaults['weight_scan_show_fb_banner_ads'] as bool;
    }
  }

  bool get showNativeAds {
    try {
      return _remoteConfig.getBool('weight_scan_show_native_ads');
    } catch (e) {
      print('⚠️ Error getting weight_scan_show_native_ads: $e');
      return _defaults['weight_scan_show_native_ads'] as bool;
    }
  }

  bool get showOpenAds {
    try {
      return _remoteConfig.getBool('weight_scan_show_open_ads');
    } catch (e) {
      print('⚠️ Error getting weight_scan_show_open_ads: $e');
      return _defaults['weight_scan_show_open_ads'] as bool;
    }
  }

  bool get showFbNativeAds {
    try {
      return _remoteConfig.getBool('weight_scan_show_fb_native_ads');
    } catch (e) {
      print('⚠️ Error getting weight_scan_show_fb_native_ads: $e');
      return _defaults['weight_scan_show_fb_native_ads'] as bool;
    }
  }






  /// Check if interstitial ads should be shown
  bool get showInterstitialAds {
    try {
      return _remoteConfig.getBool('weight_scan_show_interstitial_ads');
    } catch (e) {
      print('⚠️ Error getting weight_scan_show_interstitial_ads: $e');
      return _defaults['weight_scan_show_interstitial_ads'] as bool;
    }
  }

  bool get showFbInterstitialAds {
    try {
      return _remoteConfig.getBool('weight_scan_show_fb_interstitial_ads');
    } catch (e) {
      print('⚠️ Error getting weight_scan_show_fb_interstitial_ads: $e');
      return _defaults['weight_scan_show_fb_interstitial_ads'] as bool;
    }
  }


  /// Get interstitial ad frequency (show after X screens)
  int get interstitialAdFrequency {
    try {
      final frequency = _remoteConfig.getInt('weight_scan_interstitial_ad_frequency');
      final finalFrequency = frequency > 0 ? frequency : 5;
      print('🔧 Firebase Remote Config - weight_scan_interstitial_ad_frequency: $finalFrequency (raw: $frequency)');
      return finalFrequency; // Minimum 1
    } catch (e) {
      print('⚠️ Error getting weight_scan_interstitial_ad_frequency: $e');
      final defaultFreq = _defaults['weight_scan_interstitial_ad_frequency'] as int;
      print('🔧 Using default frequency: $defaultFreq');
      return defaultFreq;
    }
  }


  String get bannerAdUnitId {
    try {
      if (Platform.isAndroid) {
        return _remoteConfig.getString('weight_scan_android_banner_ad_id');
      } else if (Platform.isIOS) {
        return _remoteConfig.getString('weight_scan_ios_banner_ad_id');
      }
    } catch (e) {
      print('⚠️ Error getting banner ad unit ID: $e');
    }
    
    if (Platform.isAndroid) {
      return _defaults['weight_scan_android_banner_ad_id'] as String;
    } else if (Platform.isIOS) {
      return _defaults['weight_scan_ios_banner_ad_id'] as String;
    }
    throw UnsupportedError('Unsupported platform');
  }

  String get interstitialAdUnitId {
    try {
      if (Platform.isAndroid) {
        return _remoteConfig.getString('weight_scan_android_interstitial_ad_id');
      } else if (Platform.isIOS) {
        return _remoteConfig.getString('weight_scan_ios_interstitial_ad_id');
      }
    } catch (e) {
      print('⚠️ Error getting interstitial ad unit ID: $e');
    }
    
    if (Platform.isAndroid) {
      return _defaults['weight_scan_android_interstitial_ad_id'] as String;
    } else if (Platform.isIOS) {
      return _defaults['weight_scan_ios_interstitial_ad_id'] as String;
    }
    throw UnsupportedError('Unsupported platform');
  }

  String get nativeAdUnitId {
    try {
      if (Platform.isAndroid) {
        return _remoteConfig.getString('weight_scan_android_native_ad_id');
      } else if (Platform.isIOS) {
        return _remoteConfig.getString('weight_scan_ios_native_ad_id');
      }
    } catch (e) {
      print('⚠️ Error getting native ad unit ID: $e');
    }
    
    if (Platform.isAndroid) {
      return _defaults['weight_scan_android_native_ad_id'] as String;
    } else if (Platform.isIOS) {
      return _defaults['weight_scan_ios_native_ad_id'] as String;
    }
    throw UnsupportedError('Unsupported platform');
  }

  String get openAdUnitId {
    try {
      if (Platform.isAndroid) {
        return _remoteConfig.getString('weight_scan_android_open_ad_id');
      } else if (Platform.isIOS) {
        return _remoteConfig.getString('weight_scan_ios_open_ad_id');
      }
    } catch (e) {
      print('⚠️ Error getting open ad unit ID: $e');
    }
    
    if (Platform.isAndroid) {
      return _defaults['weight_scan_android_open_ad_id'] as String;
    } else if (Platform.isIOS) {
      return _defaults['weight_scan_ios_open_ad_id'] as String;
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Facebook Ad Unit IDs
  String get fbBannerAdUnitId {
    try {
      if (Platform.isAndroid) {
        return _remoteConfig.getString('weight_scan_android_fb_banner_ad_id');
      } else if (Platform.isIOS) {
        return _remoteConfig.getString('weight_scan_ios_fb_banner_ad_id');
      }
    } catch (e) {
      print('⚠️ Error getting FB banner ad unit ID: $e');
    }
    
    if (Platform.isAndroid) {
      return _defaults['weight_scan_android_fb_banner_ad_id'] as String;
    } else if (Platform.isIOS) {
      return _defaults['weight_scan_ios_fb_banner_ad_id'] as String;
    }
    throw UnsupportedError('Unsupported platform');
  }

  String get fbInterstitialAdUnitId {
    try {
      if (Platform.isAndroid) {
        return _remoteConfig.getString('weight_scan_android_fb_interstitial_ad_id');
      } else if (Platform.isIOS) {
        return _remoteConfig.getString('weight_scan_ios_fb_interstitial_ad_id');
      }
    } catch (e) {
      print('⚠️ Error getting FB interstitial ad unit ID: $e');
    }
    
    if (Platform.isAndroid) {
      return _defaults['weight_scan_android_fb_interstitial_ad_id'] as String;
    } else if (Platform.isIOS) {
      return _defaults['weight_scan_ios_fb_interstitial_ad_id'] as String;
    }
    throw UnsupportedError('Unsupported platform');
  }

  String get fbNativeAdUnitId {
    try {
      if (Platform.isAndroid) {
        return _remoteConfig.getString('weight_scan_android_fb_native_ad_id');
      } else if (Platform.isIOS) {
        return _remoteConfig.getString('weight_scan_ios_fb_native_ad_id');
      }
    } catch (e) {
      print('⚠️ Error getting FB native ad unit ID: $e');
    }
    
    if (Platform.isAndroid) {
      return _defaults['weight_scan_android_fb_native_ad_id'] as String;
    } else if (Platform.isIOS) {
      return _defaults['weight_scan_ios_fb_native_ad_id'] as String;
    }
    throw UnsupportedError('Unsupported platform');
  }


  /// Get all config values (useful for debugging)
  Map<String, dynamic> getAllValues() {
    return {
      'show_banner_ads': showBannerAds,
      'show_native_ads': showNativeAds,
      'show_interstitial_ads': showInterstitialAds,
      'interstitial_ad_frequency': interstitialAdFrequency,
      'banner_ad_unit_id': bannerAdUnitId,
      'interstitial_ad_unit_id': interstitialAdUnitId,
      'native_ad_unit_id': nativeAdUnitId,
    };
  }
}
