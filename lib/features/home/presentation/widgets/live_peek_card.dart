import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'quick_action_dock.dart';

class LivePeekCard extends StatefulWidget {
  final String imageUrl;
  final String drawingUrl;
  final String voiceUrl;
  final String partnerName;
  final String? snapType;
  final VoidCallback onTap;

  const LivePeekCard({
    super.key,
    required this.imageUrl,
    required this.drawingUrl,
    required this.voiceUrl,
    required this.partnerName,
    this.snapType,
    required this.onTap,
  });

  @override
  State<LivePeekCard> createState() => _LivePeekCardState();
}

class _LivePeekCardState extends State<LivePeekCard> {
  late final PageController _pageController;
  late int _currentPage;
  final AudioPlayer _voicePlayer = AudioPlayer();
  bool _isVoicePlaying = false;

  String get _partnerName {
    final name = widget.partnerName.trim();
    return name.isEmpty ? 'Bae' : name;
  }

  int _pageForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'draw':
        return 1;
      case 'voice':
        return 2;
      default:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _currentPage = _pageForType(widget.snapType);
    _pageController = PageController(initialPage: _currentPage);
    _voicePlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isVoicePlaying = false;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant LivePeekCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final contentChanged = widget.imageUrl != oldWidget.imageUrl ||
        widget.drawingUrl != oldWidget.drawingUrl ||
        widget.voiceUrl != oldWidget.voiceUrl ||
        widget.snapType != oldWidget.snapType;

    if (widget.voiceUrl != oldWidget.voiceUrl && _isVoicePlaying) {
      _voicePlayer.stop();
      _isVoicePlaying = false;
    }

