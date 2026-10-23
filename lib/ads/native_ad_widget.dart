import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';
import '../services/ad_service.dart';
import '../services/remote_config_service.dart';

enum NativeAdSize { small, large }

class NativeAdWidget extends StatefulWidget {
  final double height;
  final String? adKey;
  final NativeAdSize size;
  final double? smallHeight; // Custom height for small ads
  final double? largeHeight; // Custom height for large ads

  const NativeAdWidget({
    super.key,
    this.height = 300,
    this.adKey,
    this.size = NativeAdSize.large,
    this.smallHeight,
    this.largeHeight,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _hasError = false;
  StreamSubscription? _configSubscription;
  bool _shouldShowAds = false;

  bool get _isSmall => widget.size == NativeAdSize.small;
  
  double get _adHeight {
    if (_isSmall) {
      return widget.smallHeight ?? 70.0; // Use custom small height or default 70
    } else {
      return widget.largeHeight ?? widget.height; // Use custom large height or widget height
    }
  }

  @override
  void initState() {
    super.initState();
    _shouldShowAds = _getAdVisibility();
    if (_shouldShowAds) _loadNativeAd();
    _configSubscription = RemoteConfigService.instance.configUpdates.listen((_) {
      _handleConfigUpdate();
    });
  }

  bool _getAdVisibility() {
    switch (widget.adKey) {
      default:
        return AdService.instance.shouldShowNativeAds;
    }
  }

  void _handleConfigUpdate() {
    final newValue = _getAdVisibility();
    if (newValue != _shouldShowAds) {
      setState(() => _shouldShowAds = newValue);
      if (_shouldShowAds) {
        _loadNativeAd();
      } else {
        _nativeAd?.dispose();
        _nativeAd = null;
        setState(() {
          _isAdLoaded = false;
          _hasError = false;
        });
      }
    }
  }

  void _loadNativeAd() {
    try {
      _nativeAd = AdService.instance.createNativeAd(
        factoryId: _isSmall ? 'smallNativeAd' : 'nativeAd',
        onAdLoaded: (ad) {
          if (mounted) setState(() { _isAdLoaded = true; _hasError = false; });
        },
        onAdFailedToLoad: (ad, error) {
          if (mounted) setState(() => _hasError = true);
          ad.dispose();
        },
      );
      _nativeAd?.load();
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _configSubscription?.cancel();
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('_adHeight -->$_adHeight');
    if (!_shouldShowAds || _hasError || !_isAdLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      // margin: const EdgeInsets.symmetric(vertical: 8),
      // padding: _isSmall ? EdgeInsets.zero : const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      height: _adHeight,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}