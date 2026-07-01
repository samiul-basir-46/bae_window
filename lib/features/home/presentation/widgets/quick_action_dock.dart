import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:bea_window_app/features/auth/services/cloudinary_service.dart';
import 'package:bea_window_app/features/auth/services/firebase_auth_service.dart';

class QuickActionDock extends StatelessWidget {
  const QuickActionDock({super.key});

  Future<void> _handleCamera(BuildContext context) async {
    final picker = ImagePicker();
    try {
      final XFile? image =
          await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (!context.mounted) return;
      if (image != null) {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.white)),
                SizedBox(width: 16),
                Text("Uploading snap to Bae..."),
              ],
            ),
            duration: Duration(seconds: 8),
          ),
        );

        final File file = File(image.path);
        final String? imageUrl = await CloudinaryService.uploadImage(file);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();

        if (imageUrl != null) {
          await FirebaseAuthService()
              .updateLatestSnap(snapUrl: imageUrl, snapType: 'Image');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to upload image. Please try again."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Camera error: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handlePulse(BuildContext context) async {
    HapticFeedback.heavyImpact();

    try {
      await FirebaseAuthService().sendPulse();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pulse sent to your Bae!"),
          backgroundColor: AppColors.primaryPink,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not send pulse: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showDrawingCanvas(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DrawingCanvasSheet(),
    );
  }

  void _showVoiceRecorder(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoiceRecorderSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.w),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.w,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDockItem(
                icon: Icons.camera_alt_rounded,
                label: "Snap It",
                onTap: () => _handleCamera(context),
              ),
              _buildDockItem(
                icon: Icons.brush_rounded,
                label: "Draw",
                onTap: () => _showDrawingCanvas(context),
              ),
              _buildDockItem(
                icon: Icons.vibration_rounded,
                label: "Pulse",
                onTap: () => _handlePulse(context),
              ),
              _buildDockItem(
                icon: Icons.mic_rounded,
                label: "Voice",
                onTap: () => _showVoiceRecorder(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38.w,
              height: 38.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.w,
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.95),
                size: 18.sp,
              ),
            ),
            UIHelper.verticalSpace(4.h),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: Colors.white70,
                fontSize: 9.5.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DrawingPoint {
  final Offset? offset;
  final ui.Paint paint;

  DrawingPoint({required this.offset, required this.paint});
}

class DrawingCanvasSheet extends StatefulWidget {
  const DrawingCanvasSheet({super.key});

  @override
  State<DrawingCanvasSheet> createState() => _DrawingCanvasSheetState();
}

class _DrawingCanvasSheetState extends State<DrawingCanvasSheet> {
  final List<DrawingPoint> _points = [];
  Color _selectedColor = AppColors.primaryPink;
  double _strokeWidth = 4.0;

