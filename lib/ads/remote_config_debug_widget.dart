// import 'package:flutter/material.dart';
// import '../../../services/remote_config_service.dart';
//
// /// Debug widget to display current Remote Config values
// /// Useful for testing and verifying Remote Config is working
// ///
// /// Usage:
// /// ```dart
// /// Scaffold(
// ///   body: Column(
// ///     children: [
// ///       RemoteConfigDebugWidget(), // Add this for debugging
// ///       // Your normal content...
// ///     ],
// ///   ),
// /// )
// /// ```
// class RemoteConfigDebugWidget extends StatelessWidget {
//   const RemoteConfigDebugWidget({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final config = RemoteConfigService.instance;
//
//     return Container(
//       margin: const EdgeInsets.all(8),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.black87,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.yellow, width: 2),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(
//             children: [
//               const Icon(Icons.bug_report, color: Colors.yellow, size: 16),
//               const SizedBox(width: 8),
//               const Text(
//                 'Remote Config Debug',
//                 style: TextStyle(
//                   color: Colors.yellow,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14,
//                 ),
//               ),
//               const Spacer(),
//               IconButton(
//                 icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
//                 onPressed: () async {
//                   await config.fetchAndActivate();
//                   // Trigger rebuild
//                   (context as Element).markNeedsBuild();
//                 },
//                 tooltip: 'Fetch Latest Config',
//               ),
//             ],
//           ),
//           const Divider(color: Colors.yellow),
//           _buildConfigRow('Banner Ads', config.showBannerAds),
//           _buildConfigRow('Native Ads', config.showNativeAds),
//           _buildConfigRow('Interstitial Ads', config.showInterstitialAds),
//           _buildConfigRow('Ad Frequency', config.interstitialAdFrequency),
//           const SizedBox(height: 4),
//           Text(
//             'Banner ID: ${config.bannerAdUnitId.substring(0, 20)}...',
//             style: const TextStyle(color: Colors.white70, fontSize: 10),
//           ),
//           Text(
//             'Interstitial ID: ${config.interstitialAdUnitId.substring(0, 20)}...',
//             style: const TextStyle(color: Colors.white70, fontSize: 10),
//           ),
//           Text(
//             'Native ID: ${config.nativeAdUnitId.substring(0, 20)}...',
//             style: const TextStyle(color: Colors.white70, fontSize: 10),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildConfigRow(String label, dynamic value) {
//     Color valueColor = Colors.white;
//     String displayValue = value.toString();
//
//     if (value is bool) {
//       valueColor = value ? Colors.green : Colors.red;
//       displayValue = value ? '✓ Enabled' : '✗ Disabled';
//     } else if (value is int) {
//       displayValue = 'Every $value screens';
//     }
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(color: Colors.white, fontSize: 12),
//           ),
//           Text(
//             displayValue,
//             style: TextStyle(
//               color: valueColor,
//               fontSize: 12,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
