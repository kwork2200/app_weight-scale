import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'Face scan button and setup.dart';
import 'camera_scan_screen.dart';
import 'history_screen.dart';
import '../ads/hybrid_banner_ad_widget.dart';
import '../ads/hybrid_native_ad_widget.dart';
import '../models/weight_database.dart';
import '../utils/functions.dart';
import '../widgets/app_drawer.dart';
import '../widgets/category_chip.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = {
      '🍎 Fruits': 'fruit',
      '🥦 Vegetables': 'vegetable',
      '📱 Electronics': 'electronics',
      '🍔 Food': 'food',
      '📚 Stationery': 'stationery',
      '⚽ Sports': 'sports',
    };

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      drawer: const AppDrawer(),
      bottomNavigationBar: const SafeArea(top: false, child: HybridBannerAdWidget()),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0A0E1A),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'WeighScan AI',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A0E1A), Color(0xFF0D1929)],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white70),
                onPressed: () =>
                    showInterstitialThenNavigate(context, const HistoryScreen()),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ScanButton().animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                const Gap(28),
                _AccuracyCard().animate().fadeIn(delay: 200.ms),
                const Gap(10),
                const HybridNativeAdWidget(),
                const Gap(15),
                FaceScanButton(),
                const Gap(28),
                Text(
                  'Supported Objects',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ).animate().fadeIn(delay: 300.ms),
                const Gap(12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.entries
                      .map((e) => CategoryChip(label: e.key, category: e.value))
                      .toList(),
                ).animate().fadeIn(delay: 400.ms),
                const Gap(10),
                const HybridNativeAdWidget(),
                const Gap(20),
                _HowToUseCard().animate().fadeIn(delay: 500.ms),
                const Gap(18),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          showInterstitialThenNavigate(context, const CameraScanScreen()),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00D4AA), Color(0xFF0066FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D4AA).withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Opacity(
                opacity: 0.15,
                child: Icon(
                  Icons.camera_alt,
                  size: 160,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.document_scanner,
                        color: Colors.white, size: 32),
                  ),
                  const Gap(16),
                  const Text(
                    'Scan & Weigh',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Scan object using camera',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccuracyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2940),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.verified, color: Color(0xFF00D4AA), size: 28),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '85–95% Accuracy',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'AI + object size analysis estimates the weight',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HowToUseCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      (
      '1',
      Icons.camera_alt,
      'Open Camera',
      'Tap the scan button'
      ),

      (
      '2',
      Icons.center_focus_strong,
      'Frame the Object',
      'Keep the object in the center'
      ),

      (
      '3',
      Icons.flash_on,
      'Capture Photo',
      'Take the picture'
      ),

      (
      '4',
      Icons.scale,
      'View Result',
      'Weight estimate will appear'
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2940),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How to Use?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const Gap(16),
          ...steps.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D4AA), Color(0xFF0066FF)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(s.$1,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12)),
                      ),
                    ),
                    const Gap(12),
                    Icon(s.$2, color: const Color(0xFF00D4AA), size: 20),
                    const Gap(8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.$3,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        Text(s.$4,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
