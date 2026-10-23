import 'package:flutter/material.dart';
import 'dart:async';
import '../services/ad_service.dart';
import '../services/fb_ad_service.dart';
import '../services/remote_config_service.dart';
import 'native_ad_widget.dart';
import 'fb_native_ad_widget.dart';
import 'third_party_image_ad.dart';

class HybridNativeAdWidget extends StatefulWidget {
  final double height;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final String? adKey;
  final double? smallHeight;

  const HybridNativeAdWidget({
    super.key,
    this.height = 150,
    this.margin,
    this.padding,
    this.adKey,
    this.smallHeight,
  });

  @override
  State<HybridNativeAdWidget> createState() => _HybridNativeAdWidgetState();
}

class _HybridNativeAdWidgetState extends State<HybridNativeAdWidget> {
  StreamSubscription? _configSubscription;
  bool _useFacebookAds = false;
  bool _showGoogleAds = false;
  bool _showFacebookAds = false;

  @override
  void initState() {
    super.initState();
    _updateAdPreferences();
    _configSubscription = RemoteConfigService.instance.configUpdates.listen((_) {
      _updateAdPreferences();
    });
  }

  void _updateAdPreferences() {
    setState(() {
      _useFacebookAds = RemoteConfigService.instance.useFacebookAds;
      _showGoogleAds = _getGoogleAdVisibility();
      _showFacebookAds = _getFacebookAdVisibility();
      
      print('🔀 HybridNativeAd [${widget.adKey}]: Google=$_showGoogleAds, FB=$_showFacebookAds');
    });
  }

  bool _getGoogleAdVisibility() {
    print("AdService.instance.shouldShowNativeAds ======> ${AdService.instance.shouldShowNativeAds}");
    switch (widget.adKey) {
      default:
        return AdService.instance.shouldShowNativeAds;
    }
  }

  bool _getFacebookAdVisibility() {
    print("AdService.instance.shouldShowNativeAds ======> ${AdService.instance.shouldShowNativeAds}");

    switch (widget.adKey) {
      default:
        return FbAdService.instance.shouldShowNativeAds;
    }
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
      return FbNativeAdWidget(
        height: widget.height,
        margin: widget.margin,
        padding: widget.padding,
        adKey: widget.adKey,
      );
    }

    // Priority 2: Google Native Ad
    if (_showGoogleAds) {
      return NativeAdWidget(
        smallHeight: widget.smallHeight,
        height: 300,
        adKey: widget.adKey,
        size: NativeAdSize.small,
      );
    }

    // Priority 3: If Google is disabled/false, try Facebook Native Ad
    if (_showFacebookAds) {
      return FbNativeAdWidget(
        height: widget.height,
        margin: widget.margin,
        padding: widget.padding,
        adKey: widget.adKey,
      );
    }

    // Priority 3: If both Google and Facebook are disabled/false, try Third-Party Native Ad
    final showThirdPartyAd = RemoteConfigService.instance.showThirdPartyNativeAds;
    if (showThirdPartyAd) {
      return ThirdPartyImageAd(
        height: widget.height,
        margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8),
        padding: widget.padding,
        isNativeSize: true,
      );
    }

    // If all three are disabled/false, return empty widget
    return const SizedBox.shrink();
  }
}
