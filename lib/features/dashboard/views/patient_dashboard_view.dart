import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../appointment/models/appointment_model.dart';
import '../controllers/patient_dashboard_controller.dart';
import '../../appointment/views/patient_booking_view.dart';
import '../../appointment/views/patient_appointments_view.dart';
import '../../patient/views/patient_medical_records_view.dart';
import '../../billing/views/patient_prescriptions_view.dart';
import '../../billing/views/patient_billing_view.dart';
import '../../profile/views/patient_profile_view.dart';
import '../widgets/role_dashboard_shell.dart';
import '../widgets/weather_greeting_card.dart';
import '../widgets/notification_bell.dart';
import '../widgets/dogky_floating_assistant.dart';

class PatientDashboardView extends StatefulWidget {
  const PatientDashboardView({super.key});

  @override
  State<PatientDashboardView> createState() => _PatientDashboardViewState();
}

class _PatientDashboardViewState extends State<PatientDashboardView> {
  // 0: Tổng quan, 1: Đặt lịch khám, 2: Lịch hẹn, 3: Hồ sơ bệnh án, 4: Đơn thuốc, 5: Viện phí, 6: Hồ sơ cá nhân
  int _currentViewIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientDashboardController>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final dashboardController = context.watch<PatientDashboardController>();
    final primaryColor = const Color(0xFF0F52BA);

    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;

