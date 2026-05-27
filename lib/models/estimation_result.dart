class WeightEstimationResult {
  final String objectName;
  final String objectNameHindi;
  final String icon;
  final double estimatedWeightGrams;
  final double minWeightGrams;
  final double maxWeightGrams;
  final double confidenceScore;
  final String category;
  final List<String> detectedLabels;
  final DateTime timestamp;
  final String? imagePath;

  // v2: extra accuracy signals
  final bool hasReferenceObject;   // coin/card detected → real scale
  final String inferredMaterial;   // metal/wood/plant/etc.

  WeightEstimationResult({
    required this.objectName,
    required this.objectNameHindi,
    required this.icon,
    required this.estimatedWeightGrams,
    required this.minWeightGrams,
    required this.maxWeightGrams,
    required this.confidenceScore,
    required this.category,
    required this.detectedLabels,
    required this.imagePath,
    this.hasReferenceObject = false,
    this.inferredMaterial = 'unknown',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  double get estimatedWeightKg => estimatedWeightGrams / 1000;

  String get formattedWeight {
    if (estimatedWeightGrams >= 1000) {
      return '${estimatedWeightKg.toStringAsFixed(2)} kg';
    }
    return '${estimatedWeightGrams.toStringAsFixed(0)} g';
  }

  String get formattedRange {
    String fmt(double v) =>
        v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}kg' : '${v.toStringAsFixed(0)}g';
    return '${fmt(minWeightGrams)} – ${fmt(maxWeightGrams)}';
  }

  String get confidenceLabel {
    if (confidenceScore >= 0.90) return 'Very High';
    if (confidenceScore >= 0.75) return 'High';
    if (confidenceScore >= 0.60) return 'Medium';
    if (confidenceScore >= 0.40) return 'Low';
    return 'Very Low';
  }

  int get confidencePercent => (confidenceScore * 100).round();

  String get accuracyTip {
    if (hasReferenceObject) return '📏 Reference object se real scale mila';
    if (confidenceScore < 0.55) return '💡 Tip: Coin ya card saath rakho accuracy ke liye';
    return '';
  }

  Map<String, dynamic> toJson() => {
        'objectName': objectName,
        'objectNameHindi': objectNameHindi,
        'icon': icon,
        'estimatedWeightGrams': estimatedWeightGrams,
        'minWeightGrams': minWeightGrams,
        'maxWeightGrams': maxWeightGrams,
        'confidenceScore': confidenceScore,
        'category': category,
        'hasReferenceObject': hasReferenceObject,
        'inferredMaterial': inferredMaterial,
        'timestamp': timestamp.toIso8601String(),
      };
}
