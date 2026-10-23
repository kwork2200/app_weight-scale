import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Face weight estimation service.dart';
import 'Face weight result screen.dart';
import '../utils/functions.dart';

enum FaceScanState { idle, detecting, analyzing, done, error, noFace }

class FaceScanCameraScreen extends StatefulWidget {
  const FaceScanCameraScreen({super.key});

  @override
  State<FaceScanCameraScreen> createState() => _FaceScanCameraScreenState();
}

class _FaceScanCameraScreenState extends State<FaceScanCameraScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraReady = false;
  bool _permissionDenied = false;
  FaceScanState _scanState = FaceScanState.idle;
  String _statusMessage = 'Apna chehra frame mein rakho';

  // Live face preview tracking
  List<Face> _detectedFaces = [];
  Size _imageSize = Size.zero;

  late AnimationController _pulseController;
  final _service = FaceWeightEstimationService();
  bool _leaving = false;

  Future<void> _handleBack() async {
    if (_leaving) return;
    _leaving = true;
    await showInterstitialThenPop(context);
    if (mounted) _leaving = false;
  }

  // For live face detection on stream
  bool _isProcessingFrame = false;
  final FaceDetector _liveDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.15,
    ),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _initAll();
  }

  Future<void> _initAll() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }
    await _service.initialize();
    await _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    // Prefer front camera for face scanning
    final front = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );
    _controller = CameraController(
      front,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    await _controller!.initialize();

    // Start live face preview
    _controller!.startImageStream(_processLiveFrame);

    if (mounted) setState(() => _isCameraReady = true);
  }

  Future<void> _processLiveFrame(CameraImage image) async {
    if (_isProcessingFrame || _scanState != FaceScanState.idle) return;
    _isProcessingFrame = true;

    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: Platform.isAndroid
              ? InputImageFormat.nv21
              : InputImageFormat.bgra8888,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      final faces = await _liveDetector.processImage(inputImage);

      if (mounted) {
        setState(() {
          _detectedFaces = faces;
          _imageSize = Size(image.width.toDouble(), image.height.toDouble());
          if (faces.isNotEmpty) {
            final bestFace = faces.reduce((a, b) {
              final aScore = a.boundingBox.width * a.boundingBox.height -
                  (a.headEulerAngleY ?? 0).abs() * 120;
              final bScore = b.boundingBox.width * b.boundingBox.height -
                  (b.headEulerAngleY ?? 0).abs() * 120;
              return bScore > aScore ? b : a;
            });
            final q = FaceQualityChecker.check(bestFace, image.width.toDouble(), image.height.toDouble());

            // Show specific guidance or green light
            _statusMessage = q.passed
                ? '✅ Perfect! Scan karo'
                : '⚠️ ${q.message}';
          } else {
            _statusMessage = 'Apna chehra frame mein rakho';
          }
        });
      }


    } catch (_) {}
    _isProcessingFrame = false;
  }

  Future<void> _captureAndAnalyze() async {
    if (_scanState != FaceScanState.idle) return;
    if (_controller == null || !_controller!.value.isInitialized) return;
    // ── REPLACE the empty-face check in _captureAndAnalyze() ─────────────
    if (_detectedFaces.isEmpty) {
      setState(() => _statusMessage = '❌ Pehle chehra frame mein lao');
      return;
    }

    // Quality pre-check before wasting an API call
    final bestFace = _detectedFaces.reduce((a, b) {
      final aScore = a.boundingBox.width * a.boundingBox.height -
          (a.headEulerAngleY ?? 0).abs() * 120;
      final bScore = b.boundingBox.width * b.boundingBox.height -
          (b.headEulerAngleY ?? 0).abs() * 120;
      return bScore > aScore ? b : a;
    });
    final preQ = FaceQualityChecker.check(bestFace, _imageSize.width, _imageSize.height);

    if (!preQ.passed) {
      setState(() => _statusMessage = '⚠️ ${preQ.message}');
      return;   // do NOT capture until user fixes pose
    }


    // Stop live stream before capture
    await _controller!.stopImageStream();

    setState(() {
      _scanState = FaceScanState.detecting;
      _statusMessage = '📸 Photo capture ho rahi hai...';
    });

    try {
      final XFile photo = await _controller!.takePicture();

      setState(() {
        _scanState = FaceScanState.analyzing;
        _statusMessage = '🧠 Weight estimate kar raha hai...';
      });

      final result = await _service.estimateFromFace(photo.path);

      if (result != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => FaceWeightResultScreen(result: result),
            ),
          );
        }
      } else {
        setState(() {
          _scanState = FaceScanState.noFace;
          _statusMessage = '❌ Face detect nahi hua. Dobara try karo.';
        });
        await Future.delayed(const Duration(seconds: 2));
        _restartStream();
      }
    } catch (e) {
      setState(() {
        _scanState = FaceScanState.error;
        _statusMessage = 'Error: ${e.toString().substring(0, 40)}';
      });
      await Future.delayed(const Duration(seconds: 2));
      _restartStream();
    }
  }

  void _restartStream() {
    if (!mounted) return;
    setState(() {
      _scanState = FaceScanState.idle;
      _statusMessage = 'Apna chehra frame mein rakho';
    });
    _controller?.startImageStream(_processLiveFrame);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.stopImageStream();
    _controller?.dispose();
    _pulseController.dispose();
    _liveDetector.close();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isCameraReady && _controller != null)
            CameraPreview(_controller!)
          else if (_permissionDenied)
            _PermissionDenied()
          else
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D4AA)),
            ),

          if (_isCameraReady && _imageSize != Size.zero && _detectedFaces.isNotEmpty)
            CustomPaint(
              painter: _FaceLivePainter(
                faces: _detectedFaces,
                imageSize: _imageSize,
                hasFace: _detectedFaces.isNotEmpty,
              ),
            ),

          _FaceGuideOverlay(
            scanState: _scanState,
            hasFace: _detectedFaces.isNotEmpty,
            pulseController: _pulseController,
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _GlassBtn(
                      icon: Icons.arrow_back_ios_new,
                      onTap: _handleBack,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF00D4AA).withOpacity(0.5),
                        ),
                      ),
                      child: const Text(
                        '👤 Face Weight Scan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _GlassBtn(
                      icon: Icons.flip_camera_ios,
                      onTap: _switchCamera,
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tips card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _detectedFaces.isNotEmpty
                              ? const Color(0xFF00D4AA).withOpacity(0.6)
                              : Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _detectedFaces.isNotEmpty
                                ? Icons.check_circle
                                : Icons.face,
                            color: _detectedFaces.isNotEmpty
                                ? const Color(0xFF00D4AA)
                                : Colors.white54,
                            size: 18,
                          ),
                          const Gap(8),
                          Flexible(
                            child: Text(
                              _statusMessage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(20),

                    // Scan button
                    GestureDetector(
                      onTap: _captureAndAnalyze,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, __) => Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _scanState == FaceScanState.idle &&
                                  _detectedFaces.isNotEmpty
                                  ? [
                                const Color(0xFF00D4AA),
                                const Color(0xFF0066FF)
                              ]
                                  : [
                                Colors.grey.shade700,
                                Colors.grey.shade600
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00D4AA).withOpacity(
                                  _detectedFaces.isNotEmpty
                                      ? 0.3 + _pulseController.value * 0.35
                                      : 0.1,
                                ),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: _scanState == FaceScanState.analyzing
                              ? const Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                          )
                              : const Icon(Icons.face_retouching_natural,
                              color: Colors.white, size: 36),
                        ),
                      ),
                    ),
                    const Gap(10),
                    Text(
                      _scanState == FaceScanState.idle
                          ? (_detectedFaces.isNotEmpty ? 'TAP TO SCAN' : 'FACE DHUNDH RAHA HAI...')
                          : _scanState == FaceScanState.analyzing
                          ? 'ANALYZING...'
                          : 'CAPTURING...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const Gap(16),
                    // Disclaimer
                    Text(
                      '⚠️ Ye sirf estimate hai — actual weight scale se check karo',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    await _controller!.stopImageStream();
    final current = _controller!.description;
    final next =
    _cameras.firstWhere((c) => c != current, orElse: () => _cameras.first);
    await _controller!.dispose();
    _controller = CameraController(next, ResolutionPreset.medium,
        enableAudio: false);
    await _controller!.initialize();
    _controller!.startImageStream(_processLiveFrame);
    if (mounted) setState(() {});
  }
}

