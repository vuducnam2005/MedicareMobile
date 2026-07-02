import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';

class NotificationSheet extends StatefulWidget {
  const NotificationSheet({
    super.key,
    required this.role,
    required this.onTabChanged,
  });

  final String role;
  final ValueChanged<int> onTabChanged;

  @override
  State<NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<NotificationSheet> {
  String _activeFilter = 'All';

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _activeFilter == value;
    final primaryColor = const Color(0xFF0F52BA);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected 
                ? Colors.white 
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
        selected: isSelected,
        selectedColor: primaryColor,
        backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected 
                ? primaryColor 
                : (isDark ? const Color(0xFF334155) : Colors.grey.shade300),
            width: 1,
          ),
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _activeFilter = value;
            });
          }
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Tải danh sách thông báo khi mở bảng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationController>().fetchNotifications();
    });
  }

  String _timeAgo(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString).toLocal();
      final difference = DateTime.now().difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Vừa xong';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} phút trước';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} giờ trước';
      } else if (difference.inDays < 30) {
        return '${difference.inDays} ngày trước';
      } else {
        return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      return dateString;
    }
  }

  // Lấy icon và màu sắc phù hợp cho từng loại thông báo
  Map<String, dynamic> _getNotificationStyle(String type) {
    switch (type) {
      case 'Appointment':
        return {
          'icon': Icons.calendar_today_rounded,
          'color': const Color(0xFF3B82F6), // Blue
          'bg': const Color(0xFFEFF6FF),
        };
      case 'Billing':
        return {
          'icon': Icons.receipt_long_rounded,
          'color': const Color(0xFFF97316), // Orange
          'bg': const Color(0xFFFFF7ED),
        };
      case 'Prescription':
        return {
          'icon': Icons.medication_rounded,
          'color': const Color(0xFF10B981), // Green
          'bg': const Color(0xFFECFDF5),
        };
      case 'MedicalRecord':
        return {
          'icon': Icons.assignment_rounded,
          'color': const Color(0xFF8B5CF6), // Purple
          'bg': const Color(0xFFF5F3FF),
        };
      case 'System':
      default:
        return {
          'icon': Icons.notifications_rounded,
          'color': const Color(0xFF64748B), // Slate Grey
          'bg': const Color(0xFFF8FAFC),
        };
    }
  }

  // Thực hiện điều hướng thông minh dựa trên vai trò & loại thông báo
  void _handleSmartNavigation(NotificationModel item) {
    final type = item.type;
    final role = widget.role.toLowerCase();

    // 1. Mark as read
    context.read<NotificationController>().markAsRead(item.id);

    // 2. Chuyển đổi sang Tab tương ứng của từng vai trò
    int targetTab = -1;

    if (role == 'patient') {
      switch (type) {
        case 'Appointment':
          targetTab = 1; // Tab Lịch khám
          break;
        case 'MedicalRecord':
          targetTab = 2; // Tab Bệnh án
          break;
        case 'Prescription':
          targetTab = 3; // Tab Đơn thuốc
          break;
        case 'Billing':
          targetTab = 4; // Tab Viện phí
          break;
      }
    } else if (role == 'nurse') {
      switch (type) {
        case 'Appointment':
          targetTab = 1; // Tab Lịch hẹn
          break;
        case 'Billing':
          targetTab = 3; // Tab Thu viện phí
          break;
        case 'Prescription':
          targetTab = 4; // Tab Phát thuốc
          break;
      }
    } else if (role == 'doctor') {
      switch (type) {
        case 'Appointment':
          targetTab = 2; // Tab Lịch hẹn của bác sĩ
          break;
        case 'MedicalRecord':
          targetTab = 4; // Tab Bệnh án của bác sĩ
          break;
      }
    } else if (role == 'admin') {
      switch (type) {
        case 'Appointment':
          targetTab = 2; // Tab Lịch hẹn (Index 5 trong Menu -> được ánh xạ thành 2 ở Bottom Nav)
          break;
        case 'Prescription':
          targetTab = 3; // Tab Kho dược (Index 6 -> 3 ở Bottom Nav)
          break;
        case 'Billing':
          targetTab = 4; // Tab Hóa đơn (Index 8 -> 4 ở Bottom Nav)
          break;
      }
    }

    // 3. Đóng Bottom Sheet trước
    Navigator.pop(context);

    // 4. Trigger thay đổi tab nếu tìm thấy màn hình khớp
    if (targetTab != -1) {
      widget.onTabChanged(targetTab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Thanh kéo (Drag Indicator)
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Tiêu đề Bottom Sheet
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Thông báo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: const Text('Đọc tất cả', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        context.read<NotificationController>().markAllAsRead();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Bộ lọc thông báo (Filter Chips)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    _buildFilterChip('All', 'Tất cả'),
                    _buildFilterChip('Unread', 'Chưa đọc'),
                    _buildFilterChip('Appointment', 'Lịch khám'),
                    _buildFilterChip('Billing', 'Viện phí'),
                    _buildFilterChip('Prescription', 'Đơn thuốc'),
                    _buildFilterChip('MedicalRecord', 'Bệnh án'),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Danh sách thông báo
              Expanded(
                child: Consumer<NotificationController>(
                  builder: (context, controller, child) {
                    if (controller.isLoading && controller.notifications.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final filteredList = controller.notifications.where((item) {
                      if (_activeFilter == 'All') return true;
                      if (_activeFilter == 'Unread') return !item.isRead;
                      return item.type == _activeFilter;
                    }).toList();

                    if (filteredList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 64,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _activeFilter == 'Unread'
                                  ? 'Không có thông báo chưa đọc nào.'
                                  : 'Không tìm thấy thông báo phù hợp.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => controller.fetchNotifications(),
                      child: ListView.separated(
                        controller: scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filteredList.length,
                        separatorBuilder: (context, index) => const Divider(
                          indent: 76,
                          endIndent: 20,
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final item = filteredList[index];
                          final style = _getNotificationStyle(item.type);
                          
                          return InkWell(
                            onTap: () => _handleSmartNavigation(item),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Trạng thái Chưa đọc (Chấm tròn đỏ ở đầu)
                                  Container(
                                    margin: const EdgeInsets.only(top: 14, right: 10),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: item.isRead
                                          ? Colors.transparent
                                          : Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  
                                  // Icon đại diện loại thông báo
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: style['bg'],
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      style['icon'],
                                      color: style['color'],
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  
                                  // Nội dung thông báo
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: item.isRead
                                                ? FontWeight.w600
                                                : FontWeight.w900,
                                            color: item.isRead
                                                ? (isDark ? Colors.white70 : Colors.black87)
                                                : (isDark ? Colors.white : Colors.black),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.content,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _timeAgo(item.createdAt),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
