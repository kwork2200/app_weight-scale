// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../../utils/functions.dart';
// import 'hybrid_banner_ad_widget.dart';
//
// /// Wrapper widget that adds banner ads to any screen
// class AdEnabledScreen extends StatefulWidget {
//   final Widget child;
//   final bool showBanner;
//   final bool showInterstitialOnEnter;
//
//   const AdEnabledScreen({
//     super.key,
//     required this.child,
//     this.showBanner = true,
//     this.showInterstitialOnEnter = true,
//   });
//
//   @override
//   State<AdEnabledScreen> createState() => _AdEnabledScreenState();
// }
//
// class _AdEnabledScreenState extends State<AdEnabledScreen> {
//   static const String _skipInterstitialKey = 'skip_interstitial_on_next_screen';
//
//   @override
//   void initState() {
//     super.initState();
//
//     _checkAndShowInterstitial();
//   }
//
//   Future<void> _checkAndShowInterstitial() async {
//     final prefs = await SharedPreferences.getInstance();
//     final skipInterstitial = prefs.getBool(_skipInterstitialKey) ?? false;
//
//     if (skipInterstitial) {
//       // Reset the flag after consuming it
//       await prefs.setBool(_skipInterstitialKey, false);
//       print('⏭️ Skipping interstitial ad (app resumed from background)');
//       return;
//     }
//
//     if (widget.showInterstitialOnEnter) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         showManagedInterstitialAd(context, alwaysShow: false);
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Expanded(child: widget.child),
//         if (widget.showBanner)
//           SafeArea(
//             top: false,
//             child: const HybridBannerAdWidget (),
//           ),
//       ],
//     );
//   }
// }