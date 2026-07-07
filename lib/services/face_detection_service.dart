import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,   // smile, eyes open probability
      enableLandmarks: true,        // eye, nose, mouth positions
      enableTracking: true,         // track same face across frames
      performanceMode: FaceDetectorMode.accurate, // vs .fast
      minFaceSize: 0.15,            // ignore tiny faces in background
    ),
  );

  Future<List<Face>> detectFaces(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    return await _detector.processImage(inputImage);
  }

  // For live camera stream (use with startImageStream)
  Future<List<Face>> detectFromBytes({
    required Uint8List bytes,
    required InputImageMetadata metadata,
  }) async {
    final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);
    return await _detector.processImage(inputImage);
  }

  void dispose() => _detector.close();
}

class FaceOverlayPainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;

  FaceOverlayPainter({required this.faces, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    final boxPaint = Paint()
      ..color = const Color(0xFF00D4AA)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (final face in faces) {
      final rect = Rect.fromLTRB(
        face.boundingBox.left * scaleX,
        face.boundingBox.top * scaleY,
        face.boundingBox.right * scaleX,
        face.boundingBox.bottom * scaleY,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), boxPaint);

      // Show smile probability
      if (face.smilingProbability != null) {
        final tp = TextPainter(
          text: TextSpan(
            text: 'Smile: ${(face.smilingProbability! * 100).toInt()}%',
            style: const TextStyle(color: Color(0xFF00D4AA), fontSize: 13),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(rect.left, rect.top - 18));
      }
    }
  }

  @override
  bool shouldRepaint(FaceOverlayPainter old) => old.faces != faces;
}
