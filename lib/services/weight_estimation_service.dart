import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_config.dart';
import '../models/estimation_result.dart';


class WeightEstimationService {
  static final WeightEstimationService _instance =
      WeightEstimationService._internal();
  factory WeightEstimationService() => _instance;
  WeightEstimationService._internal();

  GenerativeModel? _geminiModel;
  bool _isInitialized = false;

  /// Log helper that works in both debug and release builds
  static void _log(String message) {
    if (message.contains('❌') || message.contains('ERROR')) {
      stderr.writeln(message);
    }
  }

  Future<void> initialize({String? apiKey}) async {
    if (_isInitialized) return;
    _isInitialized = true;

    final String? key = (apiKey != null && apiKey.isNotEmpty)
        ? apiKey
        : APIConfig.effectiveGeminiKey;

    if (key == null || key.isEmpty) {
      _log('⚠️ Gemini API key not configured. Using fallback ML methods.');
      return;
    }

    final models = ['gemini-2.5-flash-lite', 'gemini-2.5-flash', 'gemini-2.5-pro',];

    for (final model in models) {
      try {
        _log('🔄 Trying Gemini model: $model');
        final testModel = GenerativeModel(model: model, apiKey: key);
        await testModel.generateContent([Content.text('hi')]);
        _geminiModel = testModel;
        return;
      } catch (e) {
        _log('⚠️ Model $model failed: $e');
      }
    }

    _log('❌ All Gemini models failed. Using fallback ML methods.');
  }


  Future<void> dispose() async {
    _geminiModel = null;
    _isInitialized = false;
  }

  Future<WeightEstimationResult?> estimateFromImage(String imagePath) async {
    await initialize();

    if (_geminiModel != null) {
      try {
        final aiResult = await _estimateWithGeminiAI(imagePath);
        if (aiResult != null) {
          return aiResult;
        }
      } catch (e) {
        print('⚠️ AI estimation failed, falling back to traditional methods: $e');
      }
    }

    return await _estimateWithTraditionalML(imagePath);
  }

  static const Duration _apiTimeout = Duration(seconds: 30);

