
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;


import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../config/api_config.dart';
import 'face_weight_estimation_result.dart';

// ── PASTE THIS BLOCK after your imports, before the AgeGroup enum ─────────────

class FaceQualityResult {
  final bool passed;
  final String? message;    // shown to user when rejected
  final double confidenceBonus;
  const FaceQualityResult._({required this.passed, this.message, this.confidenceBonus = 0});
  factory FaceQualityResult.pass({double bonus = 0}) =>
      FaceQualityResult._(passed: true, confidenceBonus: bonus);
  factory FaceQualityResult.fail(String msg) =>
      FaceQualityResult._(passed: false, message: msg);
}

class FaceQualityChecker {
  static const double _minBoxPx   = 110.0;
  static const double _maxYawDeg  = 25.0;
  static const double _minEyeOpen = 0.30;

  // ← removed Size, now takes plain doubles
  static FaceQualityResult check(Face face, double imageWidth, double imageHeight) {
    final box  = face.boundingBox;
    final yaw  = (face.headEulerAngleY ?? 0).abs();
    final lEye = face.leftEyeOpenProbability  ?? 1.0;
    final rEye = face.rightEyeOpenProbability ?? 1.0;

    if (box.width < _minBoxPx || box.height < _minBoxPx)
      return FaceQualityResult.fail('Chehra zyada door hai — paas aao');
    if (yaw > _maxYawDeg)
      return FaceQualityResult.fail('Seedha dekho — ${yaw.toInt()}° turned');
    if (lEye < _minEyeOpen || rEye < _minEyeOpen)
      return FaceQualityResult.fail('Aankhen kholo aur seedha dekho');

    double bonus = 0.0;
    if (yaw < 8)         bonus += 0.06;
    if (lEye > 0.85)     bonus += 0.03;
    if (box.width > 220) bonus += 0.04;
    return FaceQualityResult.pass(bonus: bonus);
  }
}
// ─────────────────────────────────────────────────────────────────────────────
enum AgeGroup { child, teen, youngAdult, adult, middleAge, senior, elderly }

const Map<AgeGroup, Map<int, List<double>>> _anthroMean = {
  AgeGroup.child:      {0: [32.0, 142.0], 1: [30.0, 140.0]},
  AgeGroup.teen:       {0: [55.0, 166.0], 1: [48.0, 157.0]},
  AgeGroup.youngAdult: {0: [65.0, 170.0], 1: [54.0, 158.0]},
  AgeGroup.adult:      {0: [72.0, 169.0], 1: [60.0, 157.0]},
  AgeGroup.middleAge:  {0: [75.0, 168.0], 1: [63.0, 156.0]},
  AgeGroup.senior:     {0: [70.0, 166.0], 1: [58.0, 154.0]},
  AgeGroup.elderly:    {0: [64.0, 163.0], 1: [53.0, 151.0]},
};

const Map<AgeGroup, List<double>> _bmiThresholds = {
  AgeGroup.child:      [13.5, 17.0, 20.5, 24.5],
  AgeGroup.teen:       [15.5, 18.0, 22.5, 26.5],
  AgeGroup.youngAdult: [18.5, 23.0, 25.0, 30.0],
  AgeGroup.adult:      [18.5, 23.0, 27.5, 32.0],
  AgeGroup.middleAge:  [18.5, 23.5, 28.0, 32.5],
  AgeGroup.senior:     [20.0, 24.0, 28.5, 33.0],
  AgeGroup.elderly:    [21.0, 25.0, 30.0, 35.0],
};

double _faceRatioToBMI(double r) {
  if (r < 0.68) return -4.0;
  if (r < 0.74) return -2.5;
  if (r < 0.80) return -1.0;
  if (r < 0.86) return  0.0;
  if (r < 0.92) return  1.8;
  if (r < 0.98) return  3.5;
  return 5.5;
}

double _cheekBMI(double mer) {
  if (mer < 0.78) return -3.0;
  if (mer < 0.88) return -1.5;
  if (mer < 0.98) return  0.0;
  if (mer < 1.08) return  1.8;
  if (mer < 1.18) return  3.5;
  return 5.0;
}

class FaceWeightEstimationService {
  // Singleton
  static final FaceWeightEstimationService _instance =
  FaceWeightEstimationService._internal();
  factory FaceWeightEstimationService() => _instance;
  FaceWeightEstimationService._internal();

  bool   _initialized = false;
  String? _apiKey;

