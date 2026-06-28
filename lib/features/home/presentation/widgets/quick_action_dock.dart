import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';

class QuickActionDock extends StatelessWidget {
  const QuickActionDock({super.key});

  Future<void> _handleCamera(BuildContext context) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (!context.mounted) return;
      if (image != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Snapped: ${image.name}"),
            backgroundColor: AppColors.primaryPink,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Camera error: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _handlePulse() {
    HapticFeedback.heavyImpact();
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
      borderRadius: BorderRadius.circular(24.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
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
                onTap: _handlePulse,
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
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46.w,
              height: 46.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1.w,
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.9),
                size: 22.sp,
              ),
            ),
            UIHelper.verticalSpace(6.h),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: Colors.white70,
                fontSize: 11.sp,
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
  final Paint paint;

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
                      icon: const Icon(Icons.undo_rounded, color: Colors.white70),
                      onPressed: () {
                        if (_points.isNotEmpty) {
                          setState(() {
                            // Remove until previous null/lift
                            if (_points.last.offset == null) {
                              _points.removeLast();
                            }
                            while (_points.isNotEmpty && _points.last.offset != null) {
                              _points.removeLast();
                            }
                          });
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          _points.clear();
                        });
                      },
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Drawing Saved!"),
                            backgroundColor: AppColors.primaryPink,
                          ),
                        );
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
                      final paint = Paint()
                        ..color = _selectedColor
                        ..strokeCap = StrokeCap.round
                        ..strokeWidth = _strokeWidth;
                      _points.add(DrawingPoint(
                        offset: details.localPosition,
                        paint: paint,
                      ));
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      final paint = Paint()
                        ..color = _selectedColor
                        ..strokeCap = StrokeCap.round
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
                        paint: Paint(),
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
                      style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13.sp),
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
                            color: isSelected ? Colors.white : Colors.transparent,
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
  void paint(Canvas canvas, Size size) {
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
        final path = '${directory.path}/voice_temp_${DateTime.now().millisecondsSinceEpoch}.m4a';

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
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
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
                    child: Icon(Icons.stop_rounded, color: Colors.white, size: 28.sp),
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
                        colors: [AppColors.primaryPink, AppColors.primaryPurple],
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
                    child: Icon(Icons.fiber_manual_record_rounded, color: Colors.white, size: 32.sp),
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
                        _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
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
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Voice Message Sent!"),
                      backgroundColor: AppColors.primaryPink,
                    ),
                  );
                },
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
