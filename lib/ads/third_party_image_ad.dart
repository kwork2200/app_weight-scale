import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/remote_config_service.dart';

/// Third-party image ad widget (fallback when Google/Facebook ads are disabled)
/// Shows assets/images/third_image_ads.jpg and opens URL on tap
class ThirdPartyImageAd extends StatelessWidget {
  final double height;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final bool isNativeSize; // true for native ad size, false for banner size

  const ThirdPartyImageAd({
    super.key,
    this.height = 320,
    this.margin,
    this.padding,
    this.isNativeSize = true,
  });

  /// Open the third-party ad URL in browser
  Future<void> _openAdUrl(BuildContext context) async {
    final url = RemoteConfigService.instance.thirdPartyAdUrl;
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('✅ Opened third-party ad URL: $url');
      } else {
        print('❌ Cannot launch URL: $url');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open ad link'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error launching URL: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening ad link'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openAdUrl(context),
      child: Container(
        margin: margin ?? (isNativeSize 
            ? const EdgeInsets.symmetric(vertical: 8) 
            : EdgeInsets.zero),
        padding: padding,
        decoration: isNativeSize ? BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ) : null,
        height: height,
        child: ClipRRect(
          borderRadius: isNativeSize ? BorderRadius.circular(12) : BorderRadius.zero,
          child: Image.asset(
            'assets/images/third_image_ads.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: height,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Error loading third-party ad image: $error');
              return Container(
                color: Colors.grey.shade800,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
