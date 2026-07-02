import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/ai_assistant_controller.dart';
import '../views/dogky_chat_view.dart';

import 'dogky_video_player.dart';

class DogkyFloatingAssistant extends StatefulWidget {
  const DogkyFloatingAssistant({super.key});

  @override
  State<DogkyFloatingAssistant> createState() => _DogkyFloatingAssistantState();
}

class _DogkyFloatingAssistantState extends State<DogkyFloatingAssistant> {
  // Vị trí mặc định ở góc dưới bên phải
  static const double defaultRight = 20.0;
  static const double defaultBottom = 30.0;

  double _right = defaultRight;
  double _bottom = defaultBottom;
  bool _isReturning = false;
  bool _isDragging = false;

  void _onPointerDown(PointerEvent event) {
    if (context.read<AiAssistantController>().isOpen) return;
    setState(() {
      _isReturning = false;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (context.read<AiAssistantController>().isOpen) return;
    setState(() {
      _isDragging = true;
      _right -= details.delta.dx;
      _bottom -= details.delta.dy;

      // Giới hạn vùng kéo thả trong màn hình
      final size = MediaQuery.of(context).size;
      const double elementSize = 88.0;
      final maxRight = size.width - elementSize - 10;
      final maxBottom = size.height - elementSize - kBottomNavigationBarHeight - 20;

      if (_right < 8) _right = 8;
      if (_right > maxRight) _right = maxRight;
      if (_bottom < 8) _bottom = 8;
      if (_bottom > maxBottom) _bottom = maxBottom;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
  }

  Future<void> _handleTap() async {
    final controller = context.read<AiAssistantController>();
    if (controller.isOpen) return;

    // Nếu đang ở vị trí khác vị trí mặc định, chạy hiệu ứng quay lại
    final isAtDefault = (_right - defaultRight).abs() < 1.0 && (_bottom - defaultBottom).abs() < 1.0;

    if (!isAtDefault) {
      setState(() {
        _isReturning = true;
        _right = defaultRight;
        _bottom = defaultBottom;
      });

      // Đợi hiệu ứng kết thúc rồi mới mở chat
      await Future.delayed(const Duration(milliseconds: 520));
      if (mounted) {
        setState(() {
          _isReturning = false;
        });
        controller.toggleChat(true);
        _showChatDialog();
      }
    } else {
      controller.toggleChat(true);
      _showChatDialog();
    }
  }

  void _showChatDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'DogkyChat',
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, anim1, anim2) {
        return const DogkyChatView();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AiAssistantController>();
    if (controller.isOpen) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedPositioned(
      duration: _isReturning ? const Duration(milliseconds: 520) : Duration.zero,
      curve: Curves.elasticOut,
      right: _right,
      bottom: _bottom,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bong bóng thoại gợi ý động (nằm trên đầu cún)
          if (controller.isSpeechBubbleVisible)
            AnimatedOpacity(
              opacity: controller.isSpeechBubbleVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: const BoxConstraints(maxWidth: 160),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF4A2A1D), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Text(
                      controller.activeSpeechBubbleText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // Mũi tên chỉ xuống con chó ở dưới
                    Positioned(
                      bottom: -18,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: CustomPaint(
                          size: const Size(12, 6),
                          painter: TrianglePainter(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Chú cún Dogky
          Listener(
            onPointerDown: _onPointerDown,
            child: GestureDetector(
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onTap: _handleTap,
              child: MouseRegion(
                cursor: _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
                child: const SizedBox(
                  width: 76,
                  height: 76,
                  child: DogkyVideoPlayer(size: 76.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(6, 6);
    path.lineTo(12, 0);
    path.close();

    // Vẽ nền trắng bên trong
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Vẽ viền nâu
    final strokePaint = Paint()
      ..color = const Color(0xFF4A2A1D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
