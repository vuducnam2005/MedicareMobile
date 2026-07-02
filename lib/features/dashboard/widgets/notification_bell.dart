import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/notification_controller.dart';
import 'notification_sheet.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({
    super.key,
    required this.role,
    required this.onTabChanged,
    this.color = const Color(0xFF0F172A),
  });

  final String role;
  final ValueChanged<int> onTabChanged;
  final Color color;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  int _lastUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Bắt đầu polling tự động cập nhật số lượng tin nhắn chưa đọc
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationController>().startPolling();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    _shakeController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationController>(
      builder: (context, controller, child) {
        if (controller.unreadCount > _lastUnreadCount) {
          _lastUnreadCount = controller.unreadCount;
          _triggerShake();
        } else {
          _lastUnreadCount = controller.unreadCount;
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                double offset = 0.0;
                final val = _shakeController.value;
                if (val > 0.0 && val <= 0.2) {
                  offset = -4.0;
                } else if (val > 0.2 && val <= 0.4) {
                  offset = 4.0;
                } else if (val > 0.4 && val <= 0.6) {
                  offset = -3.0;
                } else if (val > 0.6 && val <= 0.8) {
                  offset = 3.0;
                } else if (val > 0.8 && val < 1.0) {
                  offset = -1.0;
                }
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: IconButton(
                    icon: Icon(
                      controller.unreadCount > 0
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_outlined,
                      color: widget.color,
                      size: 24,
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => NotificationSheet(
                          role: widget.role,
                          onTabChanged: widget.onTabChanged,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            if (controller.unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        '${controller.unreadCount > 99 ? '99+' : controller.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