  Future<WeightEstimationResult?> _estimateWithGeminiAI(String imagePath) async {
    if (_geminiModel == null) return null;

    final imageFile = File(imagePath);
    if (!await imageFile.exists()) return null;

    try {
      final imageBytes = await imageFile.readAsBytes();
      
      final prompt = '''
Analyze this image and provide a detailed weight estimation. Follow this exact JSON format:

{
  "object_name": "English name of the object",
  "object_name_hindi": "Hindi name of the object",
  "category": "fruit|vegetable|electronics|food|container|stationery|sports|animal|other",
  "estimated_weight_grams": 250.5,
  "min_weight_grams": 200.0,
  "max_weight_grams": 300.0,
  "confidence_score": 0.85,
  "icon": "🍎",
  "detected_labels": ["apple", "fruit", "red"],
  "analysis": "Brief explanation of how you determined the weight",
  "has_reference_object": false,
  "inferred_material": "organic|metal|plastic|wood|glass|fabric|other"
}

Guidelines:
1. Analyze the object's size, shape, color, and apparent density
2. Consider common objects for scale reference if visible
3. Provide realistic weight estimates based on typical object weights
4. Be conservative with confidence scores (0.3-0.95 range)
5. For unknown objects, estimate based on visual characteristics
6. Return ONLY valid JSON, no additional text

Analyze the image carefully and provide the most accurate weight estimation possible.''';

      // Add timeout to prevent hanging on network issues
      final response = await _geminiModel!.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', Uint8List.fromList(imageBytes)),
        ]),
      ]).timeout(
        _apiTimeout,
        onTimeout: () {
          _log('⚠️ Gemini API call timed out after ${_apiTimeout.inSeconds} seconds');
          throw Exception('API call timed out after ${_apiTimeout.inSeconds} seconds');
        },
      );

      if (response.text != null) {
        return _parseGeminiResponse(response.text!, imagePath);
      }
    } catch (e) {
      _log('❌ Gemini AI error: $e');
      rethrow;
    }

    return null;
  }

  WeightEstimationResult _parseGeminiResponse(String response, String imagePath) {
    try {
      String jsonStr = response.trim();
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      jsonStr = jsonStr.trim();

      final Map<String, dynamic> data = _parseSimpleJson(jsonStr);
      
      if (data.isEmpty) {
        return _createFallbackResult(imagePath);
      }

      final String objectName = data['object_name'] as String? ?? 'Unknown Object';
      final String objectNameHindi = data['object_name_hindi'] as String? ?? 'अज्ञात वस्तु';
      final String category = data['category'] as String? ?? 'other';
      final double estimatedWeight = (data['estimated_weight_grams'] as num?)?.toDouble() ?? 250.0;
      final double minWeight = (data['min_weight_grams'] as num?)?.toDouble() ?? (estimatedWeight * 0.8);
      final double maxWeight = (data['max_weight_grams'] as num?)?.toDouble() ?? (estimatedWeight * 1.2);
      final double confidence = (data['confidence_score'] as num?)?.toDouble() ?? 0.5;
      final String icon = data['icon'] as String? ?? '📦';
      final List<dynamic> detectedLabels = data['detected_labels'] as List<dynamic>? ?? [];
      final bool hasReferenceObject = data['has_reference_object'] as bool? ?? false;
      final String inferredMaterial = data['inferred_material'] as String? ?? 'other';

      return WeightEstimationResult(
        objectName: objectName,
        objectNameHindi: objectNameHindi,
        icon: icon,
        estimatedWeightGrams: estimatedWeight.clamp(1.0, 50000.0),
        minWeightGrams: minWeight,
        maxWeightGrams: maxWeight,
        confidenceScore: confidence.clamp(0.0, 1.0),
        category: category,
        detectedLabels: detectedLabels.map((l) => l.toString()).toList(),
        imagePath: imagePath,
        hasReferenceObject: hasReferenceObject,
        inferredMaterial: inferredMaterial,
      );
    } catch (e) {
      print('❌ Error parsing Gemini response: $e');
      return _createFallbackResult(imagePath);
    }
  }

  Map<String, dynamic> _parseSimpleJson(String jsonStr) {
    // Basic JSON parsing - extract key-value pairs
    final Map<String, dynamic> result = {};
    
    try {
      int start = jsonStr.indexOf('{');
      int end = jsonStr.lastIndexOf('}');
      
      if (start == -1 || end == -1 || start >= end) {
        return result;
      }
      
      final String jsonContent = jsonStr.substring(start, end + 1);
      
      final regex = RegExp(r'"([^"]+)"\s*:\s*"([^"]*)"');
      for (final match in regex.allMatches(jsonContent)) {
        result[match.group(1)!] = match.group(2)!;
      }
      
      final numRegex = RegExp(r'"([^"]+)"\s*:\s*(\d+\.?\d*)');
      for (final match in numRegex.allMatches(jsonContent)) {
        result[match.group(1)!] = double.tryParse(match.group(2)!) ?? 0;
      }
      
      final boolRegex = RegExp(r'"([^"]+)"\s*:\s*(true|false)');
      for (final match in boolRegex.allMatches(jsonContent)) {
        result[match.group(1)!] = match.group(2) == 'true';
      }
      
      final arrayRegex = RegExp(r'"([^"]+)"\s*:\s*\[([^\]]*)\]');
      for (final match in arrayRegex.allMatches(jsonContent)) {
        final String arrayContent = match.group(2)!;
        final List<String> items = arrayContent
            .split(',')
            .map((s) => s.trim().replaceAll('"', '').replaceAll("'", ''))
            .where((s) => s.isNotEmpty)
            .toList();
        result[match.group(1)!] = items;
      }
    } catch (e) {
      print('⚠️ JSON parsing error: $e');
    }
    
    return result;
  }

  WeightEstimationResult _createFallbackResult(String imagePath) {
    return WeightEstimationResult(
      objectName: 'Unknown Object',
      objectNameHindi: 'अज्ञात वस्तु',
      icon: '📦',
      estimatedWeightGrams: 250.0,
      minWeightGrams: 200.0,
      maxWeightGrams: 300.0,
      confidenceScore: 0.3,
      category: 'unknown',
      detectedLabels: [],
      imagePath: imagePath,
      hasReferenceObject: false,
      inferredMaterial: 'unknown',
    );
  }

  Future<WeightEstimationResult?> _estimateWithTraditionalML(String imagePath) async {

    final imageFile = File(imagePath);
    final rawBytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(rawBytes);

    if (decoded == null) {
      return _createFallbackResult(imagePath);
    }

    final pixelCount = decoded.width * decoded.height;
    if (pixelCount == 0) return _createFallbackResult(imagePath);

    // Analyze brightness and color for basic estimation
    double totalLuminance = 0;
    int darkPixels = 0;
    int greenPixels = 0;
    
    for (int y = 0; y < decoded.height; y += 4) {
      for (int x = 0; x < decoded.width; x += 4) {
        final pixel = decoded.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        
        final lum = 0.299 * r + 0.587 * g + 0.114 * b;
        totalLuminance += lum;
        if (lum < 80) darkPixels++;
        if (g > r && g > b && g > 100) greenPixels++;
      }
    }

    final sampledPixels = (decoded.width / 4).ceil() * (decoded.height / 4).ceil();
    final avgLuminance = totalLuminance / sampledPixels;
    final greenRatio = greenPixels / sampledPixels;
    final darkRatio = darkPixels / sampledPixels;

    // Basic weight estimation based on image characteristics
    double weightG = 250.0;
    String category = 'unknown';
    String icon = '📦';
    String material = 'unknown';
    
    if (greenRatio > 0.3) {
      category = 'fruit';
      icon = '🍎';
      material = 'organic';
      weightG = 150 + (avgLuminance * 2);
    } else if (darkRatio > 0.5) {
      category = 'electronics';
      icon = '📱';
      material = 'metal';
      weightG = 200 + (avgLuminance * 3);
    } else {
      weightG = 100 + (avgLuminance * 1.5);
    }

    weightG = weightG.clamp(10.0, 10000.0);

    return WeightEstimationResult(
      objectName: 'Detected Object',
      objectNameHindi: 'वस्तु',
      icon: icon,
      estimatedWeightGrams: weightG,
      minWeightGrams: weightG * 0.7,
      maxWeightGrams: weightG * 1.3,
      confidenceScore: 0.4,
      category: category,
      detectedLabels: [],
      imagePath: imagePath,
      hasReferenceObject: false,
      inferredMaterial: material,
    );
  }



  /// Check if AI mode is available
  bool get isAIAvailable => _geminiModel != null;

}