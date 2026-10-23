
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../ads/hybrid_banner_ad_widget.dart';
import '../ads/hybrid_native_ad_widget.dart';
import '../utils/functions.dart';
import 'Face scan camera screen.dart';
import 'face_weight_estimation_result.dart';

class FaceWeightResultScreen extends StatelessWidget {
  final FaceWeightEstimationResult result;
  const FaceWeightResultScreen({super.key, required this.result});

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
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () =>
                  showInterstitialThenPop(context, popToFirst: true),
            ),
            title: Row(
              children: [
                Text(result.ageGroupEmoji, style: const TextStyle(fontSize: 22)),
                const Gap(8),
                const Text('Face Weight Result',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Age Group Chip ────────────────────────────────────────
                if (result.ageGroup.isNotEmpty)
                  _AgeGroupBanner(result: result)
                      .animate().fadeIn(duration: 300.ms),
                if (result.ageGroup.isNotEmpty) const Gap(16),

                // ── Photo ────────────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Image.file(File(result.imagePath), fit: BoxFit.cover),
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const Gap(10),

                const HybridNativeAdWidget(),
                const Gap(16),

                // ── Weight Card ───────────────────────────────────────────
                _WeightCard(result: result).animate().fadeIn(delay: 100.ms),
                const Gap(16),

                // ── BMI Card ─────────────────────────────────────────────
                _BMICard(result: result).animate().fadeIn(delay: 200.ms),
                const Gap(16),

                // ── Visual Cues Row ───────────────────────────────────────
                if (_hasVisualCues(result))
                  _VisualCuesCard(result: result).animate().fadeIn(delay: 250.ms),
                if (_hasVisualCues(result)) const Gap(16),

                // ── Confidence + Body Type ────────────────────────────────
                _ConfidenceCard(result: result).animate().fadeIn(delay: 300.ms),
                const Gap(10),

                // ── Details Grid ──────────────────────────────────────────
                const HybridNativeAdWidget(),
                const Gap(16),
                _DetailsCard(result: result).animate().fadeIn(delay: 400.ms),
                const Gap(16),

                // ── AI Analysis ───────────────────────────────────────────
                if (result.analysisPoints.isNotEmpty)
                  _AnalysisCard(result: result).animate().fadeIn(delay: 500.ms),
                const Gap(16),

                // ── Disclaimer ────────────────────────────────────────────
                const HybridNativeAdWidget(),
                const Gap(16),
                _DisclaimerCard().animate().fadeIn(delay: 600.ms),
                const Gap(24),

                // ── Scan Again ────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const FaceScanCameraScreen()),
                    ),
                    icon: const Icon(Icons.face_retouching_natural),
                    label: const Text('Dobara Scan Karo',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4AA),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms),
                const Gap(24),
              ]),
            ),
          ),
        ],
      ),
      ),
    );
  }

  bool _hasVisualCues(FaceWeightEstimationResult r) =>
      r.faceShape.isNotEmpty || r.neckThickness.isNotEmpty ||
          r.cheekFullness.isNotEmpty || r.jawline.isNotEmpty;
}

class _AgeGroupBanner extends StatelessWidget {
  final FaceWeightEstimationResult result;
  const _AgeGroupBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7B2FF7).withOpacity(0.3),
            const Color(0xFFE040FB).withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7B2FF7).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Text(result.ageGroupEmoji, style: const TextStyle(fontSize: 28)),
          const Gap(12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Detected Age Group',
                  style: TextStyle(color: Colors.white54, fontSize: 11)),
              const Gap(2),
              Text(
                result.ageGroup.isEmpty ? 'Adult' : result.ageGroup,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF7B2FF7).withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '~${result.estimatedAge} yrs',
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  final FaceWeightEstimationResult result;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⚖️', style: TextStyle(fontSize: 28)),
              const Gap(10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimated Weight',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(
                    result.formattedWeight,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Gap(4),
          Text('Range: ${result.formattedRange}',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Gap(16),
          _WeightBar(
              value: result.estimatedWeightKg,
              min:   result.minWeightKg,
              max:   result.maxWeightKg),
        ],
      ),
    );
  }
}

class _WeightBar extends StatelessWidget {
  final double value, min, max;
  const _WeightBar({required this.value, required this.min, required this.max});

  @override
  Widget build(BuildContext context) {
    final pos = ((value - min) / (max - min)).clamp(0.0, 1.0);
    return Column(
      children: [
        Stack(children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(4)),
          ),
          FractionallySizedBox(
            widthFactor: pos,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ]),
        const Gap(4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${min.toStringAsFixed(0)} kg',
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
          Text('${max.toStringAsFixed(0)} kg',
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ]),
      ],
    );
  }
}

class _BMICard extends StatelessWidget {
  final FaceWeightEstimationResult result;
  const _BMICard({required this.result});

