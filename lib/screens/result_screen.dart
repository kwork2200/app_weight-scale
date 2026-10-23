import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../ads/hybrid_banner_ad_widget.dart';
import '../ads/hybrid_native_ad_widget.dart';
import '../models/estimation_result.dart';
import '../utils/functions.dart';
import '../widgets/weight_gauge.dart';
import 'camera_scan_screen.dart';

class ResultScreen extends StatelessWidget {
  final WeightEstimationResult result;
  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        showInterstitialThenPop(context, popToFirst: true);
      },
      child: Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      bottomNavigationBar: const SafeArea(top: false, child: HybridBannerAdWidget()),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF0A0E1A),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () =>
                  showInterstitialThenPop(context, popToFirst: true),
            ),
            title: const Text('Scan Result',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Object image preview
                if (result.imagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Image.file(
                        File(result.imagePath!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms),

                const Gap(20),

                // Object name card
                // _ObjectNameCard(result: result).animate().fadeIn(delay: 100.ms),

                const Gap(16),

                // Weight Display
                const HybridNativeAdWidget(),

                const Gap(16),

                _WeightCard(result: result).animate().fadeIn(delay: 200.ms),

                const Gap(16),

                // Confidence gauge
                _ConfidenceCard(result: result).animate().fadeIn(delay: 300.ms),

                const Gap(16),

                // Details
                const HybridNativeAdWidget(),

                const Gap(16),

                _DetailsCard(result: result).animate().fadeIn(delay: 400.ms),

                const Gap(16),

                // Detected labels
                if (result.detectedLabels.isNotEmpty)
                  _DetectedLabelsCard(labels: result.detectedLabels)
                      .animate()
                      .fadeIn(delay: 500.ms),

                const Gap(24),

                // Scan Again button
                _ScanAgainButton().animate().fadeIn(delay: 600.ms),

                const Gap(24),
              ]),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _ObjectNameCard extends StatelessWidget {
  final WeightEstimationResult result;
  const _ObjectNameCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2940),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(result.icon, style: const TextStyle(fontSize: 52)),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.objectName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  result.objectNameHindi,
                  style: const TextStyle(
                    color: Color(0xFF00D4AA),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Gap(4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4AA).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF00D4AA).withOpacity(0.3)),
                  ),
                  child: Text(
                    result.category.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF00D4AA),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
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

class _WeightCard extends StatelessWidget {
  final WeightEstimationResult result;
  const _WeightCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D4AA), Color(0xFF0066FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4AA).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Estimated Weight',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
          const Gap(8),
          Text(
            result.formattedWeight,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
            ),
          ),
          const Gap(4),
          Text(
            'Range: ${result.formattedRange}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const Gap(16),
          WeightGauge(
            value: result.estimatedWeightGrams,
            min: result.minWeightGrams,
            max: result.maxWeightGrams,
          ),
        ],
      ),
    );
  }
}

class _ConfidenceCard extends StatelessWidget {
  final WeightEstimationResult result;
  const _ConfidenceCard({required this.result});

  Color get _confidenceColor {
    if (result.confidenceScore >= 0.85) return const Color(0xFF00D4AA);
    if (result.confidenceScore >= 0.65) return Colors.amber;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2940),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 45,
            lineWidth: 8,
            percent: result.confidenceScore.clamp(0.0, 1.0),
            center: Text(
              '${result.confidencePercent}%',
              style: TextStyle(
                color: _confidenceColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            progressColor: _confidenceColor,
            backgroundColor: _confidenceColor.withOpacity(0.15),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const Gap(20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Confidence',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const Gap(4),
                Text(
                  result.confidenceLabel,
                  style: TextStyle(
                    color: _confidenceColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Gap(4),
                Text(
                  'Material: ${result.inferredMaterial}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 11,
                  ),
                ),
                if (result.hasReferenceObject) ...[
                  const Gap(6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFF00D4AA).withOpacity(0.5)),
                    ),
                    child: const Text(
                      '📏 Real scale detected',
                      style: TextStyle(
                          color: Color(0xFF00D4AA),
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
                if (result.accuracyTip.isNotEmpty) ...[
                  const Gap(6),
                  Text(
                    result.accuracyTip,
                    style: TextStyle(
                      color: Colors.amber.withOpacity(0.8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final WeightEstimationResult result;
  const _DetailsCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Object Name', result.objectName),
      ('Category', result.category.toUpperCase()),
      ('Min Weight', result.minWeightGrams >= 1000 ? '${(result.minWeightGrams / 1000).toStringAsFixed(2)} kg' : '${result.minWeightGrams.toStringAsFixed(0)} g'),
      ('Max Weight', result.maxWeightGrams >= 1000 ? '${(result.maxWeightGrams / 1000).toStringAsFixed(2)} kg' : '${result.maxWeightGrams.toStringAsFixed(0)} g'),
      ('Scan Time', '${result.timestamp.hour}:${result.timestamp.minute.toString().padLeft(2, '0')}'),
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
            'Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(16),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.$1,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13)),
                    Text(r.$2,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _DetectedLabelsCard extends StatelessWidget {
  final List<String> labels;
  const _DetectedLabelsCard({required this.labels});

  @override
  Widget build(BuildContext context) {
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
            'AI Detected Labels',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: labels
                .map((l) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Text(l,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ScanAgainButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CameraScanScreen()),
        ),
        icon: const Icon(Icons.document_scanner),
        label: const Text(
          'Scan Again',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00D4AA),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
