import 'package:flutter/material.dart';

class WeightGauge extends StatelessWidget {
  final double value;
  final double min;
  final double max;

  const WeightGauge({
    super.key,
    required this.value,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final percent = ((value - min) / (max - min)).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_fmt(min),
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
            Text(_fmt(max),
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percent),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                Color.lerp(
                  Colors.greenAccent,
                  Colors.redAccent,
                  v,
                )!,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _fmt(value),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _fmt(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}kg' : '${v.toStringAsFixed(0)}g';
}
