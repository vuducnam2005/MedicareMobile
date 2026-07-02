import 'dart:async';
import 'package:flutter/material.dart';

enum MedicareToastType { success, error, info }

class MedicareToast extends StatefulWidget {
  final String message;
  final MedicareToastType type;
  final VoidCallback onDismiss;

  const MedicareToast({
    super.key,
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  static void show(
    BuildContext context, {
    required String message,
    required MedicareToastType type,
  }) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: MedicareToast(
            message: message,
            type: type,
            onDismiss: () {
              overlayEntry.remove();
            },
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    // Tự động đóng sau 2.5 giây
    Timer(const Duration(milliseconds: 2500), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  State<MedicareToast> createState() => _MedicareToastState();
}

class _MedicareToastState extends State<MedicareToast> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color leftBarColor;
    IconData icon;
    Color iconColor;

    switch (widget.type) {
      case MedicareToastType.success:
        leftBarColor = const Color(0xFF10B981); // Emerald Green
        icon = Icons.check_circle_outline_rounded;
        iconColor = const Color(0xFF10B981);
        break;
      case MedicareToastType.error:
        leftBarColor = const Color(0xFFEF4444); // Red
        icon = Icons.error_outline_rounded;
        iconColor = const Color(0xFFEF4444);
        break;
      case MedicareToastType.info:
        leftBarColor = const Color(0xFF0F52BA); // Sapphire Blue
        icon = Icons.info_outline_rounded;
        iconColor = const Color(0xFF0F52BA);
        break;
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Vạch màu đặc trưng cạnh trái
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: leftBarColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 14),
              // Icon biểu tượng
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              // Nội dung thông báo
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Nút đóng nhanh
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                onPressed: () {
                  _animationController.reverse().then((_) {
                    widget.onDismiss();
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
