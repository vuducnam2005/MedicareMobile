import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dashboard/controllers/patient_dashboard_controller.dart';
import '../models/appointment_model.dart';

class PatientAppointmentsView extends StatefulWidget {
  const PatientAppointmentsView({super.key});

  @override
  State<PatientAppointmentsView> createState() => _PatientAppointmentsViewState();
}

class _PatientAppointmentsViewState extends State<PatientAppointmentsView> {
  String _searchQuery = '';
  String _dateFilter = 'All'; // 'All', 'Today', 'Upcoming', 'Past'
  String _statusFilter = 'All'; // 'All', 'Confirmed', 'Pending', 'Completed', 'Cancelled'
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Hàm chuyển đổi/an toàn hóa định dạng ngày
  String _safeDate(dynamic val) {
    final str = val?.toString() ?? '';
    if (str.length >= 10) return str.substring(0, 10);
    return str;
  }

  @override
  Widget build(BuildContext context) {
    final dashboardController = context.watch<PatientDashboardController>();
    final primaryColor = const Color(0xFF0F52BA);
    final appointments = dashboardController.appointments;

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    // Áp dụng bộ lọc
    final filtered = appointments.where((apt) {
      // 1. Lọc theo tìm kiếm (Tên bác sĩ hoặc Chuyên khoa)
      if (_searchQuery.isNotEmpty) {
        final doctor = (apt.doctorName ?? '').toLowerCase();
        final specialty = (apt.specialtyName ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        if (!doctor.contains(query) && !specialty.contains(query)) {
          return false;
        }
      }

      // 2. Lọc theo thời gian ngày hẹn ('All', 'Today', 'Upcoming', 'Past')
      final aptDate = _safeDate(apt.appointmentDate);
      if (_dateFilter == 'Today' && aptDate != todayStr) return false;
      if (_dateFilter == 'Upcoming' && aptDate.compareTo(todayStr) <= 0) return false;
      if (_dateFilter == 'Past' && aptDate.compareTo(todayStr) >= 0) return false;

      // 3. Lọc theo trạng thái ('All', 'Confirmed', 'Pending', 'Completed', 'Cancelled')
      if (_statusFilter != 'All') {
        final status = apt.status.toLowerCase();
        if (_statusFilter == 'Confirmed' && (status != 'confirmed' && status != 'checkedin')) return false;
        if (_statusFilter == 'Pending' && status != 'pending') return false;
        if (_statusFilter == 'Completed' && status != 'completed') return false;
        if (_statusFilter == 'Cancelled' && !status.contains('cancel')) return false;
      }

      return true;
    }).toList();

    // Sắp xếp lịch hẹn: sắp xếp ngày gần nhất lên trên
    filtered.sort((a, b) {
      final dateA = _safeDate(a.appointmentDate);
      final dateB = _safeDate(b.appointmentDate);
      return dateB.compareTo(dateA);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => dashboardController.loadDashboardData(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề & Căn lề Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lịch khám của tôi',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.8,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Quản lý và theo dõi các lịch hẹn.',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng mở tab "Đặt lịch khám" từ Menu để tạo lịch mới!')),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Đặt lịch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),

              // Bộ tìm kiếm & Lọc (Search + 2 hàng Chip bộ lọc)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên bác sĩ, chuyên khoa...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: primaryColor, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Hàng bộ lọc 1: Thời gian
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'Tất cả ngày',
                            selected: _dateFilter == 'All',
                            onTap: () {
                              setState(() => _dateFilter = 'All');
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Hôm nay',
                            selected: _dateFilter == 'Today',
                            onTap: () {
                              setState(() => _dateFilter = 'Today');
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Sắp tới',
                            selected: _dateFilter == 'Upcoming',
                            onTap: () {
                              setState(() => _dateFilter = 'Upcoming');
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Lịch sử',
                            selected: _dateFilter == 'Past',
                            onTap: () {
                              setState(() => _dateFilter = 'Past');
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Hàng bộ lọc 2: Trạng thái
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'Tất cả trạng thái',
                            selected: _statusFilter == 'All',
                            onTap: () {
                              setState(() => _statusFilter = 'All');
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Chờ duyệt',
                            selected: _statusFilter == 'Pending',
                            onTap: () {
                              setState(() => _statusFilter = 'Pending');
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Đã xác nhận',
                            selected: _statusFilter == 'Confirmed',
                            onTap: () {
                              setState(() => _statusFilter = 'Confirmed');
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Đã khám xong',
                            selected: _statusFilter == 'Completed',
                            onTap: () {
                              setState(() => _statusFilter = 'Completed');
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Đã hủy',
                            selected: _statusFilter == 'Cancelled',
                            onTap: () {
                              setState(() => _statusFilter = 'Cancelled');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Danh sách lịch hẹn đã lọc
              Expanded(
                child: filtered.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: 300,
                          margin: const EdgeInsets.all(20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              const Text(
                                'Không tìm thấy lịch hẹn',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Vui lòng thay đổi từ khóa tìm kiếm hoặc các tiêu chí bộ lọc của bạn.',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final appt = filtered[index];
                          return _buildAppointmentCard(context, appt, primaryColor);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom Animated Filter Chip (Xóa bỏ checkmark xấu xí, bo tròn mượt mà, đổi màu mượt)
  Widget _buildFilterChip({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F52BA) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F52BA).withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // Thẻ thông tin lịch hẹn
  Widget _buildAppointmentCard(BuildContext context, AppointmentModel appt, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_outline, color: primaryColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appt.doctorName ?? 'Bác sĩ chưa cập nhật',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        appt.specialtyName ?? 'Chuyên khoa ngoại',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(appt.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _getStatusLabel(appt.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(appt.status),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(
                appt.appointmentDate,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(
                appt.slotTime,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          if (appt.reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.comment_outlined, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appt.reason,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
          
          // Thêm nút Hủy lịch khám nếu trạng thái là Đang chờ hoặc Đã xác nhận
          if (appt.status.toLowerCase().contains('pending') || appt.status.toLowerCase().contains('confirm')) ...[
            const Divider(height: 24, thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Hủy lịch khám', style: TextStyle(fontWeight: FontWeight.bold)),
                        content: const Text('Bạn có chắc chắn muốn hủy lịch khám này không?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Không'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              final success = await context.read<PatientDashboardController>().cancelAppointment(appt.id);
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã hủy lịch khám thành công!'), backgroundColor: Colors.green),
                                );
                              }
                            },
                            child: const Text('Có, Hủy lịch', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.cancel_outlined, size: 14, color: Colors.red),
                  label: const Text('Hủy lịch', style: TextStyle(color: Colors.red, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('confirm') || s.contains('active')) return const Color(0xFF10B981);
    if (s.contains('pending')) return const Color(0xFFF59E0B);
    if (s.contains('cancel')) return const Color(0xFFEF4444);
    if (s.contains('completed')) return const Color(0xFF3B82F6);
    return Colors.grey;
  }

  String _getStatusLabel(String status) {
    final s = status.toLowerCase();
    if (s.contains('confirm')) return 'Đã xác nhận';
    if (s.contains('pending')) return 'Đang chờ duyệt';
    if (s.contains('cancel')) return 'Đã hủy';
    if (s.contains('completed')) return 'Đã khám xong';
    return status;
  }
}
