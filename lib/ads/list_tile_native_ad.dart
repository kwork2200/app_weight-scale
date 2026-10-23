import 'dart:developer';
import 'package:app_weight_scale/services/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Customizable native ad widget with adjustable height and width
/// Based on the listTile factory registered in MainActivity
class ListTileNativeAd extends StatefulWidget {
  final double? height;
  final double? width;
  final String? adUnitId;

  const ListTileNativeAd({
    Key? key,
    this.height = 250,
    this.width,
    this.adUnitId,
  }) : super(key: key);

  @override
  State<ListTileNativeAd> createState() => _ListTileNativeAdState();
}

class _ListTileNativeAdState extends State<ListTileNativeAd> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: widget.adUnitId ?? AdService.instance.nativeAdUnitId,
      factoryId: 'listTile',
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
            log("ListTile Native Ad Loaded");
          }
        },
        onAdFailedToLoad: (ad, error) {
          log("ListTile Native Ad Failed to load: ${error.message}");
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
            });
          }
        },
        onAdClicked: (_) {
          log("ListTile Native Ad Clicked");
        },
        onAdImpression: (_) {
          log("ListTile Native Ad Impression");
        },
      ),
      request: const AdRequest(),
    );

    _nativeAd!.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width ?? MediaQuery.of(context).size.width,
      child: _isAdLoaded
          ? AdWidget(ad: _nativeAd!)
          : Center(
              child: CircularProgressIndicator(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
    );
  }
}

/// Native ad container that handles loading and error states
class NativeAdContainer extends StatefulWidget {
  final double height;
  final double? width;
  final Widget? placeholder;
  final Widget? errorWidget;
  final String? adUnitId;

  const NativeAdContainer({
    Key? key,
    this.height = 250,
    this.width,
    this.placeholder,
    this.errorWidget,
    this.adUnitId,
  }) : super(key: key);

  @override
  State<NativeAdContainer> createState() => _NativeAdContainerState();
}

class _NativeAdContainerState extends State<NativeAdContainer> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: widget.adUnitId ?? AdService.instance.nativeAdUnitId,
      factoryId: 'listTile',
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
              _hasError = false;
            });
            log("Native Ad Container - Ad Loaded");
          }
        },
        onAdFailedToLoad: (ad, error) {
          log("Native Ad Container - Failed to load: ${error.message}");
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              _hasError = true;
            });
          }
        },
      ),
      request: const AdRequest(),
    );

    _nativeAd!.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ?? const SizedBox.shrink();
    }

    if (!_isAdLoaded) {
      return widget.placeholder ??
          Container(
            height: widget.height,
            width: widget.width ?? MediaQuery.of(context).size.width,
            color: Colors.black12,
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          );
    }

    return Container(
      height: widget.height,
      width: widget.width ?? MediaQuery.of(context).size.width,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}

/// Simple helper widget for native ads
Widget nativeAdWidget({
  double height = 250,
  double? width,
  String? adUnitId,
}) {
  return ListTileNativeAd(
    height: height,
    width: width,
    adUnitId: adUnitId,
  );
}