  // ── REPLACE FaceDetector constructor in face_detection_service.dart ───────
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,   // smile + eye-open probabilities
      enableLandmarks:      true,   // nose, eye, mouth positions
      enableContours:       true,   // jaw outline — needed for weight ratios
      enableTracking:       false,  // not needed for single-shot capture
      performanceMode:      FaceDetectorMode.accurate,  // NOT fast
      minFaceSize:          0.10,   // was 0.15 — catches slightly smaller faces
    ),
  );

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _apiKey = APIConfig.effectiveGeminiKey;
    if (_apiKey == null || _apiKey!.isEmpty) {
      print('⚠️  No Gemini API key — geometry fallback will be used');
      print('   APIConfig.effectiveGeminiKey mein key set karo');
    } else {
      print('✅ Gemini API key loaded: ${_apiKey!.substring(0, 8)}...');
    }
  }
// ── ADD THIS METHOD right after _extractMetrics() ────────────────────────
  Face _selectBestFace(List<Face> faces) {
    return faces.reduce((best, candidate) =>
    _faceScore(candidate) > _faceScore(best) ? candidate : best);
  }

  double _faceScore(Face f) {
    final area   = f.boundingBox.width * f.boundingBox.height;
    final yawPen = (f.headEulerAngleY ?? 0).abs() * 120.0;
    return area - yawPen;
  }
  // ── ADD THESE TWO HELPERS inside FaceWeightEstimationService ─────────────

  Future<String> _fixRotation(String imagePath) async {
    try {
      final bytes   = await File(imagePath).readAsBytes();
      img.Image decoded = img.decodeImage(bytes)!;
      // img package auto-reads EXIF and can bake orientation in:
      decoded = img.bakeOrientation(decoded);
      final fixed = '${imagePath}_rot.jpg';
      await File(fixed).writeAsBytes(img.encodeJpg(decoded, quality: 95));
      return fixed;
    } catch (_) {
      return imagePath; // return original if anything fails
    }
  }

  Future<String> _cropFaceRegion(
      String imagePath, Face face, img.Image decoded) async {
    final box  = face.boundingBox;
    final padX = box.width  * 0.28;
    final padY = box.height * 0.28;

    final x = (box.left   - padX).clamp(0, decoded.width.toDouble()).toInt();
    final y = (box.top    - padY).clamp(0, decoded.height.toDouble()).toInt();
    final w = (box.width  + padX * 2).clamp(1, decoded.width  - x.toDouble()).toInt();
    final h = (box.height + padY * 2).clamp(1, decoded.height - y.toDouble()).toInt();

    final cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
    final resized = img.copyResize(cropped, width: 512);
    final outPath = '${imagePath}_crop.jpg';
    await File(outPath).writeAsBytes(img.encodeJpg(resized, quality: 92));
    return outPath;
  }



  Future<FaceWeightEstimationResult?> estimateFromFace(String imagePath) async {
    await initialize();

    if (!await File(imagePath).exists()) return null;

    final correctedPath = await _fixRotation(imagePath);

    List<Face> faces;
    try {
      faces = await _detector.processImage(InputImage.fromFilePath(correctedPath));
    } catch (e) {
      print('❌ ML Kit error: $e');
      return null;
    }
    if (faces.isEmpty) { print('❌ No face'); return null; }

    final face = _selectBestFace(faces);
    print('✅ Best face: ${face.boundingBox.width.toInt()}×${face.boundingBox.height.toInt()} px  yaw=${face.headEulerAngleY?.toStringAsFixed(1)}°');

    final imgDecoded = img.decodeImage(await File(correctedPath).readAsBytes())!;
    final quality = FaceQualityChecker.check(face, imgDecoded.width.toDouble(), imgDecoded.height.toDouble());
    if (!quality.passed) {
      _lastQualityMessage = quality.message;
      print('⚠️ Quality rejected: ${quality.message}');
      return null;
    }

    // STEP 5: Crop to face region and resize to 512px for Gemini
    final croppedPath = await _cropFaceRegion(correctedPath, face, imgDecoded);

    final metrics  = _extractMetrics(face);
    final ageGroup = _guessAgeGroup(metrics);

    if (_apiKey != null && _apiKey!.isNotEmpty) {
      try {
        final result = await _callGeminiVision(croppedPath, metrics, face, ageGroup);
        if (result != null) {
          final boostedConf = (result.confidenceScore + quality.confidenceBonus).clamp(0.0, 0.92);

          // Rebuild with boosted confidence using all named params from result
          return FaceWeightEstimationResult(
            imagePath:         result.imagePath,
            estimatedWeightKg: result.estimatedWeightKg,
            minWeightKg:       result.minWeightKg,
            maxWeightKg:       result.maxWeightKg,
            confidenceScore:   boostedConf,
            bodyType:          result.bodyType,
            bodyTypeHindi:     result.bodyTypeHindi,
            estimatedHeightCm: result.estimatedHeightCm,
            estimatedBMI:      result.estimatedBMI,
            bmiCategory:       result.bmiCategory,
            gender:            result.gender,
            estimatedAge:      result.estimatedAge,
            ageGroup:          result.ageGroup,
            analysisPoints:    result.analysisPoints,
            aiAnalysis:        result.aiAnalysis,
            faceWidthPx:       result.faceWidthPx,
            faceHeightPx:      result.faceHeightPx,
            headToFaceRatio:   result.headToFaceRatio,
            faceShape:         result.faceShape,
            neckThickness:     result.neckThickness,
            cheekFullness:     result.cheekFullness,
            jawline:           result.jawline,
            hasDoubleChin:     result.hasDoubleChin,
          );
        }
      } catch (e) {
        print('⚠️ Gemini failed → geometry fallback: $e');
      }
    }

    return _geometryFallback(correctedPath, metrics, face, ageGroup);
  }

  String? get lastQualityMessage => _lastQualityMessage;
  String? _lastQualityMessage;

  Map<String, double> _extractMetrics(Face face) {
    final box   = face.boundingBox;
    final faceW = box.width.toDouble();
    final faceH = box.height.toDouble();

    double leX = 0, leY = 0, reX = 0, reY = 0;
    double lmX = 0, lmY = 0, rmX = 0;
    double nY  = 0;
    double laX = 0, raX = 0;

    void readLandmark(FaceLandmarkType t, Function(double, double) fn) {
      final lm = face.landmarks[t];
      if (lm != null) fn(lm.position.x.toDouble(), lm.position.y.toDouble());
    }

    readLandmark(FaceLandmarkType.leftEye,    (x, y) { leX = x; leY = y; });
    readLandmark(FaceLandmarkType.rightEye,   (x, y) { reX = x; reY = y; });
    readLandmark(FaceLandmarkType.noseBase,   (x, y) { nY  = y; });
    readLandmark(FaceLandmarkType.leftMouth,  (x, y) { lmX = x; lmY = y; });
    readLandmark(FaceLandmarkType.rightMouth, (x, y) { rmX = x; });
    readLandmark(FaceLandmarkType.leftEar,    (x, y) { laX = x; });
    readLandmark(FaceLandmarkType.rightEar,   (x, y) { raX = x; });

    final eyeDist    = (reX - leX).abs();
    final mouthWidth = (rmX - lmX).abs();
    final avgEyeY    = (leY + reY) / 2;
    final eyeToMouth = (lmY > 0 ? (lmY - avgEyeY).abs() : faceH * 0.35);
    final earWidth   = (raX - laX).abs();

    // Contour-based jaw width
    double jawW = 0;
    final jawContour = face.contours[FaceContourType.face];
    if (jawContour != null && jawContour.points.isNotEmpty) {
      double mn = double.infinity, mx = -double.infinity;
      for (final p in jawContour.points) {
        if (p.x < mn) mn = p.x.toDouble();
        if (p.x > mx) mx = p.x.toDouble();
      }
      jawW = mx - mn;
    }
    if (jawW == 0) jawW = faceW * 0.85;

    final lowerThird = lmY > 0
        ? (box.bottom - lmY).abs().toDouble()
        : faceH * 0.30;

    return {
      'faceWidth':   faceW,
      'faceHeight':  faceH,
      'faceRatio':   faceH > 0 ? faceW / faceH : 0.88,
      'eyeDist':     eyeDist,
      'mouthWidth':  mouthWidth,
      'eyeToMouth':  eyeToMouth,
      'earWidth':    earWidth,
      'jawWidth':    jawW,
      'ipdRatio':    faceW > 0 ? eyeDist / faceW : 0.50,
      'mer':         eyeDist > 0 ? mouthWidth / eyeDist : 1.0,
      'jawRatio':    faceW > 0 ? jawW / faceW : 0.85,
      'lowerRatio':  faceH > 0 ? lowerThird / faceH : 0.30,
      'etmRatio':    faceW > 0 ? eyeToMouth / faceW : 0.40,
      'smilingProb': face.smilingProbability       ?? 0.5,
      'leftEyeOpen': face.leftEyeOpenProbability   ?? 1.0,
      'rightEyeOpen':face.rightEyeOpenProbability  ?? 1.0,
      'headYaw':     face.headEulerAngleY           ?? 0.0,
      'headRoll':    face.headEulerAngleZ           ?? 0.0,
    };
  }

  AgeGroup _guessAgeGroup(Map<String, double> m) {
    final faceW  = m['faceWidth']  ?? 200;
    final ipdR   = m['ipdRatio']   ?? 0.50;
    final jawR   = m['jawRatio']   ?? 0.85;
    final lowerR = m['lowerRatio'] ?? 0.33;

    if (faceW < 240 && ipdR > 0.55) return AgeGroup.child;
    if (faceW < 300 && ipdR > 0.52) return AgeGroup.teen;
    if (jawR < 0.77 && lowerR > 0.42) return AgeGroup.elderly;
    if (jawR < 0.81 && lowerR > 0.39) return AgeGroup.senior;
    // Default — Gemini will detect exact age from image
    return AgeGroup.youngAdult;
  }

  Future<FaceWeightEstimationResult?> _callGeminiVision(
      String imagePath,
      Map<String, double> m,
      Face face,
      AgeGroup ageGroup,
      ) async {
    final imageBytes = await File(imagePath).readAsBytes();
    final b64Image   = base64Encode(imageBytes);
    final mime       = imagePath.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';

    final box     = face.boundingBox;
    final ageHint = _ageGroupLabel(ageGroup);
    final refM    = _anthroRef(ageGroup, 0);
    final refF    = _anthroRef(ageGroup, 1);

    final prompt = '''
You are a world-class body composition AI with expertise in estimating weight, age, height, and BMI from photographs. Your estimates must be INDIVIDUALIZED — do not output population averages.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ML KIT FACE GEOMETRY DATA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Face size: ${box.width.toInt()}×${box.height.toInt()} px
Face width/height ratio: ${m['faceRatio']!.toStringAsFixed(3)}  [>0.90=round/wide  <0.78=narrow/long]
Eye dist / face width:   ${m['ipdRatio']!.toStringAsFixed(3)}   [>0.52=child-like  <0.46=adult]
Mouth width / eye dist:  ${m['mer']!.toStringAsFixed(3)}        [>1.05=full cheeks <0.88=defined cheeks]
Jaw width / face width:  ${m['jawRatio']!.toStringAsFixed(3)}   [>0.92=broad jaw   <0.80=narrow jaw]
Lower face ratio:        ${m['lowerRatio']!.toStringAsFixed(3)} [>0.40=heavy chin  <0.28=lean chin]
Eye-to-mouth ratio:      ${m['etmRatio']!.toStringAsFixed(3)}   [<0.32=round face  >0.50=elongated face]
Head yaw: ${m['headYaw']!.toStringAsFixed(1)}°   Smiling: ${(m['smilingProb']! * 100).toInt()}%
Geometry age-group hint: $ageHint
South Asian reference male:   ${refM[0].toStringAsFixed(0)} kg / ${refM[1].toStringAsFixed(0)} cm
South Asian reference female: ${refF[0].toStringAsFixed(0)} kg / ${refF[1].toStringAsFixed(0)} cm

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ANALYSIS STEPS (perform all)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1 — GENDER
Analyze: brow ridge, jaw structure, cheekbones, neck, hairline, facial hair.
→ Determine: Male or Female

STEP 2 — AGE ESTIMATION
Analyze: skin texture, wrinkle depth, eye area puffiness, hair color/density, nasolabial folds, ear lobe size, jawline sharpness, temporal hair.
→ Output EXACT estimated age (e.g. 24 not "mid-20s")

STEP 3 — HEIGHT
Analyze: head-to-body ratio if body visible, neck length, shoulder width relative to head size.
South Asian male avg: 165-172 cm. Female avg: 152-160 cm.
→ Output height in cm

STEP 4 — VISUAL WEIGHT SIGNALS (assess each)
A) FACE SHAPE: Round → high fat (BMI 26-32), Oval → medium (BMI 21-26), Long/Angular → lean (BMI 17-22)
B) CHEEK FULLNESS: Puffy/full → +6-10 kg, Hollow/defined → -5-8 kg
C) JAWLINE: Soft/undefined → overweight, Sharp/defined → lean or athletic
D) DOUBLE CHIN: Yes → strong overweight (+8-15 kg above reference)
E) NECK THICKNESS: Thick → higher weight, Slim → lower weight (+/-4-6 kg)
F) TEMPORAL REGION: Hollowed → very lean; Full → higher fat
G) NASOLABIAL FOLDS: Deep prominent folds → heavier; Shallow → leaner
H) BODY VISIBLE (shoulders/torso/arms): Broad torso → heavier; Slim shoulders → lighter (+/-5-10 kg)
I) SKIN: Loose/sagging → possible weight loss; Tight → lean or young

STEP 5 — WEIGHT CALCULATION
Start with reference for detected gender + age.
Apply ALL signal corrections from Step 4 — each strong signal = ±3-8 kg.
Combine signals. DO NOT output just the reference mean.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OUTPUT — JSON ONLY, NO MARKDOWN FENCES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{
  "estimated_weight_kg": 68.5,
  "min_weight_kg": 62.0,
  "max_weight_kg": 75.0,
  "estimated_height_cm": 170.0,
  "estimated_bmi": 23.7,
  "bmi_category": "Normal",
  "body_type": "Athletic",
  "body_type_hindi": "एथलेटिक",
  "gender": "Male",
  "estimated_age": 26,
  "age_group": "Young Adult (18-29)",
  "confidence_score": 0.74,
  "face_shape": "Oval",
  "neck_thickness": "Medium",
  "cheek_fullness": "Moderate",
  "jawline": "Defined",
  "double_chin": false,
  "analysis_points": [
    "Oval face with defined jawline — lean to average build",
    "No double chin — not overweight",
    "Medium neck — average frame",
    "Moderate cheek fullness — normal body fat",
    "Estimated age 26 from smooth skin and sharp features"
  ],
  "ai_analysis": "Young adult male ~26 years. Oval face, defined jawline, no double chin — suggests normal BMI 22-24 range. Moderate cheek fullness consistent with average build at 68-70 kg for 170 cm height."
}

RULES — READ CAREFULLY:
• age_group MUST be exactly one of: "Child (6-12)", "Teen (13-17)", "Young Adult (18-29)", "Adult (30-44)", "Middle Age (45-59)", "Senior (60-74)", "Elderly (75+)"
• estimated_age: visible age from photo — NOT age-group midpoint
• estimated_weight_kg: INDIVIDUAL estimate using all signals — NOT just reference mean
• confidence_score: 0.55-0.80 face-only; up to 0.88 if torso visible
• min/max: ±10-14% of estimated_weight_kg
• body_type: Slim / Athletic / Average / Stocky / Heavy
• body_type_hindi: पतला / एथलेटिक / औसत / भारी-भरकम / मोटा
• Output ONLY the JSON object. No text before or after.
''';

    const models = ['gemini-2.5-flash', 'gemini-1.5-flash'];

    for (final model in models) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey',
        );

        final requestBody = jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inline_data': {
                    'mime_type': mime,
                    'data': b64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature':     0.15,
            'topP':            0.8,
            'maxOutputTokens': 1024,
            'responseMimeType': 'application/json',
          },
          'safetySettings': [
            {'category': 'HARM_CATEGORY_HARASSMENT',        'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_HATE_SPEECH',       'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
          ],
        });

        print('📡 Calling Gemini $model...');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: requestBody,
        ).timeout(const Duration(seconds: 45));

        if (response.statusCode != 200) {
          final snippet = response.body.length > 300
              ? response.body.substring(0, 300)
              : response.body;
          print('⚠️  Gemini $model HTTP ${response.statusCode}: $snippet');
          continue;
        }

        final decoded    = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = decoded['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          print('⚠️  Gemini $model: no candidates in response');
          continue;
        }

        final content = candidates[0]['content'] as Map?;
        final parts   = content?['parts'] as List?;
        if (parts == null || parts.isEmpty) {
          print('⚠️  Gemini $model: empty parts');
          continue;
        }

        final rawText = parts[0]['text'] as String? ?? '';
        if (rawText.isEmpty) {
          print('⚠️  Gemini $model: empty text response');
          continue;
        }

        print('🤖 Gemini [$model] responded (${rawText.length} chars)');

        final result = _parseGeminiResponse(rawText, imagePath, m, ageGroup);
        if (result != null) return result;

      } catch (e) {
        print('⚠️  Gemini $model exception: $e');
      }
    }

    print('❌ All Gemini models failed');
    return null;
  }

  // ── Parse Gemini JSON Response ─────────────────────────────────────────────
  FaceWeightEstimationResult? _parseGeminiResponse(
      String raw,
      String imagePath,
      Map<String, double> metrics,
      AgeGroup fallbackGroup,
      ) {
    try {
      // Strip markdown fences if present
      String json = raw.trim()
          .replaceAll(RegExp(r'```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'```\s*',     multiLine: true), '')
          .trim();

      final start = json.indexOf('{');
      final end   = json.lastIndexOf('}');
      if (start == -1 || end == -1 || end <= start) {
        print('❌ No valid JSON object in Gemini response');
        return null;
      }
      json = json.substring(start, end + 1);

      // ── Inline parse helpers ─────────────────────────────────────────────
      double parseDouble(String key, double fallback) {
        final match = RegExp('"$key"\\s*:\\s*([\\d.]+)').firstMatch(json);
        return match != null ? double.tryParse(match.group(1)!) ?? fallback : fallback;
      }
      String parseStr(String key, String fallback) {
        final match = RegExp('"$key"\\s*:\\s*"([^"]*)"').firstMatch(json);
        return match?.group(1) ?? fallback;
      }
      int parseInt(String key, int fallback) {
        final match = RegExp('"$key"\\s*:\\s*(\\d+)').firstMatch(json);
        return match != null ? int.tryParse(match.group(1)!) ?? fallback : fallback;
      }
      bool parseBool(String key, bool fallback) {
        final match = RegExp('"$key"\\s*:\\s*(true|false)').firstMatch(json);
        return match != null ? match.group(1) == 'true' : fallback;
      }
      List<String> parseArr(String key) {
        final match = RegExp('"$key"\\s*:\\s*\\[([^\\]]*)\\]', dotAll: true).firstMatch(json);
        if (match == null) return [];
        return match.group(1)!
            .split(',')
            .map((s) => s.trim().replaceAll('"', '').trim())
            .where((s) => s.isNotEmpty && s.length > 3)
            .toList();
      }

      // ── Parse values ─────────────────────────────────────────────────────
      final weight     = parseDouble('estimated_weight_kg', 65.0).clamp(15.0, 220.0);
      final minW       = parseDouble('min_weight_kg', weight * 0.88).clamp(15.0, 220.0);
      final maxW       = parseDouble('max_weight_kg', weight * 1.12).clamp(15.0, 220.0);
      final height     = parseDouble('estimated_height_cm', 168.0).clamp(80.0, 220.0);
      final bmi        = parseDouble('estimated_bmi', weight / math.pow(height / 100, 2));
      final conf       = parseDouble('confidence_score', 0.65).clamp(0.0, 0.88);
      final age        = parseInt('estimated_age', 24);
      final doubleC    = parseBool('double_chin', false);
      final faceShape  = parseStr('face_shape', '');
      final neckThick  = parseStr('neck_thickness', '');
      final cheekFull  = parseStr('cheek_fullness', '');
      final jawline    = parseStr('jawline', '');

      // Resolve age group from AI response
      final aiAgeStr     = parseStr('age_group', '');
      final resolvedGrp  = _parseAgeGroupStr(aiAgeStr) ?? fallbackGroup;

      // Build analysis points
      final pts    = parseArr('analysis_points');
      final extras = <String>[];
      if (doubleC)           extras.add('Double chin detected — overweight indicator');
      if (faceShape.isNotEmpty) extras.add('Face shape: $faceShape');
      if (neckThick.isNotEmpty) extras.add('Neck: $neckThick');
      if (jawline.isNotEmpty)   extras.add('Jawline: $jawline');

      print('📊 Parsed: weight=${weight}kg age=$age group=${_ageGroupLabel(resolvedGrp)} BMI=${bmi.toStringAsFixed(1)} conf=${(conf*100).toInt()}%');

      return FaceWeightEstimationResult(
        imagePath:         imagePath,
        estimatedWeightKg: weight,
        minWeightKg:       minW,
        maxWeightKg:       maxW,
        confidenceScore:   conf,
        bodyType:          parseStr('body_type',       'Average'),
        bodyTypeHindi:     parseStr('body_type_hindi', 'औसत'),
        estimatedHeightCm: height,
        estimatedBMI:      bmi,
        bmiCategory:       _bmiCategory(bmi, resolvedGrp),
        gender:            parseStr('gender', 'Unknown'),
        estimatedAge:      age,
        ageGroup:          _ageGroupLabel(resolvedGrp),
        analysisPoints:    [...pts, ...extras],
        aiAnalysis:        parseStr('ai_analysis', 'Gemini AI visual analysis.'),
        faceWidthPx:       metrics['faceWidth']  ?? 0,
        faceHeightPx:      metrics['faceHeight'] ?? 0,
        headToFaceRatio:   metrics['faceRatio']  ?? 1.0,
        faceShape:         faceShape,
        neckThickness:     neckThick,
        cheekFullness:     cheekFull,
        jawline:           jawline,
        hasDoubleChin:     doubleC,
      );
    } catch (e, st) {
      print('❌ JSON parse error: $e\n$st');
      print('Raw response snippet: ${raw.substring(0, math.min(400, raw.length))}');
      return null;
    }
  }

  // ── Geometry Fallback (7-signal model) ───────────────────────────────────
  FaceWeightEstimationResult _geometryFallback(
      String imagePath,
      Map<String, double> m,
      Face face,
      AgeGroup ageGroup,
      ) {
    final jawR    = m['jawRatio']  ?? 0.85;
    final ipdR    = m['ipdRatio'] ?? 0.50;
    // Gender proxy: broader jaw + lower IPD ratio → male
    final genderP = (jawR > 0.87 && ipdR < 0.52) ? 0 : 1;

    final ref    = _anthroRef(ageGroup, genderP);
    final refW   = ref[0];
    final refH   = ref[1];
    final hSq    = math.pow(refH / 100, 2).toDouble();

    // Signal 1 + 2: face ratio & cheek fullness
    final faceRatio = m['faceRatio'] ?? 0.88;
    final mer       = m['mer']       ?? 1.0;
    double offset   = _faceRatioToBMI(faceRatio) + _cheekBMI(mer);

    // Signal 3: lower face ratio (chin/jowl area)
    final lowerR = m['lowerRatio'] ?? 0.33;
    if (lowerR > 0.43)       offset += 2.5;
    else if (lowerR > 0.39)  offset += 1.2;
    else if (lowerR < 0.27)  offset -= 1.8;

    // Signal 4: jaw width ratio (body frame)
    if (jawR > 0.94)         offset += 2.5;
    else if (jawR > 0.91)    offset += 1.2;
    else if (jawR < 0.77)    offset -= 2.5;
    else if (jawR < 0.81)    offset -= 1.2;

    // Signal 5: interpupillary distance ratio
    if (ipdR > 0.56)         offset += 1.5;
    else if (ipdR > 0.53)    offset += 0.5;
    else if (ipdR < 0.43)    offset -= 1.8;
    else if (ipdR < 0.46)    offset -= 0.8;

    // Signal 6: absolute face size (selfie proxy for body size)
    final faceW = m['faceWidth'] ?? 200;
    if (faceW > 380)          offset += 1.5;
    else if (faceW > 320)     offset += 0.5;
    else if (faceW < 180)     offset -= 1.0;

    // Signal 7: eye-to-mouth vertical ratio (face elongation)
    final etmR = m['etmRatio'] ?? 0.40;
    if (etmR < 0.31)          offset += 1.8;  // compressed/round = heavier
    else if (etmR > 0.50)     offset -= 1.8;  // elongated = leaner

    // Apply offset
    double weight = refW + offset * hSq;

    // Head tilt correction
    final yaw = (m['headYaw'] ?? 0.0).abs();
    if (yaw > 20)      weight *= 0.97;
    else if (yaw > 10) weight *= 0.99;

    weight = _clampWeight(weight, ageGroup);

    final bmi      = weight / hSq;
    final bmiCat   = _bmiCategory(bmi, ageGroup);
    final bodyType = _bodyType(bmi);

    return FaceWeightEstimationResult(
      imagePath:         imagePath,
      estimatedWeightKg: weight,
      minWeightKg:       (weight * 0.86).clamp(15.0, 220.0),
      maxWeightKg:       (weight * 1.14).clamp(15.0, 220.0),
      confidenceScore:   0.48,
      bodyType:          bodyType[0],
      bodyTypeHindi:     bodyType[1],
      estimatedHeightCm: refH,
      estimatedBMI:      bmi,
      bmiCategory:       bmiCat,
      gender:            genderP == 0 ? 'Male (estimated)' : 'Female (estimated)',
      estimatedAge:      _ageGroupMid(ageGroup),
      ageGroup:          _ageGroupLabel(ageGroup),
      analysisPoints: [
        'Face ratio ${faceRatio.toStringAsFixed(2)}: ${faceRatio > 0.88 ? "wider/rounder face" : faceRatio < 0.76 ? "narrow/long face" : "average face"}',
        'Cheek ratio ${mer.toStringAsFixed(2)}: ${mer > 1.05 ? "full cheeks (+fat)" : mer < 0.90 ? "defined cheeks (lean)" : "moderate cheeks"}',
        'Jaw ratio ${jawR.toStringAsFixed(2)}: ${jawR > 0.91 ? "broad jaw (heavier frame)" : jawR < 0.80 ? "narrow jaw (leaner)" : "medium frame"}',
        'Lower face ${lowerR.toStringAsFixed(2)}: ${lowerR > 0.40 ? "fuller chin area" : "defined chin (lean)"}',
        'BMI offset ${offset > 0 ? "+" : ""}${offset.toStringAsFixed(1)} → BMI ${bmi.toStringAsFixed(1)} (${bmiCat})',
        '⚠️ Gemini API key add karo APIConfig mein for full AI analysis (+30% accuracy)',
      ],
      aiAnalysis: 'Geometry-based estimation using 7 facial proportion signals. '
          'Add your Gemini API key in APIConfig.effectiveGeminiKey for '
          'Gemini 2.5 Flash visual AI analysis with much higher accuracy.',
      faceWidthPx:     m['faceWidth']  ?? 0,
      faceHeightPx:    m['faceHeight'] ?? 0,
      headToFaceRatio: faceRatio,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  List<double> _anthroRef(AgeGroup g, int gender) =>
      _anthroMean[g]?[gender] ?? [65.0, 168.0];

  String _bmiCategory(double bmi, AgeGroup g) {
    final t = _bmiThresholds[g] ?? [18.5, 23.0, 25.0, 30.0];
    if (bmi < t[0]) return 'Underweight';
    if (bmi < t[2]) return 'Normal';
    if (bmi < t[3]) return 'Overweight';
    return 'Obese';
  }

  List<String> _bodyType(double bmi) {
    if (bmi < 18.5) return ['Slim',    'पतला'];
    if (bmi < 21.5) return ['Athletic','एथलेटिक'];
    if (bmi < 25.0) return ['Average', 'औसत'];
    if (bmi < 30.0) return ['Stocky',  'भारी-भरकम'];
    return           ['Heavy',  'मोटा'];
  }

  double _clampWeight(double w, AgeGroup g) {
    switch (g) {
      case AgeGroup.child:      return w.clamp(14.0,  70.0);
      case AgeGroup.teen:       return w.clamp(28.0, 105.0);
      case AgeGroup.youngAdult: return w.clamp(38.0, 135.0);
      case AgeGroup.adult:      return w.clamp(42.0, 145.0);
      case AgeGroup.middleAge:  return w.clamp(42.0, 148.0);
      case AgeGroup.senior:     return w.clamp(38.0, 125.0);
      case AgeGroup.elderly:    return w.clamp(32.0, 105.0);
    }
  }

  String _ageGroupLabel(AgeGroup g) {
    switch (g) {
      case AgeGroup.child:      return 'Child (6-12)';
      case AgeGroup.teen:       return 'Teen (13-17)';
      case AgeGroup.youngAdult: return 'Young Adult (18-29)';
      case AgeGroup.adult:      return 'Adult (30-44)';
      case AgeGroup.middleAge:  return 'Middle Age (45-59)';
      case AgeGroup.senior:     return 'Senior (60-74)';
      case AgeGroup.elderly:    return 'Elderly (75+)';
    }
  }

  int _ageGroupMid(AgeGroup g) {
    switch (g) {
      case AgeGroup.child:      return 9;
      case AgeGroup.teen:       return 15;
      case AgeGroup.youngAdult: return 23;
      case AgeGroup.adult:      return 36;
      case AgeGroup.middleAge:  return 51;
      case AgeGroup.senior:     return 66;
      case AgeGroup.elderly:    return 78;
    }
  }

  AgeGroup? _parseAgeGroupStr(String s) {
    if (s.isEmpty) return null;
    final l = s.toLowerCase();
    if (l.contains('child'))  return AgeGroup.child;
    if (l.contains('teen'))   return AgeGroup.teen;
    if (l.contains('young'))  return AgeGroup.youngAdult;
    if (l.contains('middle')) return AgeGroup.middleAge;
    if (l.contains('elder'))  return AgeGroup.elderly;
    if (l.contains('senior')) return AgeGroup.senior;
    if (l.contains('adult'))  return AgeGroup.adult;
    return null;
  }

  void dispose() {
    _detector.close();
    _initialized = false;
  }
}
