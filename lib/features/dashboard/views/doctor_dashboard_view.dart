import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';
import '../controllers/doctor_dashboard_controller.dart';
import '../widgets/role_dashboard_shell.dart';
import '../widgets/weather_greeting_card.dart';
import '../widgets/notification_bell.dart';
import '../../patient/views/doctor_examine_view.dart';

class DoctorDashboardView extends StatefulWidget {
  const DoctorDashboardView({super.key});

  @override
  State<DoctorDashboardView> createState() => _DoctorDashboardViewState();
}

class _DoctorDashboardViewState extends State<DoctorDashboardView> {
  int _selectedMenuIndex = 0; // Quản lý 6 tab làm việc của bác sĩ
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _aptSearchController = TextEditingController();
  final TextEditingController _schedSearchController = TextEditingController();
  String _searchQuery = '';

  // Các bộ lọc và tìm kiếm cho Tab Lịch Hẹn (Tab 2)
  String _aptSearchQuery = '';
  String _aptTimeFilter = 'All'; // 'All', 'Morning', 'Afternoon'
  String _aptDateFilter = 'Today'; // 'Today', 'Upcoming', 'All'
  bool _aptSortAscending = true;

  // Các bộ lọc và tìm kiếm cho Tab Lịch Làm Việc (Tab 5)
  String _schedSearchQuery = '';
  String _schedDateFilter = 'All'; // 'All', 'Today', 'Week', 'Upcoming'
  String _schedStatusFilter = 'All'; // 'All', 'Available', 'Unavailable'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _aptSearchController.addListener(() {
      setState(() {
        _aptSearchQuery = _aptSearchController.text;
      });
    });
    _schedSearchController.addListener(() {
      setState(() {
        _schedSearchQuery = _schedSearchController.text;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _aptSearchController.dispose();
    _schedSearchController.dispose();
    super.dispose();
  }

  void _refreshData() {
    final user = context.read<AuthController>().currentUser;
    if (user != null) {
      final int doctorId = user.doctorId ?? 0;
      context.read<DoctorDashboardController>().loadAllDoctorData(doctorId);
      context.read<DoctorDashboardController>().loadMedicines();
    }
  }

  void _changeTab(int index) {
    setState(() {
      _selectedMenuIndex = index;
      _searchController.clear();
      _aptSearchController.clear();
      _schedSearchController.clear();
      _searchQuery = '';
      _aptSearchQuery = '';
      _schedSearchQuery = '';
      _aptTimeFilter = 'All';
      _aptDateFilter = 'Today';
      _aptSortAscending = true;
      _schedDateFilter = 'All';
      _schedStatusFilter = 'All';
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final doctorController = context.watch<DoctorDashboardController>();
    final user = authController.currentUser;
    final primaryColor = const Color(0xFF0F52BA); // Sapphire Blue cho Bác sĩ

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy thông tin người dùng.')),
      );
    }

    // Phân loại trạng thái lượt khám
    final waitingVisits = doctorController.visits
        .where((v) => v['status'] == 'CheckedIn')
        .toList();
    final examiningVisits = doctorController.visits
        .where((v) => v['status'] == 'Examining')
        .toList();
    final completedVisits = doctorController.visits
        .where((v) => v['status'] == 'Completed')
        .toList();
    final activeQueue = [...examiningVisits, ...waitingVisits];

    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return RoleDashboardShell(
      scaffoldKey: _scaffoldKey,
      title: _getAppBarTitle(),
      userName: user.fullName,
      roleLabel: 'Bác sĩ',
      roleSubtitle: user.specialtyName != null
          ? 'Chuyên khoa: ${user.specialtyName}'
          : user.email,
      primaryColor: primaryColor,
      menuItems: _doctorMenuItems,
      selectedIndex: _selectedMenuIndex,
      onMenuSelected: _changeTab,
      onRefresh: _refreshData,
      onLogout: () => context.read<AuthController>().logout(),
      isLoading: doctorController.isLoading,
      avatarIcon: Icons.medical_services_rounded,
      bottomNavigationBar: isWideScreen ? null : _buildDoctorBottomNav(primaryColor),
      appBarActions: [
        NotificationBell(
          role: 'Doctor',
          onTabChanged: _changeTab,
        ),
      ],
      // Sidebar chứa 6 tab làm việc y hệt bản Web
      body: _buildMainContent(
        user: user,
        doctorController: doctorController,
        activeQueue: activeQueue,
        waitingVisits: waitingVisits,
        examiningVisits: examiningVisits,
        completedVisits: completedVisits,
        primaryColor: primaryColor,
      ),
    );
  }

  // Lấy tiêu đề AppBar tương ứng với từng Tab
  Widget _buildDoctorBottomNav(Color primaryColor) {
    final currentIndex = switch (_selectedMenuIndex) {
      0 => 0,
      1 => 1,
      2 => 2,
      3 => 3,
      4 => 4,
      _ => 0,
    };

    return NavigationBar(
      height: 68,
      backgroundColor: Colors.white,
      indicatorColor: primaryColor.withOpacity(0.12),
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        final target = switch (index) {
          0 => 0,
          1 => 1,
          2 => 2,
          3 => 3,
          4 => 4,
          _ => 0,
        };
        _changeTab(target);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Tổng quan',
        ),
        NavigationDestination(
          icon: Icon(Icons.groups_2_outlined),
          selectedIcon: Icon(Icons.groups_2_rounded),
          label: 'Hàng đợi',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today_rounded),
          label: 'Lịch hẹn',
        ),
        NavigationDestination(
          icon: Icon(Icons.medical_information_outlined),
          selectedIcon: Icon(Icons.medical_information_rounded),
          label: 'Khám',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_edu_outlined),
          selectedIcon: Icon(Icons.history_edu_rounded),
          label: 'Bệnh án',
        ),
      ],
    );
  }

  static const List<RoleDashboardMenuItem> _doctorMenuItems = [
    RoleDashboardMenuItem(
      title: 'Bảng điều khiển',
      icon: Icons.dashboard_rounded,
      index: 0,
      section: 'Khám bệnh',
    ),
    RoleDashboardMenuItem(
      title: 'Hàng đợi khám',
      icon: Icons.people_alt_rounded,
      index: 1,
      section: 'Khám bệnh',
    ),
    RoleDashboardMenuItem(
      title: 'Lịch hẹn',
      icon: Icons.calendar_month_rounded,
      index: 2,
      section: 'Khám bệnh',
    ),
    RoleDashboardMenuItem(
      title: 'Khám & kê đơn',
      icon: Icons.healing_rounded,
      index: 3,
      section: 'Khám bệnh',
    ),
    RoleDashboardMenuItem(
      title: 'Lịch sử bệnh án',
      icon: Icons.history_edu_rounded,
      index: 4,
      section: 'Hồ sơ',
    ),
    RoleDashboardMenuItem(
      title: 'Lịch làm việc',
      icon: Icons.calendar_view_week_rounded,
      index: 5,
      section: 'Hồ sơ',
    ),
  ];

  String _getAppBarTitle() {
    switch (_selectedMenuIndex) {
      case 0:
        return 'Bảng điều khiển Bác sĩ';
      case 1:
        return 'Hàng đợi khám';
      case 2:
        return 'Lịch hẹn hôm nay';
      case 3:
        return 'Khám bệnh & Kê đơn';
      case 4:
        return 'Lịch sử bệnh án';
      case 5:
        return 'Lịch làm việc';
      default:
        return 'Medicare';
    }
  }

  // Điều hướng nội dung chính dựa trên Tab được chọn
  Widget _buildMainContent({
    required UserModel user,
    required DoctorDashboardController doctorController,
    required List<dynamic> activeQueue,
    required List<dynamic> waitingVisits,
    required List<dynamic> examiningVisits,
    required List<dynamic> completedVisits,
    required Color primaryColor,
  }) {
    if (doctorController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final int docId = user.doctorId ?? 0;

    switch (_selectedMenuIndex) {
      case 0:
        return _buildDashboardTab(
          user,
          doctorController,
          activeQueue,
          waitingVisits,
          examiningVisits,
          completedVisits,
          primaryColor,
        );
      case 1:
        return _buildQueueTab(activeQueue, docId, primaryColor);
      case 2:
        return _buildAppointmentsTab(
          doctorController.appointments,
          primaryColor,
        );
      case 3:
        return _buildExamineTab(activeQueue, docId, primaryColor);
      case 4:
        return _buildHistoryTab(user, doctorController, primaryColor);
      case 5:
        return _buildScheduleTab(doctorController.schedules, primaryColor);
      default:
        return const Center(child: Text('Đang phát triển'));
    }
  }

  // --- 6 TAB CHI TIẾT ---

  // TAB 0: BẢNG ĐIỀU KHIỂN (DASHBOARD)
  Widget _buildDashboardTab(
    UserModel user,
    DoctorDashboardController doctorController,
    List<dynamic> activeQueue,
    List<dynamic> waitingVisits,
    List<dynamic> examiningVisits,
    List<dynamic> completedVisits,
    Color primaryColor,
  ) {
    // Tính toán số đơn thuốc đã kê
    final prescriptionsCount = doctorController.medicalRecords.where((rec) {
      final recDocName = rec['doctorName'] ?? rec['doctorNameSnapshot'] ?? '';
      final recDocId = rec['doctorId'];
      final isMyDoc =
          (recDocId != null &&
              user.doctorId != null &&
              recDocId == user.doctorId) ||
          _normalizeName(recDocName) == _normalizeName(user.fullName);
      if (!isMyDoc) return false;
      final pId =
          rec['prescriptionId'] ??
          (rec['prescriptions'] is List &&
                  (rec['prescriptions'] as List).isNotEmpty
              ? 1
              : null);
      return pId != null;
    }).length;

    // Danh sách lịch hẹn hôm nay
    final todayDate = DateTime.now().toIso8601String().substring(0, 10);
    final todayAppointments = doctorController.appointments.where((item) {
      final aptDate = _safeDate(item['appointmentDate']);
      return aptDate == todayDate;
    }).toList();
    final pendingAppointments = todayAppointments.where((apt) {
      final status = (apt['status'] ?? '').toString().toLowerCase();
      return status.contains('pending') ||
          status.contains('confirmed') ||
          status.contains('checkedin');
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Thẻ banner chào mừng cao cấp, đầy đủ thông tin y hệt bản Web
          _buildDoctorCommandHeader(
            user: user,
            todayAppointments: todayAppointments.length,
            activeQueue: activeQueue.length,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 16),

          // 2. 5 chỉ số thống kê (bao gồm Đơn thuốc đã kê)
          _buildDoctorMetricsGrid(
            appointments: todayAppointments.length,
            waiting: waitingVisits.length,
            examining: examiningVisits.length,
            completed: completedVisits.length,
            prescriptions: prescriptionsCount,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 16),
          _buildDoctorAttentionPanel(
            activeQueue: activeQueue,
            pendingAppointments: pendingAppointments,
            prescriptionsCount: prescriptionsCount,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 24),

          // 3. Bệnh nhân tiếp theo
          const Text(
            'Bệnh nhân tiếp theo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          if (activeQueue.isNotEmpty)
            _buildNextPatientCard(
              activeQueue.first,
              user.doctorId ?? 0,
              primaryColor,
            )
          else
            _buildEmptySection('Chưa có bệnh nhân tiếp theo cho bác sĩ này.'),
          const SizedBox(height: 24),

          // 4. Quick actions / Thao tác nhanh
          const Text(
            'Quick actions / Thao tác nhanh',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _buildDoctorActionGrid(primaryColor),
          const SizedBox(height: 24),

          // 5. Hai bảng danh sách xem nhanh trực tiếp trên Dashboard giống bản Web
          _buildDashboardPanel(
            title: 'Hàng chờ khám hôm nay',
            subtitle: 'Hiển thị tối đa 5 bệnh nhân đang chờ',
            child: activeQueue.isEmpty
                ? _buildEmptySection('Hàng chờ hôm nay chưa có dữ liệu.')
                : Column(
                    children: activeQueue
                        .take(5)
                        .map(
                          (visit) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _buildPatientVisitCard(
                              visit,
                              user.doctorId ?? 0,
                              primaryColor,
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 20),
          _buildDashboardPanel(
            title: 'Lịch hẹn hôm nay',
            subtitle: 'Sắp xếp theo giờ khám tăng dần',
            child: todayAppointments.isEmpty
                ? _buildEmptySection('Không có lịch hẹn hôm nay cho bác sĩ.')
                : Column(
                    children: todayAppointments
                        .take(6)
                        .map(
                          (apt) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _buildSimpleAppointmentCard(
                              apt,
                              primaryColor,
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  // TAB 1: HÀNG ĐỢI KHÁM (QUEUE)
  Widget _buildQueueTab(List<dynamic> queue, int doctorId, Color primaryColor) {
    if (queue.isEmpty) {
      return _buildEmptySection('Hàng đợi khám hiện đang trống.');
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: queue.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final visit = queue[index];
        return _buildPatientVisitCard(visit, doctorId, primaryColor);
      },
    );
  }

  // TAB 2: LỊCH HẸN HÔM NAY / SẮP TỚI (APPOINTMENTS) - Tích hợp đầy đủ bộ lọc, tìm kiếm và sắp xếp
  Widget _buildAppointmentsTab(List<dynamic> appointments, Color primaryColor) {
    final todayDate = DateTime.now().toIso8601String().substring(0, 10);

    List<dynamic> filtered = appointments.where((apt) {
      // 1. Tìm kiếm theo tên bệnh nhân
      if (_aptSearchQuery.isNotEmpty) {
        final name = (apt['patientName'] ?? apt['patientNameSnapshot'] ?? '')
            .toString()
            .toLowerCase();
        if (!name.contains(_aptSearchQuery.toLowerCase())) return false;
      }

      // 2. Phân loại theo thời gian / ngày hẹn ('Today', 'Upcoming', 'All')
      final aptDate = _safeDate(apt['appointmentDate']);
      if (_aptDateFilter == 'Today' && aptDate != todayDate) return false;
      if (_aptDateFilter == 'Upcoming' && aptDate.compareTo(todayDate) <= 0)
        return false;

      // 3. Lọc theo ca trực / khung giờ ('All', 'Morning', 'Afternoon')
      final slotTime = apt['slotTime'] ?? '00:00';
      final hour = int.tryParse(slotTime.split(':').first) ?? 0;
      if (_aptTimeFilter == 'Morning' && hour >= 12) return false;
      if (_aptTimeFilter == 'Afternoon' && hour < 12) return false;

      return true;
    }).toList();

    // 4. Sắp xếp theo thời gian
    filtered.sort((a, b) {
      final dateA = _safeDate(a['appointmentDate']);
      final dateB = _safeDate(b['appointmentDate']);
      final timeA = a['slotTime'] ?? '00:00';
      final timeB = b['slotTime'] ?? '00:00';

      final comp = '$dateA $timeA'.compareTo('$dateB $timeB');
      return _aptSortAscending ? comp : -comp;
    });

    return Column(
      children: [
        // Thanh bộ lọc & tìm kiếm nâng cấp (Không dùng container trắng tràn viền nữa)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Ô tìm kiếm bo tròn giống Tab 3 và Tab 4
              TextField(
                controller: _aptSearchController,
                decoration: InputDecoration(
                  hintText: 'Tìm lịch hẹn theo tên bệnh nhân...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _aptSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _aptSearchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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

              // 2. Bộ lọc dạng chips trượt ngang
              // 2. Bộ lọc Ngày khám (Hàng 1)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'Hôm nay',
                      selected: _aptDateFilter == 'Today',
                      onSelected: (selected) {
                        setState(() => _aptDateFilter = 'Today');
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Sắp tới',
                      selected: _aptDateFilter == 'Upcoming',
                      onSelected: (selected) {
                        setState(() => _aptDateFilter = 'Upcoming');
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Tất cả ngày',
                      selected: _aptDateFilter == 'All',
                      onSelected: (selected) {
                        setState(() => _aptDateFilter = 'All');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 2. Bộ lọc Ca trực (Hàng 2)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'Tất cả ca',
                      selected: _aptTimeFilter == 'All',
                      onSelected: (selected) {
                        setState(() => _aptTimeFilter = 'All');
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Ca sáng',
                      selected: _aptTimeFilter == 'Morning',
                      onSelected: (selected) {
                        setState(() => _aptTimeFilter = 'Morning');
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Ca chiều',
                      selected: _aptTimeFilter == 'Afternoon',
                      onSelected: (selected) {
                        setState(() => _aptTimeFilter = 'Afternoon');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. Kết quả & Sắp xếp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kết quả: ${filtered.length} lịch hẹn',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _aptSortAscending = !_aptSortAscending;
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.sort_rounded,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _aptSortAscending
                              ? 'Sắp xếp: Giờ tăng dần'
                              : 'Sắp xếp: Giờ giảm dần',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Danh sách lịch hẹn đã lọc
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptySection('Không tìm thấy lịch hẹn phù hợp.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final apt = filtered[index];
                    final String patientName =
                        apt['patientName'] ??
                        apt['patientNameSnapshot'] ??
                        'Bệnh nhân';
                    final String time = apt['slotTime'] ?? '00:00';
                    final String date = _safeDate(apt['appointmentDate']);
                    final String reason = apt['reason'] ?? 'Khám định kỳ';
                    final String status = apt['status'] ?? 'Confirmed';

                    Color statusColor = const Color(0xFF3B82F6);
                    String statusText = 'Đã xác nhận';
                    if (status == 'CheckedIn') {
                      statusColor = const Color(0xFFEF4444);
                      statusText = 'Đã check-in';
                    } else if (status == 'Completed') {
                      statusColor = const Color(0xFF10B981);
                      statusText = 'Hoàn tất';
                    }

                    final int pId = apt['patientId'] ?? 0;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: pId > 0
                            ? () => _showPatientDetailsSheet(
                                context,
                                pId,
                                patientName,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEBF3FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      color: Color(0xFF0F52BA),
                                      size: 16,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      time,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F52BA),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          patientName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.info_outline_rounded,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ngày: $date · Lý do: $reason',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // TAB 3: KHÁM BỆNH & KÊ ĐƠN (EXAMINE & PRESCRIBE)
  Widget _buildExamineTab(
    List<dynamic> queue,
    int doctorId,
    Color primaryColor,
  ) {
    final filteredQueue = queue.where((visit) {
      if (_searchQuery.isEmpty) return true;
      final String patientName = (visit['patientName'] ?? '')
          .toString()
          .toLowerCase();
      return patientName.contains(_searchQuery.toLowerCase());
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm nhanh bệnh nhân chờ khám...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildQueueTab(filteredQueue, doctorId, primaryColor),
        ],
      ),
    );
  }

  // TAB 4: LỊCH SỬ BỆNH ÁN ĐỘNG (HISTORY) - Lọc và tìm kiếm y hệt bản Web
  Widget _buildHistoryTab(
    UserModel user,
    DoctorDashboardController doctorController,
    Color primaryColor,
  ) {
    final myRecords = doctorController.medicalRecords.where((rec) {
      final recDocName = rec['doctorName'] ?? rec['doctorNameSnapshot'] ?? '';
      final recDocId = rec['doctorId'];
      return (recDocId != null &&
              user.doctorId != null &&
              recDocId == user.doctorId) ||
          _normalizeName(recDocName) == _normalizeName(user.fullName);
    }).toList();

    final filteredRecords = myRecords.where((rec) {
      if (_searchQuery.isNotEmpty) {
        final patientName =
            (rec['patientName'] ?? rec['patientNameSnapshot'] ?? '')
                .toString()
                .toLowerCase();
        final diagnosis = (rec['diagnosisText'] ?? '').toString().toLowerCase();
        return patientName.contains(_searchQuery.toLowerCase()) ||
            diagnosis.contains(_searchQuery.toLowerCase());
      }
      return true;
    }).toList();

    // Phân loại trạng thái ca khám hôm nay cho panel chỉ số
    final waitingVisits = doctorController.visits
        .where((v) => v['status'] == 'CheckedIn')
        .toList();
    final examiningVisits = doctorController.visits
        .where((v) => v['status'] == 'Examining')
        .toList();
    final completedVisits = doctorController.visits
        .where((v) => v['status'] == 'Completed')
        .toList();

    Widget historyStatsGrid() {
      final List<Map<String, dynamic>> statItems = [
        {
          'label': 'Tổng dữ liệu',
          'value': filteredRecords.length.toString(),
          'color': const Color(0xFF3B82F6),
          'icon': Icons.folder_open_rounded,
          'note': 'Theo bộ lọc',
        },
        {
          'label': 'Đang chờ',
          'value': waitingVisits.length.toString(),
          'color': const Color(0xFFEF4444),
          'icon': Icons.hourglass_empty_rounded,
          'note': 'Hàng chờ',
        },
        {
          'label': 'Đang khám',
          'value': examiningVisits.length.toString(),
          'color': const Color(0xFFF59E0B),
          'icon': Icons.play_circle_outline_rounded,
          'note': 'Lượt khám',
        },
        {
          'label': 'Hoàn tất',
          'value': completedVisits.length.toString(),
          'color': const Color(0xFF10B981),
          'icon': Icons.check_circle_rounded,
          'note': 'Đã xử lý xong',
        },
      ];

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.none,
        child: Row(
          children: statItems.map((item) {
            return Container(
              width: 105,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 20,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['value'] as String,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: item['color'] as Color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['label'] as String,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    item['note'] as String,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    return Column(
      children: [
        // 1. Ô tìm kiếm
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm bệnh án theo tên bệnh nhân / chẩn đoán...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primaryColor),
              ),
            ),
          ),
        ),

        // 2. Panel 4 chỉ số thống kê đồng bộ bản Web (Luôn hiển thị kể cả danh sách trống)
        historyStatsGrid(),
        const SizedBox(height: 16),

        // 3. Danh sách bệnh án đã lọc
        Expanded(
          child: filteredRecords.isEmpty
              ? _buildEmptySection('Không tìm thấy hồ sơ bệnh án nào phù hợp.')
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredRecords.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final rec = filteredRecords[index];
                    final String patientName =
                        rec['patientName'] ??
                        rec['patientNameSnapshot'] ??
                        'Bệnh nhân';
                    final String diagnosis =
                        rec['diagnosisText'] ?? 'Khám lâm sàng';
                    final String date = rec['createdAt'] != null
                        ? rec['createdAt'].toString().substring(0, 10)
                        : 'Hôm nay';
                    final String note = rec['doctorNote'] ?? '';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                patientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                date,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Chẩn đoán: $diagnosis',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          if (note.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Lời dặn: $note',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // TAB 5: LỊCH LÀM VIỆC ĐỘNG (SCHEDULE)
  Widget _buildScheduleTab(List<dynamic> schedules, Color primaryColor) {
    final themeColor = const Color(
      0xFF0F52BA,
    ); // Màu xanh nước biển Sapphire Blue
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);

    // Tính toán đầu tuần và cuối tuần (Thứ Hai đến Chủ Nhật)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final startOfWeekStr = startOfWeek.toIso8601String().substring(0, 10);
    final endOfWeekStr = endOfWeek.toIso8601String().substring(0, 10);

    // Lọc danh sách lịch làm việc
    List<dynamic> filtered = schedules.where((item) {
      // 1. Tìm kiếm theo từ khóa
      if (_schedSearchQuery.isNotEmpty) {
        final query = _schedSearchQuery.toLowerCase();
        final date = _safeDate(item['workDate']).toLowerCase();
        final room =
            (item['roomName'] ?? item['roomNumber'] ?? item['room'] ?? '')
                .toString()
                .toLowerCase();
        final start = (item['startTime'] ?? '').toString().toLowerCase();
        final end = (item['endTime'] ?? '').toString().toLowerCase();
        if (!date.contains(query) &&
            !room.contains(query) &&
            !start.contains(query) &&
            !end.contains(query)) {
          return false;
        }
      }

      // 2. Bộ lọc thời gian
      final date = _safeDate(item['workDate']);
      if (_schedDateFilter == 'Today' && date != todayStr) return false;
      if (_schedDateFilter == 'Week' &&
          (date.compareTo(startOfWeekStr) < 0 ||
              date.compareTo(endOfWeekStr) > 0)) {
        return false;
      }
      if (_schedDateFilter == 'Upcoming' && date.compareTo(todayStr) <= 0)
        return false;

      // 3. Bộ lọc trạng thái nhận lịch
      final isAvailable =
          item['isAvailable'] != false && item['IsAvailable'] != false;
      if (_schedStatusFilter == 'Available' && !isAvailable) return false;
      if (_schedStatusFilter == 'Unavailable' && isAvailable) return false;

      return true;
    }).toList();

    // Sắp xếp lịch trực tăng dần theo Ngày và Giờ bắt đầu
    filtered.sort((a, b) {
      final dateA = _safeDate(a['workDate']);
      final dateB = _safeDate(b['workDate']);
      final timeA = (a['startTime'] ?? '').toString();
      final timeB = (b['startTime'] ?? '').toString();

      final compDate = dateA.compareTo(dateB);
      if (compDate != 0) return compDate;
      return timeA.compareTo(timeB);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bộ tìm kiếm và các nút lọc (Responsive, không tràn viền)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ô tìm kiếm
              TextField(
                controller: _schedSearchController,
                decoration: InputDecoration(
                  hintText: 'Tìm theo phòng khám, ngày trực...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _schedSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _schedSearchController.clear();
                            setState(() {
                              _schedSearchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: themeColor, width: 1.5),
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
                      selected: _schedDateFilter == 'All',
                      onSelected: (selected) {
                        setState(() => _schedDateFilter = 'All');
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Hôm nay',
                      selected: _schedDateFilter == 'Today',
                      onSelected: (selected) {
                        setState(() => _schedDateFilter = 'Today');
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Tuần này',
                      selected: _schedDateFilter == 'Week',
                      onSelected: (selected) {
                        setState(() => _schedDateFilter = 'Week');
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Sắp tới',
                      selected: _schedDateFilter == 'Upcoming',
                      onSelected: (selected) {
                        setState(() => _schedDateFilter = 'Upcoming');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Hàng bộ lọc 2: Trạng thái nhận lịch
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'Tất cả trạng thái',
                      selected: _schedStatusFilter == 'All',
                      onSelected: (selected) {
                        setState(() => _schedStatusFilter = 'All');
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Còn nhận lịch',
                      selected: _schedStatusFilter == 'Available',
                      onSelected: (selected) {
                        setState(() => _schedStatusFilter = 'Available');
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Đã kín / Nghỉ',
                      selected: _schedStatusFilter == 'Unavailable',
                      onSelected: (selected) {
                        setState(() => _schedStatusFilter = 'Unavailable');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Dòng thống kê số ca
              Text(
                'Thống kê: ${filtered.length} ca trực',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Danh sách ca trực
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptySection(
                  'Không tìm thấy ca trực nào phù hợp với bộ lọc.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = filtered[index];

                    final workDateStr = _safeDate(item['workDate']);
                    final dayName = _getWeekdayFromDate(workDateStr);
                    final dateFormatted = _formatDateVN(workDateStr);

                    final start = item['startTime']?.toString() ?? '';
                    final end = item['endTime']?.toString() ?? '';
                    final startTimeStr = start.length >= 5
                        ? start.substring(0, 5)
                        : '--:--';
                    final endTimeStr = end.length >= 5
                        ? end.substring(0, 5)
                        : '--:--';
                    final timeRange = '$startTimeStr - $endTimeStr';

                    final room =
                        item['roomName'] ??
                        item['roomNumber'] ??
                        item['room'] ??
                        'Chưa xếp phòng';
                    final isAvailable =
                        item['isAvailable'] != false &&
                        item['IsAvailable'] != false;
                    final duration = item['slotDurationMinutes'] ?? 30;

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
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Icon + Thứ, ngày + Badge trạng thái
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: themeColor.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.calendar_today_rounded,
                                      color: themeColor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        dateFormatted,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isAvailable
                                      ? const Color(0xFFE6F4EA)
                                      : const Color(0xFFFCE8E6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isAvailable ? 'Còn nhận lịch' : 'Đã kín lịch',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isAvailable
                                        ? const Color(0xFF137333)
                                        : const Color(0xFFC5221F),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, thickness: 1),

                          // Body: Chi tiết ca trực
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Ca trực: ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                timeRange,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.av_timer_rounded,
                                size: 14,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Thời lượng: ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                '$duration phút/ca',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Phòng khám: ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                room,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: themeColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- SUB-WIDGETS TRỢ GIÚP ---

  Widget _buildDoctorCommandHeader({
    required UserModel user,
    required int todayAppointments,
    required int activeQueue,
    required Color primaryColor,
  }) {
    return WeatherGreetingCard(
      displayName: user.fullName,
      primaryColor: primaryColor,
    );
  }

  Widget _buildDoctorHeaderPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.78),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorActionGrid(Color primaryColor) {
    final actions = [
      {
        'title': 'Hàng đợi khám',
        'subtitle': 'Bệnh nhân đã check-in',
        'icon': Icons.groups_2_rounded,
        'index': 1,
        'color': primaryColor,
      },
      {
        'title': 'Lịch hẹn',
        'subtitle': 'Xem lịch hôm nay',
        'icon': Icons.calendar_month_rounded,
        'index': 2,
        'color': const Color(0xFF2563EB),
      },
      {
        'title': 'Khám & kê đơn',
        'subtitle': 'Bắt đầu ca khám',
        'icon': Icons.edit_note_rounded,
        'index': 3,
        'color': const Color(0xFF059669),
      },
      {
        'title': 'Bệnh án',
        'subtitle': 'Lịch sử điều trị',
        'icon': Icons.history_edu_rounded,
        'index': 4,
        'color': const Color(0xFF7C3AED),
      },
      {
        'title': 'Lịch làm việc',
        'subtitle': 'Ca trực của tôi',
        'icon': Icons.calendar_view_week_rounded,
        'index': 5,
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'Làm mới',
        'subtitle': 'Đồng bộ dữ liệu',
        'icon': Icons.refresh_rounded,
        'index': -1,
        'color': const Color(0xFF0891B2),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.62,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildDoctorActionCard(
          title: action['title'] as String,
          subtitle: action['subtitle'] as String,
          icon: action['icon'] as IconData,
          color: action['color'] as Color,
          onTap: () {
            final target = action['index'] as int;
            if (target == -1) {
              _refreshData();
            } else {
              _changeTab(target);
            }
          },
        );
      },
    );
  }

  Widget _buildDoctorActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorMetricsGrid({
    required int appointments,
    required int waiting,
    required int examining,
    required int completed,
    required int prescriptions,
    required Color primaryColor,
  }) {
    final items = [
      ('Lịch hẹn', appointments, Icons.calendar_today_rounded, primaryColor),
      ('Chờ khám', waiting, Icons.groups_2_rounded, const Color(0xFFF59E0B)),
      (
        'Đang khám',
        examining,
        Icons.monitor_heart_rounded,
        const Color(0xFF2563EB),
      ),
      ('Hoàn tất', completed, Icons.task_alt_rounded, const Color(0xFF10B981)),
      (
        'Đơn thuốc',
        prescriptions,
        Icons.medication_rounded,
        const Color(0xFF7C3AED),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.78,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildDoctorMetricCard(
          label: item.$1,
          value: item.$2,
          icon: item.$3,
          color: item.$4,
        );
      },
    );
  }

  Widget _buildDoctorMetricCard({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorAttentionPanel({
    required List<dynamic> activeQueue,
    required List<dynamic> pendingAppointments,
    required int prescriptionsCount,
    required Color primaryColor,
  }) {
    final items = <Widget>[];

    if (activeQueue.isNotEmpty) {
      items.add(
        _buildDoctorAttentionTile(
          icon: Icons.play_circle_outline_rounded,
          title: 'Bệnh nhân đang chờ khám',
          subtitle: '${activeQueue.length} bệnh nhân cần xử lý',
          color: const Color(0xFFF59E0B),
          onTap: () => _changeTab(1),
        ),
      );
    }

    if (pendingAppointments.isNotEmpty) {
      items.add(
        _buildDoctorAttentionTile(
          icon: Icons.event_available_rounded,
          title: 'Lịch hẹn cần theo dõi',
          subtitle: '${pendingAppointments.length} lịch trong hôm nay',
          color: primaryColor,
          onTap: () => _changeTab(2),
        ),
      );
    }

    if (prescriptionsCount > 0) {
      items.add(
        _buildDoctorAttentionTile(
          icon: Icons.medication_rounded,
          title: 'Đơn thuốc đã kê',
          subtitle: '$prescriptionsCount đơn thuốc trong hồ sơ',
          color: const Color(0xFF7C3AED),
          onTap: () => _changeTab(4),
        ),
      );
    }

    if (items.isEmpty) {
      return _buildDoctorAttentionTile(
        icon: Icons.verified_rounded,
        title: 'Không có việc cần xử lý gấp',
        subtitle: 'Hệ thống sẽ cập nhật khi có bệnh nhân check-in.',
        color: const Color(0xFF10B981),
        onTap: () => _changeTab(2),
      );
    }

    return Column(children: items);
  }

  Widget _buildDoctorAttentionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Thẻ chào mừng bác sĩ được thiết kế lại theo bản Web
  // ignore: unused_element
  Widget _buildRedesignedWelcomeBanner(UserModel user, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Gradient Top
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'BẢNG ĐIỀU KHIỂN BÁC SĨ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Xin chào, BS. ${user.fullName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Theo dõi lịch khám, hàng chờ và bệnh án cần xử lý trong ngày của bác sĩ.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedMenuIndex = 2; // Xem lịch hẹn
                        });
                      },
                      icon: const Icon(Icons.calendar_month, size: 14),
                      label: const Text(
                        'Xem lịch hẹn',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F52BA),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedMenuIndex = 3; // Khám bệnh & kê đơn
                        });
                      },
                      icon: const Icon(
                        Icons.medical_services_outlined,
                        size: 14,
                      ),
                      label: const Text(
                        'Khám bệnh',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Phiên làm việc Details Bottom
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF8FAFC),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông tin phiên làm việc',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                _buildSessionRow('Bác sĩ', 'BS. ${user.fullName}'),
                const Divider(height: 10, color: Color(0xFFE2E8F0)),
                _buildSessionRow(
                  'Chuyên khoa',
                  user.specialtyName ?? 'Chưa cập nhật',
                ),
                const Divider(height: 10, color: Color(0xFFE2E8F0)),
                _buildSessionRow('Ngày trực', _todayLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // 5 chỉ số thống kê đồng bộ bản Web
  // ignore: unused_element
  Widget _buildStatsGrid({
    required int appointmentsCount,
    required int waiting,
    required int examining,
    required int completed,
    required int prescriptionsCount,
  }) {
    final List<Map<String, dynamic>> statItems = [
      {
        'label': 'Lịch hẹn',
        'value': appointmentsCount.toString(),
        'color': const Color(0xFF3B82F6),
        'icon': Icons.calendar_today_rounded,
        'note': 'Lịch hôm nay',
      },
      {
        'label': 'Chờ khám',
        'value': waiting.toString(),
        'color': const Color(0xFFEF4444),
        'icon': Icons.hourglass_empty_rounded,
        'note': 'Hàng chờ',
      },
      {
        'label': 'Đang khám',
        'value': examining.toString(),
        'color': const Color(0xFFF59E0B),
        'icon': Icons.play_circle_outline_rounded,
        'note': 'Lượt khám',
      },
      {
        'label': 'Đã xong',
        'value': completed.toString(),
        'color': const Color(0xFF10B981),
        'icon': Icons.check_circle_rounded,
        'note': 'Hoàn tất',
      },
      {
        'label': 'Đã kê đơn',
        'value': prescriptionsCount.toString(),
        'color': const Color(0xFF6366F1),
        'icon': Icons.description_rounded,
        'note': 'Đơn thuốc',
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 16) / 3; // 3 items per row
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: statItems.map((item) {
            return Container(
              width: cardWidth < 95 ? 95 : cardWidth,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 20,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['value'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: item['color'] as Color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['label'] as String,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    item['note'] as String,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Dashboard Preview Panel
  Widget _buildDashboardPanel({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(padding: const EdgeInsets.all(12.0), child: child),
        ],
      ),
    );
  }

  // Simple Appointment Card for dashboard preview
  Widget _buildSimpleAppointmentCard(dynamic apt, Color primaryColor) {
    final String patientName =
        apt['patientName'] ?? apt['patientNameSnapshot'] ?? 'Bệnh nhân';
    final String time = apt['slotTime'] ?? '00:00';
    final String reason = apt['reason'] ?? 'Khám định kỳ';
    final String status = apt['status'] ?? 'Confirmed';
    final int pId = apt['patientId'] ?? 0;

    Color statusColor = const Color(0xFF3B82F6);
    String statusText = 'Đã xác nhận';
    if (status == 'CheckedIn') {
      statusColor = const Color(0xFFEF4444);
      statusText = 'Đã check-in';
    } else if (status == 'Completed') {
      statusColor = const Color(0xFF10B981);
      statusText = 'Hoàn tất';
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: pId > 0
            ? () => _showPatientDetailsSheet(context, pId, patientName)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF3FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F52BA),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      reason,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Filter Chip helper
  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    final themeColor = const Color(
      0xFF0F52BA,
    ); // Màu xanh nước biển Sapphire Blue
    return GestureDetector(
      onTap: () => onSelected(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? themeColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: themeColor.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
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

  // Safe substring date helper
  String _safeDate(dynamic val) {
    final str = val?.toString() ?? '';
    if (str.length >= 10) return str.substring(0, 10);
    return str;
  }

  // Dynamic today label helper
  String get _todayLabel {
    final now = DateTime.now();
    final weekdays = [
      'Chủ Nhật',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
    ];
    final weekday = weekdays[now.weekday % 7];
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year;
    return '$weekday, $day/$month/$year';
  }

  // Thẻ bệnh nhân tiếp theo (Ưu tiên)
  Widget _buildNextPatientCard(
    Map<String, dynamic> visit,
    int doctorId,
    Color primaryColor,
  ) {
    final String name = visit['patientName'] ?? 'Bệnh nhân';
    final String chiefComplaint = visit['chiefComplaint'] ?? 'Khám lâm sàng';
    final int queueNumber = visit['queueNumber'] ?? 1;
    final int pId =
        visit['patientId'] ??
        visit['patient']?['id'] ??
        visit['patient']?['patientId'] ??
        0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: pId > 0
            ? () => _showPatientDetailsSheet(context, pId, name)
            : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primaryColor.withOpacity(0.08),
                child: Text(
                  queueNumber.toString(),
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lý do: $chiefComplaint',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DoctorExamineView(visit: visit, doctorId: doctorId),
                    ),
                  ).then((_) => _refreshData());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Khám ngay',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hiển thị Bottom Sheet thông tin chi tiết & lịch sử bệnh án bệnh nhân
  void _showPatientDetailsSheet(
    BuildContext context,
    int patientId,
    String patientName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: FutureBuilder<List<dynamic>>(
                future: Future.wait([
                  context.read<DoctorDashboardController>().getPatientDetail(
                    patientId,
                  ),
                  context.read<DoctorDashboardController>().getPatientHistory(
                    patientId,
                  ),
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF0F52BA)),
                          SizedBox(height: 12),
                          Text(
                            'Đang tải hồ sơ bệnh nhân...',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Lỗi khi tải dữ liệu bệnh nhân.'),
                    );
                  }

                  final patientData =
                      snapshot.data != null && snapshot.data!.isNotEmpty
                      ? snapshot.data![0] as Map<String, dynamic>?
                      : null;
                  final historyData =
                      snapshot.data != null && snapshot.data!.length > 1
                      ? snapshot.data![1] as List<dynamic>?
                      : null;

                  if (patientData == null) {
                    return const Center(
                      child: Text(
                        'Không tìm thấy thông tin bệnh nhân trên hệ thống.',
                      ),
                    );
                  }

                  final dob = patientData['dateOfBirth'] ?? 'Chưa cập nhật';
                  final cleanDob = dob.toString().split('T')[0];
                  final gender = patientData['gender'] == 'Male'
                      ? 'Nam'
                      : patientData['gender'] == 'Female'
                      ? 'Nữ'
                      : 'Khác';
                  final allergy =
                      patientData['allergyNote'] ??
                      patientData['allergies'] ??
                      'Chưa ghi nhận';
                  final history =
                      patientData['medicalHistory'] ?? 'Chưa ghi nhận';

                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Thanh bar kéo
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Tiêu đề đầu trang
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(
                              0xFF0F52BA,
                            ).withOpacity(0.1),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF0F52BA),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patientData['fullName'] ?? patientName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Mã BN: ${patientData['patientCode'] ?? patientData['id'] ?? "BN-$patientId"}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Phần 1: Thông tin hành chính
                      const Text(
                        'HÀNH CHÍNH & THÔNG TIN CHUNG',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow('Ngày sinh', cleanDob),
                            const Divider(height: 16),
                            _buildDetailRow('Giới tính', gender),
                            const Divider(height: 16),
                            _buildDetailRow(
                              'Số điện thoại',
                              patientData['phoneNumber'] ?? 'Chưa cập nhật',
                            ),
                            const Divider(height: 16),
                            _buildDetailRow(
                              'Email',
                              patientData['email'] ?? 'Chưa cập nhật',
                            ),
                            const Divider(height: 16),
                            _buildDetailRow(
                              'Nhóm máu',
                              patientData['bloodType'] ?? 'Chưa cập nhật',
                            ),
                            const Divider(height: 16),
                            _buildDetailRow(
                              'Địa chỉ',
                              patientData['address'] ?? 'Chưa cập nhật',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Phần 2: Tiền sử & Dị ứng
                      const Text(
                        'TIỀN SỬ BỆNH & DỊ ỨNG',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFEDD5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Dị ứng / Ghi chú dị ứng:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFFC2410C),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              allergy,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF7C2D12),
                              ),
                            ),
                            const Divider(height: 20, color: Color(0xFFFFEDD5)),
                            const Row(
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  color: Colors.blue,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Tiền sử bệnh lý:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              history,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Phần 3: Lịch sử bệnh án khám gần đây
                      const Text(
                        'LỊCH SỬ KHÁM BỆNH GẦN ĐÂY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (historyData == null || historyData.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Bệnh nhân chưa có lịch sử khám bệnh trước đó.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        )
                      else
                        ...historyData.take(5).map((record) {
                          final String diagnosis =
                              record['diagnosisText'] ?? 'Khám lâm sàng';
                          final String date = record['createdAt'] != null
                              ? record['createdAt'].toString().substring(0, 10)
                              : 'N/A';
                          final String doctor =
                              record['doctorName'] ??
                              record['doctorNameSnapshot'] ??
                              'Bác sĩ';
                          final String plan = record['treatmentPlan'] ?? '';
                          final String note = record['doctorNote'] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      date,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'BS: $doctor',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF0F52BA),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Chẩn đoán: $diagnosis',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                if (plan.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Điều trị: $plan',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ],
                                if (note.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Lời dặn: $note',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // Các nút thao tác nhanh trên trang chủ
  // ignore: unused_element
  Widget _buildQuickActionsGrid(Color primaryColor) {
    final List<Map<String, dynamic>> actions = [
      {'title': 'Hàng chờ khám', 'icon': Icons.people_alt_outlined, 'index': 1},
      {
        'title': 'Lịch hẹn hôm nay',
        'icon': Icons.calendar_today_outlined,
        'index': 2,
      },
      {
        'title': 'Lịch sử bệnh án',
        'icon': Icons.history_edu_outlined,
        'index': 4,
      },
      {
        'title': 'Lịch làm việc',
        'icon': Icons.calendar_view_week_outlined,
        'index': 5,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.3,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final act = actions[index];
        return InkWell(
          onTap: () {
            setState(() {
              _selectedMenuIndex = act['index'];
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Icon(act['icon'], color: primaryColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    act['title'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Thẻ bệnh nhân trong danh sách
  Widget _buildPatientVisitCard(
    Map<String, dynamic> visit,
    int doctorId,
    Color primaryColor,
  ) {
    final status = visit['status'] ?? 'CheckedIn';
    final String patientName = visit['patientName'] ?? 'Bệnh nhân';
    final String chiefComplaint = visit['chiefComplaint'] ?? 'Khám lâm sàng';
    final int queueNumber = visit['queueNumber'] ?? 0;
    final int pId =
        visit['patientId'] ??
        visit['patient']?['id'] ??
        visit['patient']?['patientId'] ??
        0;

    Color statusColor = status == 'Examining'
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);
    String statusText = status == 'Examining' ? 'Đang khám' : 'Chờ khám';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status == 'Examining'
              ? primaryColor.withOpacity(0.4)
              : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: pId > 0
            ? () => _showPatientDetailsSheet(context, pId, patientName)
            : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  queueNumber > 0 ? queueNumber.toString() : '#',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          patientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lý do: $chiefComplaint',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DoctorExamineView(visit: visit, doctorId: doctorId),
                    ),
                  ).then((_) => _refreshData());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      status == 'Examining' ? 'Khám tiếp' : 'Khám',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      status == 'Examining'
                          ? Icons.play_arrow_rounded
                          : Icons.edit_note_rounded,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            color: Colors.grey.shade200,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // SIDEBAR (DRAWER) ĐỒNG BỘ 6 TAB NHƯ BẢN WEB
  // ignore: unused_element
  Widget _buildDoctorSidebar(UserModel user, Color primaryColor) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Bảng điều khiển',
        'icon': Icons.dashboard_outlined,
        'index': 0,
      },
      {
        'title': 'Hàng đợi khám',
        'icon': Icons.people_outline_rounded,
        'index': 1,
      },
      {'title': 'Lịch hẹn', 'icon': Icons.calendar_today_outlined, 'index': 2},
      {'title': 'Khám & kê đơn', 'icon': Icons.healing_outlined, 'index': 3},
      {
        'title': 'Lịch sử bệnh án',
        'icon': Icons.history_edu_outlined,
        'index': 4,
      },
      {
        'title': 'Lịch làm việc',
        'icon': Icons.calendar_month_outlined,
        'index': 5,
      },
    ];

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: Builder(
              builder: (context) {
                final String? dbAvatar = user.avatarUrl;
                String finalAvatarUrl =
                    'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=256&auto=format&fit=crop';

                if (dbAvatar != null && dbAvatar.trim().isNotEmpty) {
                  if (dbAvatar.startsWith('http://') ||
                      dbAvatar.startsWith('https://')) {
                    finalAvatarUrl = dbAvatar;
                  } else {
                    const base = 'https://api.hwpresents.site';
                    final path = dbAvatar.startsWith('/')
                        ? dbAvatar
                        : '/$dbAvatar';
                    finalAvatarUrl = '$base$path';
                  }
                }

                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      finalAvatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        final nameParts = user.fullName.trim().split(' ');
                        final initials =
                            nameParts.isNotEmpty && nameParts.last.isNotEmpty
                            ? nameParts.last[0].toUpperCase()
                            : 'A';
                        return Container(
                          color: Colors.white,
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 28,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            accountName: Text(
              user.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(
              'Chuyên khoa: ${user.specialtyName ?? "Tim mạch"}',
              style: const TextStyle(fontSize: 12),
            ),
          ),

          // Danh sách 6 Tab điều hướng
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = _selectedMenuIndex == item['index'];

                return ListTile(
                  leading: Icon(
                    item['icon'],
                    color: isSelected ? primaryColor : const Color(0xFF64748B),
                  ),
                  title: Text(
                    item['title'],
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? primaryColor
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: primaryColor.withOpacity(0.06),
                  onTap: () {
                    setState(() {
                      _selectedMenuIndex = item['index'];
                    });
                    Navigator.pop(context); // Đóng drawer
                  },
                );
              },
            ),
          ),
          const Divider(),
          // Nút đăng xuất ở chân Sidebar
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context, context.read<AuthController>());
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ignore: unused_element
  void _showLogoutDialog(BuildContext context, AuthController authController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất'),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất tài khoản bác sĩ không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authController.logout();
            },
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Mappers
  String _normalizeName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'^(bs\.|bs|bác sĩ)\s*'), '')
        .trim();
  }

  // ignore: unused_element
  String _getDayOfWeekName(dynamic day) {
    final dayStr = day.toString();
    if (dayStr == '1' || dayStr == 'Monday') return 'Thứ Hai';
    if (dayStr == '2' || dayStr == 'Tuesday') return 'Thứ Ba';
    if (dayStr == '3' || dayStr == 'Wednesday') return 'Thứ Tư';
    if (dayStr == '4' || dayStr == 'Thursday') return 'Thứ Năm';
    if (dayStr == '5' || dayStr == 'Friday') return 'Thứ Sáu';
    if (dayStr == '6' || dayStr == 'Saturday') return 'Thứ Bảy';
    if (dayStr == '0' || dayStr == 'Sunday') return 'Chủ Nhật';
    return dayStr;
  }

  // ignore: unused_element
  String _getShiftTypeName(dynamic shift, dynamic start, dynamic end) {
    final startStr = start != null ? start.toString().substring(0, 5) : '';
    final endStr = end != null ? end.toString().substring(0, 5) : '';
    final times = (startStr.isNotEmpty && endStr.isNotEmpty)
        ? '$startStr - $endStr'
        : '';

    final shiftStr = shift.toString();
    if (shiftStr == '0' || shiftStr == 'Morning' || shiftStr == 'Sáng') {
      return 'Sáng${times.isNotEmpty ? ": $times" : ""}';
    }
    if (shiftStr == '1' || shiftStr == 'Afternoon' || shiftStr == 'Chiều') {
      return 'Chiều${times.isNotEmpty ? ": $times" : ""}';
    }
    return 'Cả ngày${times.isNotEmpty ? ": $times" : ""}';
  }

  String _getWeekdayFromDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final weekdays = [
        'Chủ Nhật',
        'Thứ Hai',
        'Thứ Ba',
        'Thứ Tư',
        'Thứ Năm',
        'Thứ Sáu',
        'Thứ Bảy',
      ];
      return weekdays[date.weekday % 7];
    } catch (_) {
      return 'Thứ';
    }
  }

  String _formatDateVN(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
