import 'package:flutter/material.dart';
import 'dart:async';
import '../services/ad_service.dart';
import '../services/fb_ad_service.dart';
import '../services/remote_config_service.dart';
import 'banner_ad_widget.dart';
import 'fb_banner_ad_widget.dart';
import 'third_party_image_ad.dart';

/// Hybrid Banner Ad Widget - Shows Facebook or Google ads based on Remote Config
class HybridBannerAdWidget extends StatefulWidget {
  const HybridBannerAdWidget({super.key});

  @override
  State<HybridBannerAdWidget> createState() => _HybridBannerAdWidgetState();
}

class _HybridBannerAdWidgetState extends State<HybridBannerAdWidget> {
  StreamSubscription? _configSubscription;
  bool _useFacebookAds = false;
  bool _showGoogleAds = false;
  bool _showFacebookAds = false;

  @override
  void initState() {
    super.initState();
    _updateAdPreferences();

    // Listen to Remote Config changes
    _configSubscription = RemoteConfigService.instance.configUpdates.listen((_) {
      _updateAdPreferences();
    });
  }

  void _updateAdPreferences() {
    setState(() {
      _useFacebookAds = RemoteConfigService.instance.useFacebookAds;
      _showGoogleAds = AdService.instance.shouldShowBannerAds;
      _showFacebookAds = FbAdService.instance.shouldShowBannerAds;
    });
  }

  @override
  void dispose() {
    _configSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Facebook ads take priority when use_facebook_ads is enabled in Remote Config
    if (_useFacebookAds && _showFacebookAds) {
      return const FbBannerAdWidget();
    }

    if (_showGoogleAds) {
      return const BannerAdWidget();
    }

    if (_showFacebookAds) {
      return const FbBannerAdWidget();
    }

    // Show third-party image ad only if enabled in Remote Config
    final showThirdPartyAd = RemoteConfigService.instance.showThirdPartyBannerAds;
    if (showThirdPartyAd) {
      return const ThirdPartyImageAd(
        height: 45,
        isNativeSize: false,
        margin: EdgeInsets.zero,
      );
    }

    // If third-party ads are also disabled, show nothing
    return const SizedBox.shrink();
  }
}