  final List<Color> _colors = [
    AppColors.primaryPink,
    AppColors.primaryPurple,
    Colors.white,
    Colors.amber,
    Colors.tealAccent,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.navBgColor.withValues(alpha: 0.98),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.r),
          topRight: Radius.circular(32.r),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.w,
        ),
      ),
      child: Column(
        children: [
          UIHelper.verticalSpace(12.h),
          // Drag handle
          Container(
            width: 40.w,
            height: 5.h,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          UIHelper.verticalSpace(16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Draw Something",
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.undo_rounded, color: Colors.white70),
                      onPressed: () {
                        if (_points.isNotEmpty) {
                          setState(() {
                            // Remove until previous null/lift
                            if (_points.last.offset == null) {
                              _points.removeLast();
                            }
                            while (_points.isNotEmpty &&
                                _points.last.offset != null) {
                              _points.removeLast();
                            }
                          });
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_rounded,
                          color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          _points.clear();
                        });
                      },
                    ),
                    TextButton(
                      onPressed: () async {
                        if (_points.isEmpty) {
                          Navigator.pop(context);
                          return;
                        }

                        final messenger = ScaffoldMessenger.of(context);

                        // Show uploading loader
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                                SizedBox(width: 16),
                                Text("Uploading drawing to Bae..."),
                              ],
                            ),
                          ),
                        );

                        Navigator.pop(context);

                        try {
                          // Generate image from points
                          final recorder = ui.PictureRecorder();
                          final canvas = ui.Canvas(recorder);
                          final paintBg = ui.Paint()
                            ..color = const Color(0xFF1E1E24);

                          // Canvas size
                          const canvasWidth = 800.0;
                          const canvasHeight = 800.0;
                          canvas.drawRect(
                            const Rect.fromLTWH(
                              0,
                              0,
                              canvasWidth,
                              canvasHeight,
                            ),
                            paintBg,
                          );

                          // We need to scale points to match our 800x800 canvas
                          for (int i = 0; i < _points.length - 1; i++) {
                            if (_points[i].offset != null &&
                                _points[i + 1].offset != null) {
                              final p1 = _points[i].offset!;
                              final p2 = _points[i + 1].offset!;

                              // Create a new fresh paint instance to prevent engine crash
                              final paintLine = ui.Paint()
                                ..color = _points[i].paint.color
                                ..strokeCap = ui.StrokeCap.round
                                ..strokeWidth = _points[i].paint.strokeWidth;

                              canvas.drawLine(p1, p2, paintLine);
                            }
                          }

                          final picture = recorder.endRecording();
                          final img = await picture.toImage(
                            canvasWidth.toInt(),
                            canvasHeight.toInt(),
                          );
                          final pngBytes = await img.toByteData(
                            format: ui.ImageByteFormat.png,
                          );

                          if (pngBytes != null) {
                            final directory = await getTemporaryDirectory();
                            final filePath =
                                '${directory.path}/draw_${DateTime.now().millisecondsSinceEpoch}.png';
                            final file = File(filePath);
                            await file.writeAsBytes(
                              pngBytes.buffer.asUint8List(),
                            );

                            final String? imageUrl =
                                await CloudinaryService.uploadImage(file);

                            messenger.clearSnackBars();

                            if (imageUrl != null) {
                              await FirebaseAuthService().updateLatestSnap(
                                snapUrl: imageUrl,
                                snapType: 'Draw',
                              );
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text("Drawing sent to Bae!"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Failed to send drawing. Please try again.",
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          messenger.clearSnackBars();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text("Drawing error: $e"),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                      child: Text(
                        "Save",
                        style: GoogleFonts.dmSans(
                          color: AppColors.primaryPink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          UIHelper.verticalSpace(12.h),
          // Canvas Area
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 1.w,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24.r),
                child: GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      final paint = ui.Paint()
                        ..color = _selectedColor
                        ..strokeCap = ui.StrokeCap.round
                        ..strokeWidth = _strokeWidth;
                      _points.add(DrawingPoint(
                        offset: details.localPosition,
                        paint: paint,
                      ));
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      final paint = ui.Paint()
                        ..color = _selectedColor
                        ..strokeCap = ui.StrokeCap.round
                        ..strokeWidth = _strokeWidth;
                      _points.add(DrawingPoint(
                        offset: details.localPosition,
                        paint: paint,
                      ));
                    });
                  },
                  onPanEnd: (details) {
                    setState(() {
                      _points.add(DrawingPoint(
                        offset: null,
                        paint: ui.Paint(),
                      ));
                    });
                  },
                  child: CustomPaint(
                    painter: CanvasPainter(points: _points),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
          UIHelper.verticalSpace(16.h),
          // Toolbar (Colors & Brush Size)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.r),
                topRight: Radius.circular(24.r),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Brush Size",
                      style: GoogleFonts.dmSans(
                          color: Colors.white70, fontSize: 13.sp),
                    ),
                    Expanded(
                      child: Slider(
                        value: _strokeWidth,
                        min: 1.0,
                        max: 12.0,
                        activeColor: _selectedColor,
                        inactiveColor: Colors.white12,
                        onChanged: (value) {
                          setState(() {
                            _strokeWidth = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                UIHelper.verticalSpace(12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _colors.map((color) {
                    final isSelected = _selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32.w,
                        height: 32.h,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isSelected ? Colors.white : Colors.transparent,
                            width: 2.w,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ]
                              : [],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                UIHelper.verticalSpace(10.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CanvasPainter extends CustomPainter {
  final List<DrawingPoint> points;

  CanvasPainter({required this.points});

  @override
  void paint(ui.Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].offset != null && points[i + 1].offset != null) {
        canvas.drawLine(
          points[i].offset!,
          points[i + 1].offset!,
          points[i].paint,
        );
      } else if (points[i].offset != null && points[i + 1].offset == null) {
        // Draw single point/dot
        canvas.drawCircle(
          points[i].offset!,
          points[i].paint.strokeWidth / 2,
          points[i].paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) => true;
}

class VoiceRecorderSheet extends StatefulWidget {
  const VoiceRecorderSheet({super.key});

  @override
  State<VoiceRecorderSheet> createState() => _VoiceRecorderSheetState();
}

class _VoiceRecorderSheetState extends State<VoiceRecorderSheet> {
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isSendingVoice = false;
  String? _filePath;
  double _recordingProgress = 0.0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path =
            '${directory.path}/voice_temp_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _filePath = path;
          _recordingProgress = 0.0;
        });

        _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          setState(() {
            _recordingProgress += 0.02; // 0.02 per 100ms means 1.0 in 5 seconds
            if (_recordingProgress >= 1.0) {
              _recordingProgress = 1.0;
              _stopRecording();
            }
          });
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not start recording: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      if (path != null) {
        _filePath = path;
      }
    });
  }

  Future<void> _playRecording() async {
    if (_filePath != null) {
      setState(() {
        _isPlaying = true;
      });
      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      });
      await _audioPlayer.play(DeviceFileSource(_filePath!));
    }
  }

  Future<void> _stopPlayback() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
    });
  }

  Future<void> _sendVoiceMessage() async {
    final filePath = _filePath;
    if (filePath == null || _isSendingVoice) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isSendingVoice = true;
    });

    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
            SizedBox(width: 16),
            Text("Uploading voice message to Bae..."),
          ],
        ),
        duration: Duration(seconds: 15),
      ),
    );

    Navigator.pop(context);

    try {
      final voiceUrl = await CloudinaryService.uploadAudio(File(filePath));
      messenger.clearSnackBars();

      if (voiceUrl == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Failed to send voice message. Please try again."),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      await FirebaseAuthService().updateLatestSnap(
        snapUrl: voiceUrl,
        snapType: 'Voice',
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Voice message sent to Bae!"),
          backgroundColor: AppColors.primaryPink,
        ),
      );
    } catch (e) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text("Voice message error: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: AppColors.navBgColor.withValues(alpha: 0.98),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.r),
          topRight: Radius.circular(32.r),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.w,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 5.h,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          UIHelper.verticalSpace(20.h),
          Text(
            "Voice Message",
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          UIHelper.verticalSpace(8.h),
          Text(
            _isRecording
                ? "Recording... Max 5 seconds"
                : _filePath != null
                    ? "Recorded successfully"
                    : "Press record to start a 5s clip",
            style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13.sp),
          ),
          UIHelper.verticalSpace(28.h),
          if (_isRecording) ...[
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80.w,
                  height: 80.h,
                  child: CircularProgressIndicator(
                    value: _recordingProgress,
                    strokeWidth: 4.w,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryPink),
                    backgroundColor: Colors.white12,
                  ),
                ),
                GestureDetector(
                  onTap: _stopRecording,
                  child: Container(
                    width: 60.w,
                    height: 60.h,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.stop_rounded,
                        color: Colors.white, size: 28.sp),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _startRecording,
                  child: Container(
                    width: 70.w,
                    height: 70.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primaryPink,
                          AppColors.primaryPurple
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPink.withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(Icons.fiber_manual_record_rounded,
                        color: Colors.white, size: 32.sp),
                  ),
                ),
                if (_filePath != null) ...[
                  SizedBox(width: 24.w),
                  GestureDetector(
                    onTap: _isPlaying ? _stopPlayback : _playRecording,
                    child: Container(
                      width: 56.w,
                      height: 56.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1.w,
                        ),
                      ),
                      child: Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 26.sp,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          UIHelper.verticalSpace(32.h),
          if (_filePath != null && !_isRecording)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                onPressed: _isSendingVoice ? null : _sendVoiceMessage,
                child: Text(
                  "Send Voice Message",
                  style: GoogleFonts.dmSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          UIHelper.verticalSpace(12.h),
        ],
      ),
    );
  }
}