  Color get _color {
    switch (result.bmiCategory.toLowerCase()) {
      case 'underweight': return Colors.blue;
      case 'normal':      return const Color(0xFF00D4AA);
      case 'overweight':  return Colors.orange;
      case 'obese':       return Colors.red;
      default:            return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bmi = result.estimatedBMI;
    final pos = ((bmi - 14) / (40 - 14)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF1E2940),
          borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(result.bmiIcon, style: const TextStyle(fontSize: 22)),
          const Gap(8),
          Text('BMI ${result.formattedBMI}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: _color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20)),
            child: Text(result.bmiCategory,
                style: TextStyle(
                    color: _color, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
        const Gap(14),
        // BMI gradient bar
        Stack(children: [
          Container(
            height: 12,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                Color(0xFF3B82F6),
                Color(0xFF00D4AA),
                Color(0xFFF59E0B),
                Color(0xFFEF4444),
              ]),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width * pos * 0.72 - 8,
            top: -4,
            child: Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                  color: _color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: _color.withOpacity(0.5), blurRadius: 6)]),
            ),
          ),
        ]),
        const Gap(6),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Under', style: TextStyle(color: Colors.white38, fontSize: 10)),
          Text('Normal', style: TextStyle(color: Colors.white38, fontSize: 10)),
          Text('Over', style: TextStyle(color: Colors.white38, fontSize: 10)),
          Text('Obese', style: TextStyle(color: Colors.white38, fontSize: 10)),
        ]),
      ]),
    );
  }
}

class _VisualCuesCard extends StatelessWidget {
  final FaceWeightEstimationResult result;
  const _VisualCuesCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final cues = <_CueTile>[];

    if (result.faceShape.isNotEmpty)
      cues.add(_CueTile('👤', 'Face Shape', result.faceShape));
    if (result.neckThickness.isNotEmpty)
      cues.add(_CueTile('🦒', 'Neck', result.neckThickness));
    if (result.cheekFullness.isNotEmpty)
      cues.add(_CueTile('😊', 'Cheeks', result.cheekFullness));
    if (result.jawline.isNotEmpty)
      cues.add(_CueTile('💪', 'Jawline', result.jawline));
    if (result.hasDoubleChin)
      cues.add(_CueTile('⚠️', 'Double Chin', 'Detected'));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2940),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7B2FF7).withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.analytics_outlined, color: Color(0xFF7B2FF7), size: 20),
          Gap(8),
          Text('Visual Cue Analysis',
              style: TextStyle(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
        const Gap(14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: cues.map((c) => _CueChip(cue: c)).toList(),
        ),
      ]),
    );
  }
}

class _CueTile {
  final String emoji, label, value;
  const _CueTile(this.emoji, this.label, this.value);
}

class _CueChip extends StatelessWidget {
  final _CueTile cue;
  const _CueChip({required this.cue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(cue.emoji, style: const TextStyle(fontSize: 16)),
        const Gap(6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cue.label,
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
          Text(cue.value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

class _ConfidenceCard extends StatelessWidget {
  final FaceWeightEstimationResult result;
  const _ConfidenceCard({required this.result});

  Color get _color {
    if (result.confidenceScore >= 0.75) return const Color(0xFF00D4AA);
    if (result.confidenceScore >= 0.55) return Colors.amber;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF1E2940),
          borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        CircularPercentIndicator(
          radius: 45,
          lineWidth: 8,
          percent: result.confidenceScore.clamp(0.0, 1.0),
          center: Text('${result.confidencePercent}%',
              style: TextStyle(
                  color: _color, fontSize: 15, fontWeight: FontWeight.w800)),
          progressColor: _color,
          backgroundColor: _color.withOpacity(0.15),
          circularStrokeCap: CircularStrokeCap.round,
        ),
        const Gap(20),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('AI Confidence',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const Gap(4),
            Text(result.confidenceLabel,
                style: TextStyle(
                    color: _color, fontSize: 18, fontWeight: FontWeight.w800)),
            const Gap(6),
            Text('${result.bodyType} • ${result.bodyTypeHindi}',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const Gap(4),
            Text('Height: ~${result.formattedHeight}',
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final FaceWeightEstimationResult result;
  const _DetailsCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('👤 Gender',       result.gender),
      ('🎂 Age Group',    result.ageGroup.isEmpty ? '~${result.estimatedAge} yrs' : result.ageGroup),
      ('📅 Est. Age',     '~${result.estimatedAge} years'),
      ('📏 Est. Height',  result.formattedHeight),
      ('⚖️ Weight Range', result.formattedRange),
      ('📊 BMI',          '${result.formattedBMI} (${result.bmiCategory})'),
      ('🏋️ Body Type',    '${result.bodyType} / ${result.bodyTypeHindi}'),
      ('🕐 Scan Time',
      '${result.timestamp.hour}:${result.timestamp.minute.toString().padLeft(2, '0')}'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF1E2940),
          borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Details',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        const Gap(16),
        ...rows.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(r.$1,
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
              Text(r.$2,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        )),
      ]),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final FaceWeightEstimationResult result;
  const _AnalysisCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2940),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.psychology, color: Color(0xFF00D4AA), size: 20),
          Gap(8),
          Text('AI Analysis',
              style: TextStyle(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
        const Gap(12),
        Text(result.aiAnalysis,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
        const Gap(12),
        ...result.analysisPoints.map((pt) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('•',
                style: TextStyle(color: Color(0xFF00D4AA), fontSize: 16)),
            const Gap(8),
            Expanded(
                child: Text(pt,
                    style: const TextStyle(color: Colors.white60, fontSize: 12))),
          ]),
        )),
      ]),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('⚠️', style: TextStyle(fontSize: 20)),
        Gap(10),
        Expanded(
          child: Text(
            'Ye sirf AI estimate hai — actual weight ke liye physical scale use karo. '
                'Age-adjusted BMI norms apply kiye gaye hain. '
                'Medical decisions ke liye doctor se consult karo.',
            style: TextStyle(color: Colors.amber, fontSize: 12, height: 1.5),
          ),
        ),
      ]),
    );
  }
}