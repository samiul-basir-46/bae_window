import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';

class LoveNoteScreen extends StatefulWidget {
  final Function(String note)? onSend;

  const LoveNoteScreen({
    super.key,
    this.onSend,
  });

  @override
  State<LoveNoteScreen> createState() => _LoveNoteScreenState();
}

class _LoveNoteScreenState extends State<LoveNoteScreen> {
  final TextEditingController _noteController = TextEditingController();

  final List<String> _quickEmojis = ["❤️", "💋", "🤗", "✨", "🌸", "🧸"];

  void _onSendNote() {
    final noteText = _noteController.text.trim();
    if (noteText.isEmpty) return;

    if (widget.onSend != null) {
      widget.onSend!(noteText);
    }
    Navigator.pop(context, noteText);
  }

  void _appendEmoji(String emoji) {
    setState(() {
      _noteController.text = _noteController.text + emoji;
      _noteController.selection = TextSelection.fromPosition(
        TextPosition(offset: _noteController.text.length),
      );
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.6),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Heavy glass blur background
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

          // Central modal card
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(28.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Hero(
                              tag: "hero-love-note-icon",
                              child: Icon(Icons.edit_note_rounded, color: Colors.tealAccent, size: 20.sp),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "Send a Love Note",
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.all(4.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close_rounded, color: Colors.white60, size: 16.sp),
                          ),
                        ),
                      ],
                    ),
                    UIHelper.verticalSpace(16.h),

                    // Soft-edged Large Text Area
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: TextField(
                        controller: _noteController,
                        cursorColor: Colors.tealAccent,
                        maxLines: 4,
                        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13.sp, height: 1.4),
                        decoration: InputDecoration(
                          hintText: "Say something sweet...",
                          hintStyle: GoogleFonts.dmSans(color: Colors.white24, fontSize: 12.sp),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    UIHelper.verticalSpace(16.h),

                    // Quick Emoji Reactions Row
                    Text(
                      "TAP EMOJI TO REPLY",
                      style: GoogleFonts.dmSans(
                        color: Colors.white38,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    UIHelper.verticalSpace(8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _quickEmojis.map((emoji) {
                        return GestureDetector(
                          onTap: () => _appendEmoji(emoji),
                          child: Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                            ),
                            child: Text(
                              emoji,
                              style: TextStyle(fontSize: 18.sp),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    UIHelper.verticalSpace(24.h),

                    // Animated Send Button with Teal Gradient Glow
                    GestureDetector(
                      onTap: _onSendNote,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.tealAccent, Color(0xFF00BFA5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.tealAccent.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: Text(
                          "Send Note",
                          style: GoogleFonts.dmSans(
                            color: Colors.black87,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
