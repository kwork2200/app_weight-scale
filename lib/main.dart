import 'package:app_weight_scale/ads/app_open_ad_manager.dart';
import 'package:app_weight_scale/ads/interstitial_ad_manager.dart';
import 'package:app_weight_scale/firebase_options.dart';
import 'package:app_weight_scale/services/app_lifecycle_service.dart';
import 'package:app_weight_scale/services/remote_config_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/splash_screen.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );


  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await MobileAds.instance.initialize();
  print('✅ Google Mobile Ads initialized');

  print('🔄 Preloading App Open Ad at app startup...');
  AppOpenAdManager.instance.loadAd();

  await RemoteConfigService.instance.initialize();

  print('🔄 Preloading Interstitial Ad at app startup...');
  InterstitialAdManager.instance.loadAd();

  Get.put(AppLifecycleService(), permanent: true);

  runApp(const WeightEstimatorApp());
}

class WeightEstimatorApp extends StatelessWidget {
  const WeightEstimatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weight Scale',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D4AA),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
      ),
      home: const SplashScreen(),
    );
  }
}