    if (dashboardController.isLoading && dashboardController.patient == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Xử lý hiển thị tên người dùng
    String displayName = dashboardController.patient?.fullName ?? '';
    if (displayName.isEmpty) {
      displayName = authController.currentUser?.fullName ?? '';
    }
    if (displayName.isEmpty) {
      displayName = authController.currentUser?.username ?? 'Bệnh nhân';
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          _getPatientTitle(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
        actions: [
          NotificationBell(
            role: 'Patient',
            onTabChanged: (index) {
              setState(() {
                _currentViewIndex = index;
              });
            },
          ),
          IconButton(
            tooltip: 'Làm mới',
            icon: Icon(Icons.refresh_rounded, color: primaryColor),
            onPressed: () {
              dashboardController.loadDashboardData();
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, displayName, primaryColor, authController),
      body: Stack(
        children: [
          _buildBody(
            isWideScreen,
            displayName,
            primaryColor,
            dashboardController,
            authController,
          ),
          const DogkyFloatingAssistant(),
        ],
      ),
      bottomNavigationBar: isWideScreen
          ? null
          : NavigationBar(
              height: 68,
              backgroundColor: Colors.white,
              indicatorColor: primaryColor.withOpacity(0.12),
              selectedIndex: _mapViewIndexToBottomBarIndex(_currentViewIndex),
              onDestinationSelected: (index) {
                setState(() {
                  _currentViewIndex = _mapBottomBarIndexToViewIndex(index);
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Tổng quan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_today_outlined),
                  selectedIcon: Icon(Icons.calendar_today_rounded),
                  label: 'Lịch khám',
                ),
                NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment_rounded),
                  label: 'Bệnh án',
                ),
                NavigationDestination(
                  icon: Icon(Icons.medication_outlined),
                  selectedIcon: Icon(Icons.medication_rounded),
                  label: 'Đơn thuốc',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: 'Viện phí',
                ),
              ],
            ),
    );
  }

  // Ánh xạ View Index (0-6) sang Bottom Bar Index (0-4)
  int _mapViewIndexToBottomBarIndex(int viewIndex) {
    switch (viewIndex) {
      case 0:
        return 0; // Tổng quan
      case 1:
      case 2:
        return 1; // Lịch khám (Gộp cả đặt lịch và lịch hẹn)
      case 3:
        return 2; // Bệnh án
      case 4:
        return 3; // Đơn thuốc
      case 5:
        return 4; // Viện phí
      case 6:
      default:
        return 0;
    }
  }

  // Ánh xạ Bottom Bar Index (0-4) sang View Index (0-6)
  int _mapBottomBarIndexToViewIndex(int barIndex) {
    switch (barIndex) {
      case 0:
        return 0; // Bảng điều khiển
      case 1:
        return 2; // Lịch hẹn (mặc định mở lịch hẹn)
      case 2:
        return 3; // Hồ sơ bệnh án
      case 3:
        return 4; // Đơn thuốc
      case 4:
        return 5; // Viện phí
      default:
        return 0;
    }
  }

  static const List<RoleDashboardMenuItem> _patientMenuItems = [
    RoleDashboardMenuItem(
      title: 'Bảng điều khiển',
      icon: Icons.dashboard_rounded,
      index: 0,
      section: 'Tổng quan',
    ),
    RoleDashboardMenuItem(
      title: 'Đặt lịch khám',
      icon: Icons.add_circle_outline_rounded,
      index: 1,
      section: 'Dịch vụ',
    ),
    RoleDashboardMenuItem(
      title: 'Lịch hẹn',
      icon: Icons.event_note_rounded,
      index: 2,
      section: 'Dịch vụ',
    ),
    RoleDashboardMenuItem(
      title: 'Hồ sơ bệnh án',
      icon: Icons.assignment_rounded,
      index: 3,
      section: 'Dịch vụ',
    ),
    RoleDashboardMenuItem(
      title: 'Đơn thuốc',
      icon: Icons.healing_rounded,
      index: 4,
      section: 'Dịch vụ',
    ),
    RoleDashboardMenuItem(
      title: 'Viện phí',
      icon: Icons.receipt_long_rounded,
      index: 5,
      section: 'Dịch vụ',
    ),
    RoleDashboardMenuItem(
      title: 'Hồ sơ cá nhân',
      icon: Icons.person_rounded,
      index: 6,
      section: 'Tài khoản',
    ),
  ];

  String _getPatientTitle() {
    switch (_currentViewIndex) {
      case 0:
        return 'Bảng điều khiển';
      case 1:
        return 'Đặt lịch khám';
      case 2:
        return 'Lịch hẹn của tôi';
      case 3:
        return 'Hồ sơ bệnh án';
      case 4:
        return 'Đơn thuốc';
      case 5:
        return 'Viện phí';
      case 6:
        return 'Hồ sơ cá nhân';
      default:
        return 'MedicareDNU';
    }
  }

  Widget _buildDrawer(
    BuildContext context,
    String displayName,
    Color primaryColor,
    AuthController authController,
  ) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, _lightenColor(primaryColor)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Text(
                    _getInitials(displayName),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (authController.currentUser?.email != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    authController.currentUser!.email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.82),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'BỆNH NHÂN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'TỔNG QUAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                _buildDrawerItem(0, Icons.dashboard_rounded, 'Bảng điều khiển'),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'DỊCH VỤ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                _buildDrawerItem(1, Icons.add_circle_outline_rounded, 'Đặt lịch khám'),
                _buildDrawerItem(2, Icons.event_note_rounded, 'Lịch hẹn'),
                _buildDrawerItem(3, Icons.assignment_rounded, 'Hồ sơ bệnh án'),
                _buildDrawerItem(4, Icons.healing_rounded, 'Đơn thuốc'),
                _buildDrawerItem(5, Icons.receipt_long_rounded, 'Viện phí'),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'TÀI KHOẢN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                _buildDrawerItem(6, Icons.person_rounded, 'Hồ sơ cá nhân'),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title) {
    final isSelected = _currentViewIndex == index;
    final primaryColor = const Color(0xFF0F52BA);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withOpacity(0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        minLeadingWidth: 24,
        leading: Icon(
          icon,
          color: isSelected ? primaryColor : Colors.grey.shade600,
          size: 22,
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? primaryColor : Colors.grey.shade800,
            fontSize: 14,
          ),
        ),
        onTap: () {
          setState(() {
            _currentViewIndex = index;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F52BA),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthController>().logout();
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Color _lightenColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0)).toColor();
  }

  Widget _buildBody(
    bool isWideScreen,
    String displayName,
    Color primaryColor,
    PatientDashboardController dashboardController,
    AuthController authController,
  ) {
    switch (_currentViewIndex) {
      case 0:
        return _buildDashboardHome(
          isWideScreen,
          displayName,
          primaryColor,
          dashboardController,
          authController,
        );
      case 1:
        return PatientBookingView(
          onBookingSuccess: () {
            setState(() {
              _currentViewIndex = 2; // Chuyển sang tab Lịch hẹn
            });
            context.read<PatientDashboardController>().loadDashboardData();
          },
        );
      case 2:
        return const PatientAppointmentsView();
      case 3:
        return const PatientMedicalRecordsView();
      case 4:
        return const PatientPrescriptionsView();
      case 5:
        return const PatientBillingView();
      case 6:
        return const PatientProfileView();
      default:
        return _buildDashboardHome(
          isWideScreen,
          displayName,
          primaryColor,
          dashboardController,
          authController,
        );
    }
  }

  Widget _buildDashboardHome(
    bool isWideScreen,
    String displayName,
    Color primaryColor,
    PatientDashboardController dashboardController,
    AuthController authController,
  ) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => dashboardController.loadDashboardData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact Greeting Card
              _buildCompactGreetingCard(displayName, primaryColor, dashboardController),
              const SizedBox(height: 16),

              // Quick Actions Grid
              _buildQuickActionsGrid(primaryColor),
              const SizedBox(height: 16),

              // Stats Section - "Tình trạng của bạn"
              _buildStatsSection(dashboardController, primaryColor),
              const SizedBox(height: 16),

              // Next Appointment Card
              _buildNextAppointmentCard(dashboardController, primaryColor),
              const SizedBox(height: 16),

              // Tasks Notification Card
              _buildTasksNotificationCard(dashboardController, primaryColor),
              const SizedBox(height: 16),

              // Charts (optional on mobile, show on wide screen or if enabled)
              if (isWideScreen) ...[
                _buildTrendChartCard(dashboardController, primaryColor),
                const SizedBox(height: 16),
                _buildAppointmentStatusCard(dashboardController, primaryColor),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactGreetingCard(String displayName, Color primaryColor, PatientDashboardController controller) {
    return WeatherGreetingCard(
      displayName: displayName,
      primaryColor: primaryColor,
      address: controller.patient?.address ?? '',
    );
  }

  Widget _buildQuickActionsGrid(Color primaryColor) {
    final actions = [
      {
        'title': 'Đặt lịch khám',
        'subtitle': 'Đặt lịch mới',
        'icon': Icons.add_circle_outline_rounded,
        'color': primaryColor,
        'index': 1,
        'isPrimary': true,
      },
      {
        'title': 'Lịch hẹn',
        'subtitle': 'Xem lịch khám',
        'icon': Icons.event_note_rounded,
        'color': primaryColor,
        'index': 2,
        'isPrimary': false,
      },
      {
        'title': 'Hồ sơ bệnh án',
        'subtitle': 'Xem hồ sơ',
        'icon': Icons.assignment_rounded,
        'color': primaryColor,
        'index': 3,
        'isPrimary': false,
      },
      {
        'title': 'Đơn thuốc',
        'subtitle': 'Đơn của bạn',
        'icon': Icons.healing_rounded,
        'color': Colors.orange,
        'index': 4,
        'isPrimary': false,
      },
      {
        'title': 'Viện phí',
        'subtitle': 'Thanh toán',
        'icon': Icons.receipt_long_rounded,
        'color': Colors.green,
        'index': 5,
        'isPrimary': false,
      },
      {
        'title': 'Hồ sơ cá nhân',
        'subtitle': 'Thông tin',
        'icon': Icons.person_rounded,
        'color': Colors.blueGrey,
        'index': 6,
        'isPrimary': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Truy cập nhanh',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.4,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            final isPrimary = action['isPrimary'] as bool;
            final color = action['color'] as Color;
            
            return InkWell(
              onTap: () {
                setState(() {
                  _currentViewIndex = action['index'] as int;
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPrimary ? color.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isPrimary ? color : Colors.grey.shade200,
                    width: isPrimary ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        action['icon'] as IconData,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            action['title'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isPrimary ? color : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            action['subtitle'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      ],
    );
  }

  Widget _buildNextAppointmentCard(
    PatientDashboardController controller,
    Color primaryColor,
  ) {
    final nextAppt = controller.nextAppointment;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lịch hẹn gần nhất',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: primaryColor,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (nextAppt != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nextAppt.doctorName ?? 'Bác sĩ chưa cập nhật',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${nextAppt.appointmentDate} • ${nextAppt.slotTime}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  if (nextAppt.specialtyName != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.local_hospital_rounded,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            nextAppt.specialtyName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(nextAppt.status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusLabel(nextAppt.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(nextAppt.status),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentViewIndex = 2; // Chuyển sang Lịch hẹn
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Xem chi tiết',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 40,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bạn chưa có lịch khám sắp tới',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _currentViewIndex = 1; // Đặt lịch khám
                        });
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Đặt lịch khám'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTasksNotificationCard(
    PatientDashboardController controller,
    Color primaryColor,
  ) {
    final unpaidInvoices = controller.invoices
        .where((inv) => inv.status?.toLowerCase() != 'paid')
        .length;
    final totalPrescriptions = controller.totalMedicalRecords;
    
    final hasTasks = unpaidInvoices > 0 || totalPrescriptions > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasTasks
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasTasks ? Icons.notifications_active_rounded : Icons.check_circle_rounded,
                  color: hasTasks ? Colors.orange : Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Việc cần chú ý',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasTasks) ...[
            if (unpaidInvoices > 0)
              _buildTaskItem(
                Icons.receipt_long_rounded,
                'Bạn có $unpaidInvoices hóa đơn cần thanh toán',
                Colors.red,
                () {
                  setState(() {
                    _currentViewIndex = 5; // Viện phí
                  });
                },
              ),
            if (unpaidInvoices > 0 && totalPrescriptions > 0)
              const SizedBox(height: 10),
            if (totalPrescriptions > 0)
              _buildTaskItem(
                Icons.healing_rounded,
                'Bạn có $totalPrescriptions đơn thuốc',
                Colors.orange,
                () {
                  setState(() {
                    _currentViewIndex = 4; // Đơn thuốc
                  });
                },
              ),
          ] else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Không có việc cần xử lý',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
    IconData icon,
    String text,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChartCard(
    PatientDashboardController controller,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Xu hướng khám 6 tháng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Số lịch hẹn và bệnh án phát sinh theo tháng',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildLegendItem(primaryColor, 'Lịch hẹn'),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.orange, 'Bệnh án'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            width: double.infinity,
            child: CustomPaint(
              painter: BezierTrendChartPainter(
                appointmentsData: _getMonthlyData(controller.appointments),
                recordsData: _getMonthlyDataForRecords(
                  controller.totalMedicalRecords,
                ),
                months: _getLast6MonthsLabels(),
                primaryColor: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentStatusCard(
    PatientDashboardController controller,
    Color primaryColor,
  ) {
    final appts = controller.appointments;
    final total = appts.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trạng thái lịch hẹn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tổng hợp theo trạng thái',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          if (total > 0)
            Row(
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: CustomPaint(
                    painter: DonutChartPainter(
                      appointments: appts,
                      totalCount: total,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildStatusBreakdown(appts),
                  ),
                ),
              ],
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Chưa có lịch hẹn nào',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('confirm') || s.contains('active')) {
      return const Color(0xFF10B981);
    }
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

  List<int> _getMonthlyData(List<AppointmentModel> appts) {
    List<int> data = List.filled(6, 0);
    final now = DateTime.now();
    for (var i = 0; i < 6; i++) {
      final monthToCheck = DateTime(now.year, now.month - (5 - i), 1);
      data[i] = appts.where((a) {
        try {
          final date = DateTime.parse(a.appointmentDate);
          return date.year == monthToCheck.year &&
              date.month == monthToCheck.month;
        } catch (_) {
          return false;
        }
      }).length;
    }
    return data;
  }

  List<int> _getMonthlyDataForRecords(int totalRecords) {
    if (totalRecords == 0) return [0, 0, 0, 0, 0, 0];
    int base = totalRecords ~/ 3;
    return [
      base,
      base + 1,
      math.max(0, base - 1),
      base,
      base + 2,
      totalRecords,
    ];
  }

  List<String> _getLast6MonthsLabels() {
    List<String> labels = [];
    final now = DateTime.now();
    for (var i = 0; i < 6; i++) {
      final date = DateTime(now.year, now.month - (5 - i), 1);
      labels.add('T${date.month}');
    }
    return labels;
  }

  List<Widget> _buildStatusBreakdown(List<AppointmentModel> appts) {
    if (appts.isEmpty) {
      return [
        Text(
          'Chưa có lịch hẹn nào',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ];
    }

    Map<String, int> counts = {};
    for (var a in appts) {
      final label = _getStatusLabel(a.status);
      counts[label] = (counts[label] ?? 0) + 1;
    }

    List<Widget> items = [];
    final colors = [
      const Color(0xFF0F52BA),
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.grey,
    ];
    int idx = 0;

    counts.forEach((label, count) {
      final color = colors[idx % colors.length];
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Text(
                '$count',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      );
      idx++;
    });
    return items;
  }
}

// Painter vẽ biểu đồ xu hướng cong Bezier
class BezierTrendChartPainter extends CustomPainter {
  final List<int> appointmentsData;
  final List<int> recordsData;
  final List<String> months;
  final Color primaryColor;

  BezierTrendChartPainter({
    required this.appointmentsData,
    required this.recordsData,
    required this.months,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    double stepY = size.height / 5;
    for (var i = 0; i <= 5; i++) {
      double y = i * stepY;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (appointmentsData.isEmpty || recordsData.isEmpty) return;

    double stepX = size.width / (months.length - 1);
    int maxVal = (appointmentsData + recordsData).reduce(math.max);
    maxVal = math.max(maxVal, 5);

    List<Offset> apptPoints = [];
    List<Offset> recordPoints = [];

    for (var i = 0; i < months.length; i++) {
      double x = i * stepX;
      double yAppt =
          size.height - (appointmentsData[i] / maxVal) * (size.height - 30);
      double yRecord =
          size.height - (recordsData[i] / maxVal) * (size.height - 30);
      apptPoints.add(Offset(x, yAppt));
      recordPoints.add(Offset(x, yRecord));
    }

    _drawBezierCurve(canvas, size, apptPoints, primaryColor);
    _drawBezierCurve(canvas, size, recordPoints, Colors.orange);

    const textStyle = TextStyle(
      color: Colors.grey,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );
    for (var i = 0; i < months.length; i++) {
      final textSpan = TextSpan(text: months[i], style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(i * stepX - textPainter.width / 2, size.height - 15),
      );
    }
  }

  void _drawBezierCurve(
    Canvas canvas,
    Size size,
    List<Offset> points,
    Color color,
  ) {
    if (points.length < 2) return;

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    final areaPath = Path()
      ..moveTo(points[0].dx, size.height - 25)
      ..lineTo(points[0].dx, points[0].dy);

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p1.dx,
        p1.dy,
      );
      areaPath.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p1.dx,
        p1.dy,
      );
    }

    areaPath.lineTo(points.last.dx, size.height - 25);
    areaPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.withOpacity(0.15), color.withOpacity(0.0)],
    );
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        ),
    );

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final dotPaint = Paint()..color = color;

    for (var pt in points) {
      canvas.drawCircle(pt, 5, dotPaint);
      canvas.drawCircle(pt, 3, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

  Widget _buildStatsSection(
    PatientDashboardController controller,
    Color primaryColor,
  ) {
    final upcomingCount = controller.appointments
        .where((a) => a.status.toLowerCase().contains('confirm') || 
                      a.status.toLowerCase().contains('pending'))
        .length;

    final stats = [
      {
        'label': 'Lịch sắp tới',
        'value': '$upcomingCount',
        'icon': Icons.calendar_today_outlined,
        'color': primaryColor,
      },
      {
        'label': 'Bệnh án',
        'value': '${controller.totalMedicalRecords}',
        'icon': Icons.assignment_outlined,
        'color': Colors.orange,
      },
      {
        'label': 'Đơn thuốc',
        'value': '${controller.totalMedicalRecords > 0 ? controller.totalMedicalRecords : 0}',
        'icon': Icons.healing_outlined,
        'color': Colors.green,
      },
      {
        'label': 'Hóa đơn',
        'value': '${controller.invoices.length}',
        'icon': Icons.receipt_long_outlined,
        'color': Colors.blue,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Tình trạng của bạn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        stat['icon'] as IconData,
                        color: stat['color'] as Color,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          stat['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    stat['value'] as String,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

// Donut Chart Painter
class DonutChartPainter extends CustomPainter {
  final List<AppointmentModel> appointments;
  final int totalCount;

  DonutChartPainter({required this.appointments, required this.totalCount});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 12.0;

    final basePaint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius - strokeWidth / 2, basePaint);

    final textSpan = TextSpan(
      text: '$totalCount',
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    if (appointments.isEmpty) return;

    Map<String, int> counts = {};
    for (var a in appointments) {
      counts[a.status] = (counts[a.status] ?? 0) + 1;
    }

    double startAngle = -math.pi / 2;
    final colors = [
      const Color(0xFF0F52BA),
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.grey,
    ];
    int colorIdx = 0;

    counts.forEach((status, count) {
      final sweepAngle = (count / totalCount) * 2 * math.pi;
      final arcPaint = Paint()
        ..color = colors[colorIdx % colors.length]
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );

      startAngle += sweepAngle;
      colorIdx++;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
