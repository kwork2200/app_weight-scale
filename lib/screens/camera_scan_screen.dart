import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/face_detection_service.dart';
import '../services/weight_estimation_service.dart';
import '../services/history_service.dart';
import '../utils/functions.dart';
import 'result_screen.dart';

enum ScanState { idle, scanning, processing, done, error }

class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({super.key});
  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraReady = false;
  bool _permissionDenied = false;
  bool _initializationFailed = false;
  String? _errorMessage;
  ScanState _scanState = ScanState.idle;
  String _statusMessage = 'Object ko center mein rakho • Coin saath rakho accuracy ke liye';
  late AnimationController _pulseController;
  final _service = WeightEstimationService();
  final _faceService = FaceDetectionService();
  bool _leaving = false;

  Future<void> _handleBack() async {
    if (_leaving) return;
    _leaving = true;
    await showInterstitialThenPop(context);
    if (mounted) _leaving = false;
  }

  // Timeout durations
  static const Duration _cameraInitTimeout = Duration(seconds: 10);
  static const Duration _serviceInitTimeout = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _initializeEverything();
  }


  Future<void> _initializeEverything() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }

    try {
      // Initialize service with timeout
      await _service.initialize().timeout(
        _serviceInitTimeout,
        onTimeout: () {
          print('⚠️ Service initialization timed out');
        },
      );
      
      // Initialize camera with timeout
      await _initCamera();
    } catch (e) {
      print('INIT ERROR: $e');
      if (mounted) {
        setState(() {
          _initializationFailed = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras().timeout(
        _cameraInitTimeout,
        onTimeout: () {
          print('⚠️ Camera discovery timed out');
          return [];
        },
      );
      
      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _initializationFailed = true;
            _errorMessage = 'No camera available';
          });
        }
        return;
      }

      await _controller?.dispose();
      _controller = CameraController(
        _cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize().timeout(
        _cameraInitTimeout,
        onTimeout: () {
          print('⚠️ Camera initialization timed out');
        },
      );

      if (!mounted) return;
      setState(() {
        _isCameraReady = true;
      });
    } catch (e) {
      print("CAMERA INIT ERROR: $e");
      if (mounted) {
        setState(() {
          _initializationFailed = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _pulseController.dispose();
    _faceService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final CameraController? cameraController = _controller;

    if (cameraController == null ||
        !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      await cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      await _initCamera();
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (_scanState != ScanState.idle) return;
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _scanState = ScanState.scanning;
      _statusMessage = '📸 Photo le raha hai...';
    });

    try {
      final XFile photo = await _controller!.takePicture();

      setState(() {
        _scanState = ScanState.processing;
        _statusMessage = '🔍 Object detect kar raha hai...';
      });

      // Skip face detection for object scanning
      debugPrint('✅ Object capture successful');

      setState(() {
        _statusMessage = '🧠 Pixel analysis + ML running...';
      });

      final result = await _service.estimateFromImage(photo.path);

      if (result != null) {
        await HistoryService.saveResult(result);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ResultScreen(result: result),
            ),
          );
        }
      } else {
        setState(() {
          _scanState = ScanState.idle;
          _statusMessage = ' Object detect nahi hua. Dobara try karo.';
        });
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _statusMessage = 'Object ko center mein rakho • Coin saath rakho accuracy ke liye';
        });
      }
    } catch (e) {
      setState(() {
        _scanState = ScanState.idle;
        _statusMessage = 'Error: ${e.toString().substring(0, 50)}';
      });
    }
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
          if (_permissionDenied)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.camera, color: Colors.white54, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Camera permission required',
                    style: TextStyle(color: Colors.white70),
                  ),
                  TextButton(
                    onPressed: openAppSettings,  // from permission_handler
                    child: const Text('Open Settings',
                        style: TextStyle(color: Color(0xFF00D4AA))),
                  ),
                ],
              ),
            )
          else if (_initializationFailed)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Initialization Failed',
                    style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _initializationFailed = false;
                        _errorMessage = null;
                      });
                      _initializeEverything();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4AA),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else if (_isCameraReady && _controller != null)
            CameraPreview(_controller!)
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF00D4AA)),
                  const SizedBox(height: 16),
                  const Text(
                    'Initializing camera...',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please wait...',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          _ScanOverlay(
            scanState: _scanState,
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
                    _GlassButton(
                      icon: Icons.arrow_back_ios_new,
                      onTap: _handleBack,
                    ),
                    const Spacer(),
                    _GlassButton(
                      icon: Icons.flip_camera_ios,
                      onTap: () async {
                        if (_cameras.length < 2) return;
                        setState(() => _isCameraReady = false);
                        final current = _controller!.description;
                        final next = _cameras.firstWhere(
                              (c) => c != current,
                          orElse: () => _cameras.first,
                        );
                        await _controller!.dispose();
                        _controller = CameraController(
                          next,
                          ResolutionPreset.high,
                          enableAudio: false,
                        );
                        await _controller!.initialize();
                        if (mounted) setState(() => _isCameraReady = true);
                      },
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status message
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFF00D4AA).withOpacity(0.4),
                        ),
                      ),
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Gap(24),

                    // Capture Button
                    GestureDetector(
                      onTap: _captureAndAnalyze,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) => Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _scanState == ScanState.idle
                                  ? [const Color(0xFF00D4AA), const Color(0xFF0066FF)]
                                  : [Colors.grey.shade700, Colors.grey.shade600],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00D4AA).withOpacity(
                                  _scanState == ScanState.idle
                                      ? 0.3 + _pulseController.value * 0.3
                                      : 0.1,
                                ),
                                blurRadius: 20 + _pulseController.value * 15,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: _scanState == ScanState.processing
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
                              : const Icon(
                                  Icons.document_scanner,
                                  color: Colors.white,
                                  size: 36,
                                ),
                        ),
                      ),
                    ),
                    const Gap(12),
                    Text(
                      _scanState == ScanState.idle
                          ? 'TAP TO SCAN'
                          : _scanState == ScanState.processing
                              ? 'ANALYZING...'
                              : 'CAPTURING...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
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
}

