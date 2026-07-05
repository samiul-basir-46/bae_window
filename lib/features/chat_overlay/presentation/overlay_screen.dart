import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:url_launcher/url_launcher.dart';

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> with SingleTickerProviderStateMixin {
  double _x = 16.0;
  double _y = 200.0;
  int _unreadCount = 0;
  String _avatarUrl = '';
  String _conversationId = '';

  late AnimationController _snapController;
  late Animation<double> _snapAnimation;
  double _snapStartX = 0.0;
  double _snapTargetX = 0.0;

  final double _bubbleSize = 64.0;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _snapController.addListener(() {
      setState(() {
        _x = _snapAnimation.value;
      });
    });

    // Listen to updates from the main app
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map) {
        setState(() {
          _unreadCount = data['unreadCount'] ?? 0;
          _avatarUrl = data['avatarUrl'] ?? '';
          _conversationId = data['conversationId'] ?? '';
        });
      }
    });

    // Snap to edge initially after frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _snapToEdge();
    });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _snapToEdge() {
    if (!mounted) return;
    final screenWidth = MediaQuery.of(context).size.width;
    _snapStartX = _x;
    if (_x + _bubbleSize / 2 < screenWidth / 2) {
      _snapTargetX = 16.0; // Left side
    } else {
      _snapTargetX = screenWidth - _bubbleSize - 16.0; // Right side
    }

    _snapAnimation = Tween<double>(
      begin: _snapStartX,
      end: _snapTargetX,
    ).animate(CurvedAnimation(
      parent: _snapController,
      curve: Curves.easeOutBack,
    ));

    _snapController.reset();
    _snapController.forward();
  }

  void _onTap() async {
    if (_conversationId.isNotEmpty) {
      final uri = Uri.parse('baewindow://chat?conversationId=$_conversationId');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      // Minimize or close overlay
      await FlutterOverlayWindow.closeOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    const safeMinY = 60.0;
    final safeMaxY = screenHeight - _bubbleSize - 80.0;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned(
            left: _x,
            top: _y,
            child: GestureDetector(
              onTap: _onTap,
              onPanUpdate: (details) {
                setState(() {
                  _x += details.delta.dx;
                  _y += details.delta.dy;
                  // Clamp y to stay within safe vertical limits
                  _y = _y.clamp(safeMinY, safeMaxY);
                });
              },
              onPanEnd: (_) => _snapToEdge(),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Outer container with glow & shadow
                  Container(
                    width: _bubbleSize,
                    height: _bubbleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: const Color(0xFFFF5C8A).withValues(alpha: 0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFFF5C8A), // brand pink
                        width: 2.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_bubbleSize / 2),
                      child: _avatarUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _avatarUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[900],
                                child: const Icon(Icons.person, color: Colors.white24),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[900],
                                child: const Icon(Icons.person, color: Colors.white24),
                              ),
                            )
                          : Container(
                              color: Colors.grey[900],
                              child: const Icon(Icons.person, color: Colors.white30),
                            ),
                    ),
                  ),
                  // Unread count badge
                  if (_unreadCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            _unreadCount > 99 ? '99+' : '$_unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