class _FaceLivePainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final bool hasFace;

  _FaceLivePainter({
    required this.faces,
    required this.imageSize,
    required this.hasFace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width == 0 || imageSize.height == 0) return;

    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    final paint = Paint()
      ..color = const Color(0xFF00D4AA).withOpacity(0.9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (final face in faces) {
      final box = face.boundingBox;
      final rect = Rect.fromLTRB(
        box.left * scaleX,
        box.top * scaleY,
        box.right * scaleX,
        box.bottom * scaleY,
      );

      const cLen = 22.0;
      final p = paint;

      canvas.drawLine(rect.topLeft, Offset(rect.left + cLen, rect.top), p);
      canvas.drawLine(rect.topLeft, Offset(rect.left, rect.top + cLen), p);
      canvas.drawLine(rect.topRight, Offset(rect.right - cLen, rect.top), p);
      canvas.drawLine(rect.topRight, Offset(rect.right, rect.top + cLen), p);
      canvas.drawLine(
          rect.bottomLeft, Offset(rect.left + cLen, rect.bottom), p);
      canvas.drawLine(
          rect.bottomLeft, Offset(rect.left, rect.bottom - cLen), p);
      canvas.drawLine(
          rect.bottomRight, Offset(rect.right - cLen, rect.bottom), p);
      canvas.drawLine(
          rect.bottomRight, Offset(rect.right, rect.bottom - cLen), p);

      final tp = TextPainter(
        text: TextSpan(
          text: ' FACE DETECTED ',
          style: TextStyle(
            color: const Color(0xFF00D4AA),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            backgroundColor: Colors.black.withOpacity(0.6),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(rect.left, rect.top - 18));
    }
  }

  @override
  bool shouldRepaint(_FaceLivePainter old) =>
      old.faces != faces || old.hasFace != hasFace;
}

class _FaceGuideOverlay extends StatelessWidget {
  final FaceScanState scanState;
  final bool hasFace;
  final AnimationController pulseController;

  const _FaceGuideOverlay({
    required this.scanState,
    required this.hasFace,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, __) => CustomPaint(
        painter: _OvalGuidePainter(
          hasFace: hasFace,
          scanState: scanState,
          pulse: pulseController.value,
        ),
      ),
    );
  }
}

class _OvalGuidePainter extends CustomPainter {
  final bool hasFace;
  final FaceScanState scanState;
  final double pulse;

  _OvalGuidePainter({
    required this.hasFace,
    required this.scanState,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.40;
    final ow = size.width * 0.55;
    final oh = ow * 1.35;

    final ovalRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: ow,
      height: oh,
    );

    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.50);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, overlayPaint);

    // Oval border
    final color = hasFace
        ? const Color(0xFF00D4AA)
        : scanState == FaceScanState.analyzing
        ? Colors.orangeAccent
        : Colors.white54;

    final borderPaint = Paint()
      ..color = color.withOpacity(hasFace ? 0.9 : 0.5 + pulse * 0.3)
      ..strokeWidth = hasFace ? 3.0 : 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawOval(ovalRect, borderPaint);

    if (hasFace) {
      final pulsePaint = Paint()
        ..color = const Color(0xFF00D4AA).withOpacity(0.15 + pulse * 0.15)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke;
      canvas.drawOval(
        ovalRect.inflate(6 + pulse * 10),
        pulsePaint,
      );
    }

    if (!hasFace) {
      final tp = TextPainter(
        text: const TextSpan(
          text: 'Yahan chehra rakho',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: ow - 20);
      tp.paint(
        canvas,
        Offset(cx - tp.width / 2, cy + oh / 2 + 14),
      );
    }
  }

  @override
  bool shouldRepaint(_OvalGuidePainter old) =>
      old.hasFace != hasFace || old.pulse != pulse;
}

// ── Helpers ────────────────────────────────────────────────
class _GlassBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

class _PermissionDenied extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.camera_alt, color: Colors.white38, size: 64),
        const SizedBox(height: 16),
        const Text('Camera permission required',
            style: TextStyle(color: Colors.white54)),
        TextButton(
          onPressed: openAppSettings,
          child: const Text('Open Settings',
              style: TextStyle(color: Color(0xFF00D4AA))),
        ),
      ],
    ),
  );
}