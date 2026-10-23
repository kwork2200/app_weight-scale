import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/fb_ad_service.dart';
import '../services/remote_config_service.dart';

/// Facebook Native Ad Widget using Platform View with third-party image fallback
class FbNativeAdWidget extends StatefulWidget {
  final double height;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final String? adKey; // Screen-specific key

  const FbNativeAdWidget({
    super.key,
    this.height = 320,
    this.margin,
    this.padding,
    this.adKey,
  });

  @override
  State<FbNativeAdWidget> createState() => _FbNativeAdWidgetState();
}

class _FbNativeAdWidgetState extends State<FbNativeAdWidget> {
  StreamSubscription? _configSubscription;
  bool _shouldShowAds = false;

  @override
  void initState() {
    super.initState();
    _shouldShowAds = _getAdVisibility();

    // Listen to Remote Config changes
    _configSubscription = RemoteConfigService.instance.configUpdates.listen((_) {
      _handleConfigUpdate();
    });
  }

  bool _getAdVisibility() {
    switch (widget.adKey) {
      default:
        return FbAdService.instance.shouldShowNativeAds;
    }
  }

  void _handleConfigUpdate() {
    final newValue = _getAdVisibility();

    if (newValue != _shouldShowAds) {
      setState(() {
        _shouldShowAds = newValue;
      });

      if (_shouldShowAds) {
        print('📢 FB native ads ${widget.adKey ?? 'default'} enabled via Remote Config');
      } else {
        print('🚫 FB native ads ${widget.adKey ?? 'default'} disabled via Remote Config');
      }
    }
  }

  @override
  void dispose() {
    _configSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShowAds) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8),
      padding: widget.padding,
      height: widget.height,
      child: AndroidView(
        viewType: 'fb_native_ad_view',
        creationParams: {
          'placementId': FbAdService.instance.nativeAdUnitId,
        },
        creationParamsCodec: const StandardMessageCodec(),
      ),
    );
  }
}