    if (contentChanged &&
        (widget.imageUrl.isNotEmpty ||
            widget.drawingUrl.isNotEmpty ||
            widget.voiceUrl.isNotEmpty)) {
      final targetPage = _pageForType(widget.snapType);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        _pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _voicePlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleVoicePlayback() async {
    if (widget.voiceUrl.isEmpty) return;

    try {
      if (_isVoicePlaying) {
        await _voicePlayer.stop();
        if (mounted) {
          setState(() {
            _isVoicePlaying = false;
          });
        }
      } else {
        await _voicePlayer.play(UrlSource(widget.voiceUrl));
        if (mounted) {
          setState(() {
            _isVoicePlaying = true;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not play voice message: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSnap = widget.imageUrl.isNotEmpty;
    final bool hasDrawing = widget.drawingUrl.isNotEmpty;
    final bool hasVoice = widget.voiceUrl.isNotEmpty;

    return Container(
      height: 330.h,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 1. PageView for scrolling between modes
          ClipRRect(
            borderRadius: BorderRadius.circular(28.r),
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                // Slide 1: Snaps (Pictures)
                _buildSnapPage(hasSnap),

                // Slide 2: Sketches & Drawings
                _buildDrawPage(hasDrawing),

                // Slide 3: Voice Notes Player
                _buildVoicePage(hasVoice),
              ],
            ),
          ),

          // 2. Soft overlay gradient at the bottom for readability
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28.r),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. Header: Status Tag + Page Indicators
          Positioned(
            top: 16.h,
            left: 16.w,
            right: 16.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    color: Colors.black.withValues(alpha: 0.65),
                    child: Row(
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getThemeColorForPage(_currentPage),
                          ),
                        ),
                        UIHelper.horizontalSpace(6.w),
                        Text(
                          _getTitleForPage(_currentPage),
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Page Indicator Dots
                Row(
                  children: List.generate(3, (index) {
                    final isSelected = _currentPage == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      margin: EdgeInsets.only(left: 6.w),
                      width: isSelected ? 18.w : 6.w,
                      height: 6.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3.r),
                        color: isSelected
                            ? _getThemeColorForPage(index)
                            : Colors.white24,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // 4. Middle Details Overlay (Description / Indicator)
          Positioned(
            bottom: 110.h,
            left: 20.w,
            right: 20.w,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getSubLabelForPage(_currentPage),
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      UIHelper.verticalSpace(2.h),
                      Text(
                        _getMainLabelForPage(
                          _currentPage,
                          hasSnap,
                          hasDrawing,
                          hasVoice,
                        ),
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 32.w,
                    height: 32.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.swap_horizontal_circle_outlined,
                        color: Colors.white60,
                        size: 16.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Bottom: Integrated Floating Quick Action Dock
          Positioned(
            bottom: 12.h,
            left: 12.w,
            right: 12.w,
            child: const QuickActionDock(),
          ),
        ],
      ),
    );
  }

  // --- Page builder helpers ---

  Widget _buildSnapPage(bool hasSnap) {
    return Container(
      width: double.infinity,
      color: AppColors.navBgColor,
      child: hasSnap
          ? Image.network(
              widget.imageUrl,
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(
                  Icons.camera_alt_outlined,
                  "Tap Snap to capture your first photo"),
            )
          : _buildPlaceholder(Icons.camera_alt_outlined,
              "Tap Snap to capture your first photo"),
    );
  }

  Widget _buildDrawPage(bool hasDrawing) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1E1E24),
      child: hasDrawing
          ? Image.network(
              widget.drawingUrl,
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(
                  Icons.brush_outlined, "Draw and share notes on canvas"),
            )
          : _buildPlaceholder(
              Icons.brush_outlined, "Draw and share notes on canvas"),
    );
  }

  Widget _buildVoicePage(bool hasVoice) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF121420),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: hasVoice ? _toggleVoicePlayback : null,
              child: Container(
                width: 52.w,
                height: 52.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryPurple.withValues(alpha: 0.15),
                  border: Border.all(
                      color: AppColors.primaryPurple.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  _isVoicePlaying
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded,
                  color: hasVoice ? Colors.white : Colors.white38,
                  size: 28,
                ),
              ),
            ),
            UIHelper.verticalSpace(12.h),
            Text(
              hasVoice
                  ? "Voice message from $_partnerName"
                  : "No Voice Notes Yet",
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            UIHelper.verticalSpace(4.h),
            Text(
              hasVoice ? "Tap to listen" : "Tap Voice to record and send",
              style: GoogleFonts.dmSans(
                color: Colors.white30,
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            UIHelper.verticalSpace(30.h),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.15),
            size: 52.sp,
          ),
          UIHelper.verticalSpace(12.h),
          Text(
            message,
            style: GoogleFonts.dmSans(
              color: Colors.white30,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          UIHelper.verticalSpace(40.h),
        ],
      ),
    );
  }

  // --- UI details helpers ---

  Color _getThemeColorForPage(int index) {
    switch (index) {
      case 0:
        return AppColors.primaryPink;
      case 1:
        return Colors.tealAccent;
      case 2:
        return AppColors.primaryPurple;
      default:
        return Colors.white;
    }
  }

  String _getTitleForPage(int index) {
    switch (index) {
      case 0:
        return "Live Snap";
      case 1:
        return "Canvas Sketch";
      case 2:
        return "Voice Clips";
      default:
        return "Live Window";
    }
  }

  String _getSubLabelForPage(int index) {
    switch (index) {
      case 0:
        return "Latest Moment";
      case 1:
        return "Shared Drawings";
      case 2:
        return "Voice Memo";
      default:
        return "Live Window";
    }
  }

  String _getMainLabelForPage(
    int index,
    bool hasSnap,
    bool hasDrawing,
    bool hasVoice,
  ) {
    switch (index) {
      case 0:
        return hasSnap
            ? "Captured recently by $_partnerName"
            : "No Snaps Yet ✦ Send one!";
      case 1:
        return hasDrawing
            ? "Drawn recently by $_partnerName"
            : "Interactive Partner Sketches";
      case 2:
        return hasVoice
            ? "Latest voice message from $_partnerName"
            : "Listen to latest messages";
      default:
        return "";
    }
  }
}
