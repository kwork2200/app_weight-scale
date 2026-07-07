// ═══════════════════════════════════════════════════════════════════════════
//  FaceWeightEstimationResult  v2.0
//  Added: ageGroup, faceShape, neckThickness, cheekFullness, jawline, doubleChín
// ═══════════════════════════════════════════════════════════════════════════

class FaceWeightEstimationResult {
  final String imagePath;
  final double estimatedWeightKg;
  final double minWeightKg;
  final double maxWeightKg;
  final double confidenceScore;
  final String bodyType;
  final String bodyTypeHindi;
  final double estimatedHeightCm;
  final double estimatedBMI;
  final String bmiCategory;
  final String gender;
  final int estimatedAge;
  final String ageGroup;          // NEW: "Child", "Teen", "Young Adult", etc.
  final List<String> analysisPoints;
  final String aiAnalysis;
  final DateTime timestamp;
  final double faceWidthPx;
  final double faceHeightPx;
  final double headToFaceRatio;
  // Extended visual cues (new)
  final String faceShape;         // Oval, Round, Square, Long
  final String neckThickness;     // Slim, Medium, Thick
  final String cheekFullness;     // Sunken, Moderate, Full
  final String jawline;           // Defined, Average, Soft
  final bool   hasDoubleChin;

  FaceWeightEstimationResult({
    required this.imagePath,
    required this.estimatedWeightKg,
    required this.minWeightKg,
    required this.maxWeightKg,
    required this.confidenceScore,
    required this.bodyType,
    required this.bodyTypeHindi,
    required this.estimatedHeightCm,
    required this.estimatedBMI,
    required this.bmiCategory,
    required this.gender,
    required this.estimatedAge,
    this.ageGroup          = '',
    required this.analysisPoints,
    required this.aiAnalysis,
    required this.faceWidthPx,
    required this.faceHeightPx,
    required this.headToFaceRatio,
    this.faceShape         = '',
    this.neckThickness     = '',
    this.cheekFullness     = '',
    this.jawline           = '',
    this.hasDoubleChin     = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // ── Formatted getters ──────────────────────────────────────────────────────
  String get formattedWeight  => '${estimatedWeightKg.toStringAsFixed(1)} kg';
  String get formattedRange   => '${minWeightKg.toStringAsFixed(1)} – ${maxWeightKg.toStringAsFixed(1)} kg';
  String get formattedHeight  => '${estimatedHeightCm.toStringAsFixed(0)} cm';
  String get formattedBMI     => estimatedBMI.toStringAsFixed(1);
  int    get confidencePercent => (confidenceScore * 100).round();

  String get confidenceLabel {
    if (confidenceScore >= 0.80) return 'Very High';
    if (confidenceScore >= 0.70) return 'High';
    if (confidenceScore >= 0.55) return 'Medium';
    return 'Low';
  }

  String get bmiIcon {
    switch (bmiCategory.toLowerCase()) {
      case 'underweight': return '⚠️';
      case 'normal':      return '✅';
      case 'overweight':  return '🔶';
      case 'obese':       return '🔴';
      default:            return '📊';
    }
  }

  /// Age group emoji for UI
  String get ageGroupEmoji {
    switch (ageGroup.toLowerCase()) {
      case 'child (6-12)':      return '👦';
      case 'teen (13-17)':      return '🧑';
      case 'young adult (18-29)': return '👨';
      case 'adult (30-44)':     return '🧔';
      case 'middle age (45-59)': return '👴';
      case 'senior (60-74)':    return '🧓';
      case 'elderly (75+)':     return '👴';
      default:                  return '🧑';
    }
  }

  Map<String, dynamic> toJson() => {
    'imagePath':         imagePath,
    'estimatedWeightKg': estimatedWeightKg,
    'minWeightKg':       minWeightKg,
    'maxWeightKg':       maxWeightKg,
    'confidenceScore':   confidenceScore,
    'bodyType':          bodyType,
    'bodyTypeHindi':     bodyTypeHindi,
    'estimatedHeightCm': estimatedHeightCm,
    'estimatedBMI':      estimatedBMI,
    'bmiCategory':       bmiCategory,
    'gender':            gender,
    'estimatedAge':      estimatedAge,
    'ageGroup':          ageGroup,
    'analysisPoints':    analysisPoints,
    'aiAnalysis':        aiAnalysis,
    'faceWidthPx':       faceWidthPx,
    'faceHeightPx':      faceHeightPx,
    'headToFaceRatio':   headToFaceRatio,
    'faceShape':         faceShape,
    'neckThickness':     neckThickness,
    'cheekFullness':     cheekFullness,
    'jawline':           jawline,
    'hasDoubleChin':     hasDoubleChin,
    'timestamp':         timestamp.toIso8601String(),
  };

  factory FaceWeightEstimationResult.fromJson(Map<String, dynamic> j) =>
      FaceWeightEstimationResult(
        imagePath:         j['imagePath']         as String,
        estimatedWeightKg: (j['estimatedWeightKg'] as num).toDouble(),
        minWeightKg:       (j['minWeightKg']        as num).toDouble(),
        maxWeightKg:       (j['maxWeightKg']        as num).toDouble(),
        confidenceScore:   (j['confidenceScore']    as num).toDouble(),
        bodyType:          j['bodyType']            as String,
        bodyTypeHindi:     j['bodyTypeHindi']       as String,
        estimatedHeightCm: (j['estimatedHeightCm']  as num).toDouble(),
        estimatedBMI:      (j['estimatedBMI']       as num).toDouble(),
        bmiCategory:       j['bmiCategory']         as String,
        gender:            j['gender']              as String,
        estimatedAge:      j['estimatedAge']        as int,
        ageGroup:          j['ageGroup']            as String? ?? '',
        analysisPoints:    List<String>.from(j['analysisPoints'] as List),
        aiAnalysis:        j['aiAnalysis']          as String,
        faceWidthPx:       (j['faceWidthPx']        as num).toDouble(),
        faceHeightPx:      (j['faceHeightPx']       as num).toDouble(),
        headToFaceRatio:   (j['headToFaceRatio']    as num).toDouble(),
        faceShape:         j['faceShape']           as String? ?? '',
        neckThickness:     j['neckThickness']       as String? ?? '',
        cheekFullness:     j['cheekFullness']       as String? ?? '',
        jawline:           j['jawline']             as String? ?? '',
        hasDoubleChin:     j['hasDoubleChin']       as bool? ?? false,
        timestamp: DateTime.parse(j['timestamp']   as String),
      );
}