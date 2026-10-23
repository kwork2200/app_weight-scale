import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';
import '../services/ad_service.dart';
import '../services/fb_ad_service.dart';
import '../services/remote_config_service.dart';
import 'third_party_image_ad.dart';

/// Reusable Banner Ad Widget with real-time Remote Config updates
/// Falls back to third-party image ad when Google/Facebook ads are disabled
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  StreamSubscription? _configSubscription;
  bool _shouldShowAds = false;
  AdSize? _adSize;

  @override
  void initState() {
    super.initState();
    _shouldShowAds = AdService.instance.shouldShowBannerAds;

    // Listen to Remote Config changes
    _configSubscription = RemoteConfigService.instance.configUpdates.listen((_) {
      _handleConfigUpdate();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shouldShowAds && _bannerAd == null && !_isAdLoaded) {
      _loadBannerAd();
    }
  }
  
  void _handleConfigUpdate() {
    final newValue = AdService.instance.shouldShowBannerAds;
    
    // If value changed
    if (newValue != _shouldShowAds) {
      setState(() {
        _shouldShowAds = newValue;
      });
      
      if (_shouldShowAds) {
        // Ads enabled, load ad
        print('📢 Banner ads enabled via Remote Config');
        _loadBannerAd();
      } else {
        // Ads disabled, dispose current ad
        print('🚫 Banner ads disabled via Remote Config');
        _bannerAd?.dispose();
        _bannerAd = null;
        setState(() {
          _isAdLoaded = false;
        });
      }
    }
  }

  void _loadBannerAd() async {
    final screenWidth = MediaQuery.of(context).size.width.truncate();
    final adSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(screenWidth);

    if (!mounted) return;

    setState(() {
      _adSize = adSize ?? AdSize.banner;
    });

    _bannerAd = AdService.instance.createBannerAd(
      size: _adSize,
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() {
            _isAdLoaded = true;
          });
        }
        print('✅ Banner ad loaded');
      },
      onAdFailedToLoad: (ad, error) {
        print('❌ Banner ad failed to load: $error');
        ad.dispose();
      },
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _configSubscription?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if Google/Facebook banner ads are disabled
    final googleAdsDisabled = !AdService.instance.shouldShowBannerAds;
    final facebookAdsDisabled = !FbAdService.instance.shouldShowBannerAds;
    final showThirdPartyAd = RemoteConfigService.instance.showThirdPartyBannerAds;
    print('📢 googleAdsDisabled%$googleAdsDisabled   facebookAdsDisabled $facebookAdsDisabled  showThirdPartyAd $showThirdPartyAd');
    // If both Google and Facebook ads are disabled, show third-party image ad
    if (googleAdsDisabled && facebookAdsDisabled && showThirdPartyAd) {
      print('📢 Showing third-party banner image ad (Google & Facebook ads disabled)');
      return const ThirdPartyImageAd(
        height: 50, // Standard banner height
        isNativeSize: false,
        margin: EdgeInsets.zero,
      );
    }
    
    // Check Remote Config flag (real-time)
    if (!_shouldShowAds) {
      return const SizedBox.shrink();
    }

    if (!_isAdLoaded || _bannerAd == null || _adSize == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: _adSize!.height.toDouble()-10,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
