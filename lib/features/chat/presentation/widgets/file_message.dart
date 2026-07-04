import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:bea_window_app/constants/text_font_style.dart';
import 'package:bea_window_app/gen/colors.gen.dart';

class FileMessage extends StatefulWidget {
  final String fileUrl;
  final String? fileName;
  final int? fileSize;

  const FileMessage({
    super.key,
    required this.fileUrl,
    this.fileName,
    this.fileSize,
  });

  @override
  State<FileMessage> createState() => _FileMessageState();
}

class _FileMessageState extends State<FileMessage> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  String _getFileSizeString(int? bytes) {
    if (bytes == null || bytes <= 0) return 'Unknown size';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  IconData _getFileIcon(String? name) {
    final ext = name?.split('.').last.toLowerCase() ?? '';
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip_rounded;
      case 'txt':
        return Icons.text_snippet_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      case 'mp4':
      case 'mov':
        return Icons.video_library_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Future<void> _handleFileAction() async {
    final name = widget.fileName ?? 'attachment';
    final tempDir = await getApplicationDocumentsDirectory();
    final localPath = '${tempDir.path}/$name';
    final localFile = File(localPath);

    if (await localFile.exists()) {
      await OpenFile.open(localPath);
    } else {
      // Start Download
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
      });

      try {
        final dio = Dio();
        await dio.download(
          widget.fileUrl,
          localPath,
          onReceiveProgress: (received, total) {
            if (total > 0) {
              setState(() {
                _downloadProgress = received / total;
              });
            }
          },
        );
        setState(() {
          _isDownloading = false;
        });
        await OpenFile.open(localPath);
      } catch (_) {
        setState(() {
          _isDownloading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to download document.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.fileName ?? 'Unnamed file';
    return GestureDetector(
      onTap: _isDownloading ? null : _handleFileAction,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        constraints: BoxConstraints(maxWidth: 240.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1.w,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryPink.withValues(alpha: 0.1),
              ),
              child: _isDownloading
                  ? Padding(
                      padding: EdgeInsets.all(10.r),
                      child: CircularProgressIndicator(
                        value: _downloadProgress,
                        strokeWidth: 2.w,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
                        backgroundColor: Colors.white10,
                      ),
                    )
                  : Icon(
                      _getFileIcon(widget.fileName),
                      size: 20.sp,
                      color: AppColors.primaryPink,
                    ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextFontStyle.textStyle14cFFFFFFDMSans600.copyWith(
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _getFileSizeString(widget.fileSize),
                    style: TextFontStyle.textStyle10c888888DMSans600.copyWith(
                      color: AppColors.c8E8E9F,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_downward_rounded,
              size: 16.sp,
              color: Colors.white30,
            ),
          ],
        ),
      ),
    );
  }
}
