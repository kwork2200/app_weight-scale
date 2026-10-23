import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../ads/app_open_ad_manager.dart';
import '../services/remote_config_service.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(seconds: 2));
    await _requestPermissions();
    if (!mounted) return;
    await _showAppOpenAdThenGoHome();
  }

  Future<void> _showAppOpenAdThenGoHome() async {
    bool navigated = false;

    void goHome() {
      if (navigated || !mounted) return;
      navigated = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }

    if (!RemoteConfigService.instance.showOpenAds) {
      goHome();
      return;
    }

    final manager = AppOpenAdManager.instance;
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!manager.isAdAvailable && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
    }

    if (!mounted) return;

    if (manager.isAdAvailable) {
      manager.showAdIfAvailable(onAdDismissed: goHome);
    } else {
      goHome();
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.storage,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D4AA), Color(0xFF0066FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D4AA).withOpacity(0.4),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.scale,
                color: Colors.white,
                size: 60,
              ),
            )
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 32),
            Text(
              'WeighScan AI',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
            )
                .animate(delay: 300.ms)
                .fadeIn()
                .slideY(begin: 0.3, end: 0),
            const SizedBox(height: 8),
            Text(
              'Camera se weight measure karo',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF00D4AA),
                  ),
            )
                .animate(delay: 500.ms)
                .fadeIn()
                .slideY(begin: 0.3, end: 0),
            const SizedBox(height: 60),
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                color: Color(0xFF00D4AA),
                backgroundColor: Color(0xFF1E2940),
              ),
            ).animate(delay: 700.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}