class _ScanOverlay extends StatelessWidget {
  final ScanState scanState;
  final AnimationController pulseController;

  const _ScanOverlay({required this.scanState, required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(
        scanState: scanState,
        animation: pulseController,
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final ScanState scanState;
  final Animation<double> animation;

  _OverlayPainter({required this.scanState, required this.animation})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2.2);
    final boxSize = size.width * 0.72;
    final rect = Rect.fromCenter(
      center: center,
      width: boxSize,
      height: boxSize,
    );

    // Dark overlay outside the box
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.45);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, overlayPaint);

    // Corner brackets
    final cornerPaint = Paint()
      ..color = scanState == ScanState.processing
          ? Colors.orangeAccent
          : const Color(0xFF00D4AA)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 28.0;
    final corners = [
      [rect.topLeft, Offset(rect.left + cornerLen, rect.top),
          Offset(rect.left, rect.top + cornerLen)],
      [rect.topRight, Offset(rect.right - cornerLen, rect.top),
          Offset(rect.right, rect.top + cornerLen)],
      [rect.bottomLeft, Offset(rect.left + cornerLen, rect.bottom),
          Offset(rect.left, rect.bottom - cornerLen)],
      [rect.bottomRight, Offset(rect.right - cornerLen, rect.bottom),
          Offset(rect.right, rect.bottom - cornerLen)],
    ];

    for (final corner in corners) {
      canvas.drawLine(corner[0], corner[1], cornerPaint);
      canvas.drawLine(corner[0], corner[2], cornerPaint);
    }

    // Animated scanning line
    if (scanState == ScanState.scanning || scanState == ScanState.processing) {
      final scanY = rect.top + rect.height * animation.value;
      final scanPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFF00D4AA).withOpacity(0.8),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height))
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(rect.left, scanY),
        Offset(rect.right, scanY),
        scanPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => true;
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
