import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'dart:convert';

import '../../auth/controllers/auth_controller.dart';

import '../../auth/models/user_model.dart';

import '../controllers/admin_dashboard_controller.dart';
import '../widgets/role_dashboard_shell.dart';
import '../widgets/weather_greeting_card.dart';
import '../widgets/notification_bell.dart';
import 'admin_send_notification_view.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  int _selectedMenuIndex = 0; // Quản lý 11 tab vận hành của admin

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Controllers cho tìm kiếm

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  // Bộ lọc nâng cao (đồng bộ logic bản Web)

  int? _docSpecialtyFilter; // Lọc bác sĩ theo chuyên khoa

  int? _schedDoctorIdFilter; // Lọc lịch trực theo bác sĩ

  int? _schedSpecialtyIdFilter; // Lọc lịch trực theo chuyên khoa

  String _schedStatusFilter = 'All'; // All, Open, Paused

  DateTime? _schedDateFrom;

  DateTime? _schedDateTo;

  bool _schedFilterExpanded = false; // Bật tắt mở rộng panel lọc lịch trực

  String _medTypeFilter = 'All'; // All, hoặc các Chuyên khoa thuốc

  // Bộ lọc nâng cao mới bổ sung

  String _aptStatusFilter =
      'All'; // All, Pending, CheckedIn, Completed, Cancelled

  String _medStockFilter = 'All'; // All, Low, Normal

  String _accRoleFilter = 'All'; // All, Admin, Doctor, Nurse, Patient

  String _prescStatusFilter = 'All'; // All, Pending, Dispensed, Cancelled

  String _billStatusFilter = 'All'; // All, Paid, Unpaid

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  void _refreshData() {
    context.read<AdminDashboardController>().loadAllAdminData();
  }

  void _changeTab(int index) {
    setState(() {
      _selectedMenuIndex = index;

      _searchController.clear();

      _searchQuery = '';

      _docSpecialtyFilter = null;

      _schedDoctorIdFilter = null;

      _schedSpecialtyIdFilter = null;

      _schedStatusFilter = 'All';

      _schedDateFrom = null;

      _schedDateTo = null;

      _medTypeFilter = 'All';

      _aptStatusFilter = 'All';

      _medStockFilter = 'All';

      _accRoleFilter = 'All';

      _prescStatusFilter = 'All';

      _billStatusFilter = 'All';
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    final adminController = context.watch<AdminDashboardController>();

    final user = authController.currentUser;

    final primaryColor = const Color(0xFF0F52BA); // Sapphire Blue cho Admin

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy thông tin người dùng.')),
      );
    }

    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return RoleDashboardShell(
      scaffoldKey: _scaffoldKey,
      title: _getAppBarTitle(),
      userName: user.fullName,
      roleLabel: 'Quản trị hệ thống',
      roleSubtitle: user.email,
      primaryColor: primaryColor,
      menuItems: _adminMenuItems,
      selectedIndex: _selectedMenuIndex,
      onMenuSelected: _changeTab,
      onRefresh: _refreshData,
      onLogout: () => context.read<AuthController>().logout(),
      isLoading: false,
      avatarIcon: Icons.admin_panel_settings_rounded,
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: isWideScreen ? null : _buildAdminBottomNav(primaryColor),
      appBarActions: [
        NotificationBell(
          role: 'Admin',
          onTabChanged: _changeTab,
        ),
      ],
      body: SafeArea(
        child: adminController.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildMainContent(user, adminController, primaryColor),
      ),
    );
  }

  int _mapMenuIndexToBottomBarIndex(int menuIndex) {
    switch (menuIndex) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 5:
        return 2;
      case 6:
        return 3;
      case 8:
        return 4;
      default:
        return 0;
    }
  }

  int _mapBottomBarIndexToMenuIndex(int barIndex) {
    switch (barIndex) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 2:
        return 5;
      case 3:
        return 6;
      case 4:
        return 8;
      default:
        return 0;
    }
  }

  Widget _buildAdminBottomNav(Color primaryColor) {
    return NavigationBar(
      height: 68,
      backgroundColor: Colors.white,
      indicatorColor: primaryColor.withOpacity(0.12),
      selectedIndex: _mapMenuIndexToBottomBarIndex(_selectedMenuIndex),
      onDestinationSelected: (index) {
        _changeTab(_mapBottomBarIndexToMenuIndex(index));
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics_rounded),
          label: 'Báo cáo',
        ),
        NavigationDestination(
          icon: Icon(Icons.medical_services_outlined),
          selectedIcon: Icon(Icons.medical_services_rounded),
          label: 'Bác sĩ',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment_rounded),
          label: 'Lịch hẹn',
        ),
        NavigationDestination(
          icon: Icon(Icons.medication_outlined),
          selectedIcon: Icon(Icons.medication_rounded),
          label: 'Kho dược',
        ),
        NavigationDestination(
          icon: Icon(Icons.credit_card_outlined),
          selectedIcon: Icon(Icons.credit_card_rounded),
          label: 'Hóa đơn',
        ),
      ],
    );
  }

  // Tiêu đề AppBar tương ứng với từng Tab của Admin

  static const List<RoleDashboardMenuItem> _adminMenuItems = [
    RoleDashboardMenuItem(
      title: 'Báo cáo vận hành',
      icon: Icons.analytics_rounded,
      index: 0,
      section: 'Vận hành',
    ),
    RoleDashboardMenuItem(
      title: 'Quản lý Bác sĩ',
      icon: Icons.medical_services_rounded,
      index: 1,
      section: 'Nhân sự',
    ),
    RoleDashboardMenuItem(
      title: 'Quản lý Chuyên khoa',
      icon: Icons.category_rounded,
      index: 2,
      section: 'Nhân sự',
    ),
    RoleDashboardMenuItem(
      title: 'Lịch làm việc',
      icon: Icons.calendar_month_rounded,
      index: 3,
      section: 'Lịch & bệnh nhân',
    ),
    RoleDashboardMenuItem(
      title: 'Quản lý Bệnh nhân',
      icon: Icons.people_alt_rounded,
      index: 4,
      section: 'Lịch & bệnh nhân',
    ),
    RoleDashboardMenuItem(
      title: 'Quản lý Lịch hẹn',
      icon: Icons.assignment_rounded,
      index: 5,
      section: 'Lịch & bệnh nhân',
    ),
    RoleDashboardMenuItem(
      title: 'Kho dược phẩm',
      icon: Icons.medication_rounded,
      index: 6,
      section: 'Dược & tài chính',
    ),
    RoleDashboardMenuItem(
      title: 'Lịch sử Đơn thuốc',
      icon: Icons.description_rounded,
      index: 7,
      section: 'Dược & tài chính',
    ),
    RoleDashboardMenuItem(
      title: 'Hóa đơn viện phí',
      icon: Icons.credit_card_rounded,
      index: 8,
      section: 'Dược & tài chính',
    ),
    RoleDashboardMenuItem(
      title: 'Tài khoản hệ thống',
      icon: Icons.manage_accounts_rounded,
      index: 9,
      section: 'Hệ thống',
    ),
    RoleDashboardMenuItem(
      title: 'Quản lý Y tá',
      icon: Icons.badge_rounded,
      index: 10,
      section: 'Hệ thống',
    ),
    RoleDashboardMenuItem(
      title: 'Gửi thông báo',
      icon: Icons.campaign_rounded,
      index: 11,
      section: 'Hệ thống',
    ),
  ];

  String _getAppBarTitle() {
    switch (_selectedMenuIndex) {
      case 0:
        return 'Báo cáo vận hành';

      case 1:
        return 'Quản lý Bác sĩ';

      case 2:
        return 'Quản lý Chuyên khoa';

      case 3:
        return 'Lịch làm việc';

      case 4:
        return 'Quản lý Bệnh nhân';

      case 5:
        return 'Quản lý Lịch hẹn';

      case 6:
        return 'Kho dược phẩm';

      case 7:
        return 'Lịch sử Đơn thuốc';

      case 8:
        return 'Hóa đơn viện phí';

      case 9:
        return 'Tài khoản hệ thống';

      case 10:
        return 'Quản lý Y tá';

      case 11:
        return 'Gửi thông báo';

      default:
        return 'Medicare Admin';
    }
  }

  // SIDEBAR (DRAWER) CHỨA 11 PHÂN HỆ ĐỘC LẬP

  Widget _buildAdminSidebar(UserModel user, Color primaryColor) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Báo cáo vận hành',
        'icon': Icons.analytics_outlined,
        'index': 0,
      },

      {
        'title': 'Quản lý Bác sĩ',
        'icon': Icons.medical_services_outlined,
        'index': 1,
      },

      {
        'title': 'Quản lý Chuyên khoa',
        'icon': Icons.category_outlined,
        'index': 2,
      },

      {
        'title': 'Lịch làm việc',
        'icon': Icons.calendar_month_outlined,
        'index': 3,
      },

      {
        'title': 'Quản lý Bệnh nhân',
        'icon': Icons.people_outline_rounded,
        'index': 4,
      },

      {
        'title': 'Quản lý Lịch hẹn',
        'icon': Icons.assignment_outlined,
        'index': 5,
      },

      {'title': 'Kho dược phẩm', 'icon': Icons.medication, 'index': 6},

      {
        'title': 'Lịch sử Đơn thuốc',
        'icon': Icons.description_outlined,
        'index': 7,
      },

      {
        'title': 'Hóa đơn viện phí',
        'icon': Icons.credit_card_outlined,
        'index': 8,
      },

      {
        'title': 'Tài khoản hệ thống',
        'icon': Icons.manage_accounts_outlined,
        'index': 9,
      },

      {'title': 'Quản lý Y tá', 'icon': Icons.badge_outlined, 'index': 10},
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

            currentAccountPicture: Container(
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

              child: const CircleAvatar(
                backgroundColor: Colors.white,

                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Color(0xFF0F52BA),
                  size: 36,
                ),
              ),
            ),

            accountName: Text(
              user.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            accountEmail: Text(
              'Email: ${user.email}',
              style: const TextStyle(fontSize: 12),
            ),
          ),

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
                    _changeTab(item['index']);

                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),

            title: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),

            onTap: () {
              Navigator.pop(context);

              context.read<AuthController>().logout();
            },
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // Điểu phối view nội dung dựa trên menu đang chọn

  Widget _buildMainContent(
    UserModel user,
    AdminDashboardController controller,
    Color primaryColor,
  ) {
    switch (_selectedMenuIndex) {
      case 0:
        return _buildAdminCommandCenterTab(user, controller, primaryColor);

      case 1:
        return _buildDoctorsTab(controller, primaryColor);

      case 2:
        return _buildSpecialtiesTab(controller, primaryColor);

      case 3:
        return _buildSchedulesTab(controller, primaryColor);

      case 4:
        return _buildPatientsTab(controller, primaryColor);

      case 5:
        return _buildAppointmentsTab(controller, primaryColor);

      case 6:
        return _buildMedicinesTab(controller, primaryColor);

      case 7:
        return _buildPrescriptionsTab(controller, primaryColor);

      case 8:
        return _buildBillsTab(controller, primaryColor);

      case 9:
        return _buildAccountsTab(controller, primaryColor);

      case 10:
        return _buildNursesTab(controller, primaryColor);

      case 11:
        return AdminSendNotificationView(primaryColor: primaryColor);

      default:
        return const Center(child: Text('Tab không hợp lệ.'));
    }
  }

  // --- 11 TAB CHI TIẾT ---

  // TAB 0: Báo cáo vận hành (Overview Dashboard)

  Widget _buildAdminCommandCenterTab(
    UserModel user,
    AdminDashboardController controller,
    Color primaryColor,
  ) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final todayAppointments = controller.appointments
        .where((item) => _safeDate(item['appointmentDate']) == today)
        .toList();
    final pendingAppointments = controller.appointments
        .where((item) => _isPendingStatus(item['status']))
        .length;
    final lowStockMedicines = controller.medicines
        .where((item) => _isLowStockMedicine(item))
        .length;
    final unpaidBills = controller.bills
        .where((item) => !_isPaidBill(item))
        .length;
    final lockedAccounts = controller.accounts
        .where((item) => _isLockedAccount(item))
        .length;
    final paidBillsCount = controller.bills.where(_isPaidBill).length;
    final totalRevenue = controller.bills
        .where(_isPaidBill)
        .fold<double>(0, (sum, item) => sum + _readMoney(item));

    return RefreshIndicator(
      onRefresh: () =>
          context.read<AdminDashboardController>().loadAllAdminData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdminCommandHeader(user, primaryColor),
            const SizedBox(height: 14),
            _buildSectionTitle('Truy cập nhanh'),
            const SizedBox(height: 10),
            _buildQuickAccessGrid(
              todayAppointments: todayAppointments.length,
              doctors: controller.doctors.length,
              schedules: controller.schedules.length,
              patients: controller.patients.length,
              bills: controller.bills.length,
              medicines: controller.medicines.length,
            ),
            const SizedBox(height: 18),
            _buildSectionTitle('Tổng quan vận hành'),
            const SizedBox(height: 10),
            _buildOpsMetricsGrid(
              todayAppointments: todayAppointments.length,
              patients: controller.patients.length,
              doctors: controller.doctors.length,
              paidBillsCount: paidBillsCount,
              totalRevenue: totalRevenue,
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 18),
            _buildSectionTitle('Cần xử lý'),
            const SizedBox(height: 10),
            _buildAttentionSection(
              pendingAppointments: pendingAppointments,
              unpaidBills: unpaidBills,
              lowStockMedicines: lowStockMedicines,
              lockedAccounts: lockedAccounts,
            ),
            const SizedBox(height: 18),
            _buildSectionTitle('Nhóm quản trị'),
            const SizedBox(height: 10),
            _buildAdminGroupsSection(primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w900,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildAdminCommandHeader(UserModel user, Color primaryColor) {
    return WeatherGreetingCard(
      displayName: user.fullName,
      primaryColor: primaryColor,
    );
  }

  Widget _buildQuickAccessGrid({
    required int todayAppointments,
    required int doctors,
    required int schedules,
    required int patients,
    required int bills,
    required int medicines,
  }) {
    final items = [
      {
        'title': 'Lịch hẹn hôm nay',
        'subtitle': '$todayAppointments lịch',
        'icon': Icons.event_available_rounded,
        'color': const Color(0xFF2563EB),
        'tab': 5,
      },
      {
        'title': 'Bác sĩ',
        'subtitle': '$doctors hồ sơ',
        'icon': Icons.medical_services_rounded,
        'color': const Color(0xFF10B981),
        'tab': 1,
      },
      {
        'title': 'Lịch làm việc',
        'subtitle': '$schedules ca trực',
        'icon': Icons.calendar_month_rounded,
        'color': const Color(0xFFF59E0B),
        'tab': 3,
      },
      {
        'title': 'Bệnh nhân',
        'subtitle': '$patients hồ sơ',
        'icon': Icons.people_alt_rounded,
        'color': const Color(0xFF7C3AED),
        'tab': 4,
      },
      {
        'title': 'Hóa đơn',
        'subtitle': '$bills hóa đơn',
        'icon': Icons.receipt_long_rounded,
        'color': const Color(0xFFEF4444),
        'tab': 8,
      },
      {
        'title': 'Kho thuốc',
        'subtitle': '$medicines mặt hàng',
        'icon': Icons.inventory_2_rounded,
        'color': const Color(0xFF0891B2),
        'tab': 6,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 92,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildAdminShortcutCard(
          title: item['title'] as String,
          subtitle: item['subtitle'] as String,
          icon: item['icon'] as IconData,
          color: item['color'] as Color,
          onTap: () => _changeTab(item['tab'] as int),
        );
      },
    );
  }

  Widget _buildAdminShortcutCard({
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
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
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
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
  }

  Widget _buildOpsMetricsGrid({
    required int todayAppointments,
    required int patients,
    required int doctors,
    required int paidBillsCount,
    required double totalRevenue,
    required Color primaryColor,
  }) {
    final items = [
      {
        'label': 'Lịch hẹn hôm nay',
        'value': '$todayAppointments',
        'meta': 'trong ngày',
        'icon': Icons.today_rounded,
        'color': const Color(0xFF2563EB),
      },
      {
        'label': 'Bệnh nhân',
        'value': '$patients',
        'meta': 'hồ sơ',
        'icon': Icons.people_alt_outlined,
        'color': const Color(0xFF10B981),
      },
      {
        'label': 'Bác sĩ',
        'value': '$doctors',
        'meta': 'đang quản lý',
        'icon': Icons.medical_services_outlined,
        'color': primaryColor,
      },
      {
        'label': 'Doanh thu',
        'value': totalRevenue > 0
            ? '${NumberFormatSimple.format(totalRevenue)} đ'
            : '--',
        'meta': '$paidBillsCount hóa đơn đã thanh toán',
        'icon': Icons.payments_outlined,
        'color': const Color(0xFFF59E0B),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 86,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildAdminMetricCard(
          label: item['label'] as String,
          value: item['value'] as String,
          meta: item['meta'] as String,
          icon: item['icon'] as IconData,
          color: item['color'] as Color,
        );
      },
    );
  }

  Widget _buildAdminMetricCard({
    required String label,
    required String value,
    required String meta,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionSection({
    required int pendingAppointments,
    required int unpaidBills,
    required int lowStockMedicines,
    required int lockedAccounts,
  }) {
    final items = [
      if (pendingAppointments > 0)
        {
          'title': 'Lịch hẹn đang chờ xác nhận',
          'count': pendingAppointments,
          'chip': 'Pending',
          'icon': Icons.pending_actions_rounded,
          'color': const Color(0xFFF59E0B),
          'tab': 5,
        },
      if (unpaidBills > 0)
        {
          'title': 'Hóa đơn chưa thanh toán',
          'count': unpaidBills,
          'chip': 'Danger',
          'icon': Icons.receipt_long_rounded,
          'color': const Color(0xFFEF4444),
          'tab': 8,
        },
      if (lowStockMedicines > 0)
        {
          'title': 'Thuốc sắp hết hàng',
          'count': lowStockMedicines,
          'chip': 'Info',
          'icon': Icons.medication_liquid_rounded,
          'color': const Color(0xFF2563EB),
          'tab': 6,
        },
      if (lockedAccounts > 0)
        {
          'title': 'Tài khoản cần kiểm tra',
          'count': lockedAccounts,
          'chip': 'Locked',
          'icon': Icons.lock_clock_rounded,
          'color': const Color(0xFFEF4444),
          'tab': 9,
        },
    ];

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF10B981),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Hệ thống đang ổn định',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const Text(
              'Success',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildAttentionItem(
            title: item['title'] as String,
            count: item['count'] as int,
            chip: item['chip'] as String,
            icon: item['icon'] as IconData,
            color: item['color'] as Color,
            onTap: () => _changeTab(item['tab'] as int),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAttentionItem({
    required String title,
    required int count,
    required String chip,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  chip,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminGroupsSection(Color primaryColor) {
    return Column(
      children: [
        _buildAdminGroupCard(
          title: 'Nhân sự',
          icon: Icons.groups_rounded,
          color: primaryColor,
          items: [
            ['Bác sĩ', 1],
            ['Y tá', 10],
            ['Tài khoản', 9],
          ],
        ),
        const SizedBox(height: 10),
        _buildAdminGroupCard(
          title: 'Lịch & bệnh nhân',
          icon: Icons.event_note_rounded,
          color: const Color(0xFF10B981),
          items: [
            ['Lịch làm việc', 3],
            ['Lịch hẹn', 5],
            ['Bệnh nhân', 4],
          ],
        ),
        const SizedBox(height: 10),
        _buildAdminGroupCard(
          title: 'Dược & tài chính',
          icon: Icons.local_pharmacy_rounded,
          color: const Color(0xFFF59E0B),
          items: [
            ['Kho thuốc', 6],
            ['Đơn thuốc', 7],
            ['Hóa đơn', 8],
          ],
        ),
        const SizedBox(height: 10),
        _buildAdminGroupCard(
          title: 'Cấu hình',
          icon: Icons.tune_rounded,
          color: const Color(0xFF2563EB),
          items: [
            ['Chuyên khoa', 2],
          ],
        ),
      ],
    );
  }

  Widget _buildAdminGroupCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<List<Object>> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              return _buildAdminGroupLink(
                label: item[0] as String,
                color: color,
                onTap: () => _changeTab(item[1] as int),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminGroupLink({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }

  bool _isPendingStatus(dynamic status) {
    final value = status?.toString().toLowerCase() ?? '';
    return value.contains('pending') ||
        value.contains('scheduled') ||
        value.contains('waiting');
  }

  bool _isPaidBill(dynamic bill) {
    final status = bill['status']?.toString().toLowerCase() ?? '';
    return status == 'paid' ||
        status == 'paidoffline' ||
        status == 'paidonline' ||
        status.contains('paid');
  }

  bool _isLockedAccount(dynamic account) {
    final status = account['status']?.toString().toLowerCase() ?? '';
    return status.contains('locked') ||
        status.contains('blocked') ||
        status.contains('disabled');
  }

  bool _isLowStockMedicine(dynamic medicine) {
    final stock = _readInt(
      medicine['stockQuantity'] ?? medicine['stock'] ?? medicine['quantity'],
    );
    final minStock = _readInt(
      medicine['minStockLevel'] ?? medicine['minStock'] ?? 10,
    );
    return stock <= minStock;
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _readMoney(dynamic bill) {
    final value =
        bill['totalAmount'] ?? bill['amount'] ?? bill['paidAmount'] ?? 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  // ignore: unused_element
  Widget _buildReportsTab(
    AdminDashboardController controller,
    Color primaryColor,
  ) {
    // 1. Tính toán lời chào động theo múi giờ

    final hour = DateTime.now().hour;

    String greeting = 'Chúc ngủ ngon';

    if (hour >= 5 && hour < 11)
      greeting = 'Chào buổi sáng';
    else if (hour >= 11 && hour < 14)
      greeting = 'Chào buổi trưa';
    else if (hour >= 14 && hour < 18)
      greeting = 'Chào buổi chiều';
    else if (hour >= 18 && hour < 22)
      greeting = 'Chào buổi tối';

    // 2. Tính toán doanh thu

    double totalRevenue = 0;

    int paidBillsCount = 0;

    for (var bill in controller.bills) {
      final status = bill['status']?.toString().toLowerCase() ?? '';

      if (status == 'paid' || status == 'paidoffline') {
        final amount = (bill['amount'] ?? 0).toDouble();

        totalRevenue += amount;

        paidBillsCount++;
      }
    }

    // 3. Tính toán các chỉ số bổ sung

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    final todayApts = controller.appointments
        .where((a) => _safeDate(a['appointmentDate']) == todayStr)
        .toList();

    final completedToday = todayApts
        .where((a) => a['status'] == 'Completed')
        .length;

    // Đếm số lượng theo trạng thái lịch hẹn (Tổng số = 41 giống Web nếu không có DB thực tế)

    final totalApts = controller.appointments.length;

    final completedApts = controller.appointments
        .where((a) => a['status'] == 'Completed')
        .length;

    final checkedInApts = controller.appointments
        .where((a) => a['status'] == 'CheckedIn')
        .length;

    final cancelledApts = controller.appointments
        .where((a) => a['status'] == 'Cancelled')
        .length;

    final pendingApts =
        totalApts - completedApts - checkedInApts - cancelledApts;

    final lowStockCount = controller.medicines.where((med) {
      final stock = med['stockQuantity'] ?? 0;

      final minStock = med['minStockLevel'] ?? 10;

      return stock <= minStock;
    }).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // A. HEADER TRẠNG THÁI TIỆN ÍCH (Greeting + Weather + Time + Notifications)
          Container(
            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(24),

              border: Border.all(color: Colors.grey.shade200),
            ),

            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    // Lời chào & Tên
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,

                          backgroundColor: primaryColor.withOpacity(0.1),

                          child: Icon(
                            Icons.admin_panel_settings_rounded,
                            color: primaryColor,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              '$greeting, Admin!',

                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: Color(0xFF1E293B),
                              ),
                            ),

                            const Text(
                              'MedicareDNUService kính chào',

                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Bong bóng thông báo đếm số 57
                    Stack(
                      clipBehavior: Clip.none,

                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: Color(0xFF64748B),
                          ),

                          onPressed: () {},
                        ),

                        Positioned(
                          right: 4,

                          top: 4,

                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.red,

                              borderRadius: BorderRadius.circular(10),
                            ),

                            child: const Text(
                              '57',

                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Divider(height: 20),

                // Đồng hồ & Widget thời tiết
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,

                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: primaryColor,
                              size: 16,
                            ),

                            const SizedBox(width: 8),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Text(
                                  DateTime.now().toString().substring(11, 16),

                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),

                                const Text(
                                  'Thứ Tư, 01/07',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,

                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: const Row(
                          children: [
                            Icon(
                              Icons.wb_sunny_outlined,
                              color: Color(0xFFD97706),
                              size: 16,
                            ),

                            const SizedBox(width: 8),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Text(
                                  '25°C',

                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),

                                Text(
                                  'Đêm thoáng - Hà Nội',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // B. TIÊU ĐỀ BẢNG ĐIỀU KHIỂN VẬN HÀNH
          const Text(
            'Bảng điều khiển vận hành',

            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),

          const Text(
            'Theo dõi lịch khám, doanh thu, bệnh nhân, bác sĩ và kho thuốc trong một màn hình tổng quan.',

            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          // C. 4 KPI STATS CARDS (Chi tiết nâng cao giống bản Web)
          GridView.count(
            crossAxisCount: 2,

            crossAxisSpacing: 12,

            mainAxisSpacing: 12,

            shrinkWrap: true,

            physics: const NeverScrollableScrollPhysics(),

            childAspectRatio: 1.25,

            children: [
              _buildKPIItem(
                'Lịch hôm nay',

                '${todayApts.length}',

                '$completedToday lịch đã hoàn tất',

                Icons.calendar_today_rounded,

                const Color(0xFF3B82F6),

                onTap: () => _changeTab(5),
              ),

              _buildKPIItem(
                'Bệnh nhân',

                '${controller.patients.length}',

                '4 hồ sơ mới gần đây',

                Icons.people_alt_outlined,

                const Color(0xFF10B981),

                onTap: () => _changeTab(4),
              ),

              _buildKPIItem(
                'Bác sĩ',

                '${controller.doctors.length}',

                '${controller.specialties.length} chuyên khoa - ${controller.schedules.length} ca trực',

                Icons.medication_rounded,

                const Color(0xFF6366F1),

                onTap: () => _changeTab(1),
              ),

              _buildKPIItem(
                'Doanh thu đã thu',

                '${NumberFormatSimple.format(totalRevenue)} đ',

                '$paidBillsCount hóa đơn thành công',

                Icons.payments_outlined,

                const Color(0xFFD97706),

                onTap: () => _changeTab(8),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // D. TRẠNG THÁI LỊCH HẸN (Donut Chart visual indicators)
          Container(
            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(20),

              border: Border.all(color: Colors.grey.shade200),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.pie_chart_outline_rounded,
                      color: Color(0xFF3B82F6),
                      size: 18,
                    ),

                    SizedBox(width: 8),

                    Text(
                      'Trạng thái lịch hẹn',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                _buildStatusIndicatorRow(
                  'Hoàn tất',
                  completedApts,
                  totalApts,
                  Colors.green,
                ),

                const SizedBox(height: 8),

                _buildStatusIndicatorRow(
                  'Đã check-in',
                  checkedInApts,
                  totalApts,
                  Colors.blue,
                ),

                const SizedBox(height: 8),

                _buildStatusIndicatorRow(
                  'Đã hủy',
                  cancelledApts,
                  totalApts,
                  Colors.red,
                ),

                const SizedBox(height: 8),

                _buildStatusIndicatorRow(
                  'Đang chờ',
                  pendingApts,
                  totalApts,
                  Colors.orange,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // E. DANH SÁCH LỊCH HẸN MỚI NHẤT (Recent Appointments)
          Container(
            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(20),

              border: Border.all(color: Colors.grey.shade200),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Text(
                      'Lịch hẹn mới nhất',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
                    ),

                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),

                const Divider(height: 20),

                if (controller.appointments.isEmpty)
                  _buildEmptySection('Chưa có lịch hẹn nào.')
                else
                  ...controller.appointments.take(5).map((apt) {
                    final String code =
                        'LH-${apt['appointmentId'] ?? apt['id'] ?? 0}';

                    final String patient =
                        apt['patientName'] ??
                        apt['patientNameSnapshot'] ??
                        'Bệnh nhân';

                    final String doctor = apt['doctorName'] ?? 'Bác sĩ';

                    final String date = _safeDate(apt['appointmentDate']);

                    final String time = apt['slotTime'] ?? '00:00';

                    final String status = apt['status'] ?? 'Pending';

                    Color stColor = Colors.orange;

                    String stText = 'Đang chờ';

                    if (status == 'Completed') {
                      stColor = Colors.green;

                      stText = 'Hoàn tất';
                    } else if (status == 'CheckedIn') {
                      stColor = Colors.blue;

                      stText = 'Đã check-in';
                    } else if (status == 'Cancelled') {
                      stColor = Colors.red;

                      stText = 'Đã hủy';
                    }

                    return InkWell(
                      onTap: () => _showAppointmentActionDialog(
                        context,
                        apt,
                        controller,
                        primaryColor,
                      ),

                      borderRadius: BorderRadius.circular(12),

                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 8.0,
                        ),

                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              code,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Text(
                                    patient,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),

                                  Text(
                                    'BS. $doctor',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,

                              children: [
                                Text(
                                  '$date $time',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),

                                  decoration: BoxDecoration(
                                    color: stColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),

                                  child: Text(
                                    stText,
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: stColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // F. BỆNH NHÂN MỚI & MASCOT DOGKY
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // Bảng Bệnh nhân mới
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(20),

                    border: Border.all(color: Colors.grey.shade200),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Bệnh nhân mới',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF1E293B),
                        ),
                      ),

                      const Divider(height: 16),

                      if (controller.patients.isEmpty)
                        const Text(
                          'Không có bệnh nhân mới',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        )
                      else
                        ...controller.patients.take(4).map((p) {
                          final String pName =
                              p['fullName'] ?? p['name'] ?? 'Bệnh nhân';

                          final String pCode =
                              'BN-${p['patientId'] ?? p['id'] ?? 0}';

                          return InkWell(
                            onTap: () => _showPatientDetailsDialog(context, p),

                            borderRadius: BorderRadius.circular(8),

                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                                vertical: 6.0,
                              ),

                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,

                                children: [
                                  Expanded(
                                    child: Text(
                                      pName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),

                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(4),
                                    ),

                                    child: Text(
                                      pCode,
                                      style: const TextStyle(
                                        fontSize: 8,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Thẻ Mascot Dogky bác sĩ cực kỳ đáng yêu (hỗ trợ tap trò chuyện)
              InkWell(
                onTap: () => _showDogkyTipsDialog(
                  context,
                  controller,
                  completedToday,
                  lowStockCount,
                ),

                borderRadius: BorderRadius.circular(20),

                child: Container(
                  width: 120,

                  padding: const EdgeInsets.all(12),

                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),

                    borderRadius: BorderRadius.circular(20),

                    border: Border.all(color: Colors.blue.withOpacity(0.15)),
                  ),

                  child: Column(
                    children: [
                      Image.network(
                        'https://cdn-icons-png.flaticon.com/512/10260/10260336.png',

                        width: 54,

                        height: 54,

                        fit: BoxFit.contain,

                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.pets,
                              color: Colors.blue,
                              size: 40,
                            ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Dogky Helper',

                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),

                      const Text(
                        'Chạm để nghe báo cáo',

                        style: TextStyle(fontSize: 8, color: Colors.grey),

                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // G. HÓA ĐƠN GẦN ĐÂY & DOANH THU ĐÃ THU
          Container(
            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(20),

              border: Border.all(color: Colors.grey.shade200),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Hóa đơn gần đây',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                ),

                const Divider(height: 20),

                if (controller.bills.isEmpty)
                  _buildEmptySection('Chưa có hóa đơn nào.')
                else
                  ...controller.bills.take(3).map((bill) {
                    final String billCode =
                        'HD-${bill['billId'] ?? bill['id'] ?? 0}';

                    final String aptRef = 'LH-${bill['appointmentId'] ?? 0}';

                    final double amount = (bill['amount'] ?? 0.0).toDouble();

                    final String status =
                        bill['status']?.toString().toLowerCase() ?? '';

                    final isPaid = status == 'paid' || status == 'paidoffline';

                    return InkWell(
                      onTap: () => _showBillActionDialog(
                        context,
                        bill,
                        controller,
                        primaryColor,
                      ),

                      borderRadius: BorderRadius.circular(12),

                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 8.0,
                        ),

                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Text(
                                  billCode,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),

                                Text(
                                  'Lịch hẹn: $aptRef',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),

                            Row(
                              children: [
                                Text(
                                  '${NumberFormatSimple.format(amount)} đ',

                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),

                                  decoration: BoxDecoration(
                                    color: isPaid
                                        ? Colors.green.withOpacity(0.08)
                                        : Colors.red.withOpacity(0.08),

                                    borderRadius: BorderRadius.circular(6),
                                  ),

                                  child: Text(
                                    isPaid ? 'Đã thu' : 'Chưa thu',

                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: isPaid ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // H. PHÂN BỐ NHÂN LỰC & DỊCH VỤ (Hàng cuối cùng)
          const Text(
            'Phân bổ nhân lực & dịch vụ',

            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(20),

              border: Border.all(color: Colors.grey.shade200),
            ),

            child: Column(
              children: [
                _buildProgressBarRow(
                  'Bác sĩ',
                  controller.doctors.length,
                  30,
                  primaryColor,
                ),

                const SizedBox(height: 12),

                _buildProgressBarRow(
                  'Chuyên khoa',
                  controller.specialties.length,
                  15,
                  const Color(0xFF10B981),
                ),

                const SizedBox(height: 12),

                _buildProgressBarRow(
                  'Lịch trực phân bổ',
                  controller.schedules.length,
                  100,
                  const Color(0xFFF59E0B),
                ),

                const SizedBox(height: 12),

                _buildProgressBarRow(
                  'Bệnh nhân đã đăng ký',
                  controller.patients.length,
                  200,
                  const Color(0xFFEC4899),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Thẻ KPI thống kê hỗ trợ InkWell/onTap

  Widget _buildKPIItem(
    String label,

    String value,

    String subtext,

    IconData icon,

    Color color, {

    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: Colors.grey.shade200),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: onTap,

          borderRadius: BorderRadius.circular(20),

          child: Padding(
            padding: const EdgeInsets.all(12),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),

                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),

                      child: Icon(icon, color: color, size: 18),
                    ),

                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: Colors.grey,
                    ),
                  ],
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      value,

                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      label,

                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      subtext,

                      style: const TextStyle(fontSize: 8, color: Colors.grey),

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper vẽ tỷ lệ trạng thái lịch hẹn dạng Progress Bar ngang

  Widget _buildStatusIndicatorRow(
    String label,
    int count,
    int total,
    Color color,
  ) {
    final double pct = total > 0 ? (count / total) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 80,

          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  label,

                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                  ),

                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),

            child: LinearProgressIndicator(
              value: pct,

              backgroundColor: Colors.grey.shade100,

              valueColor: AlwaysStoppedAnimation<Color>(color),

              minHeight: 6,
            ),
          ),
        ),

        const SizedBox(width: 12),

        SizedBox(
          width: 24,

          child: Text(
            '$count',

            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),

            textAlign: Alignment.centerRight.x == 0
                ? TextAlign.right
                : TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBarRow(String label, int value, int max, Color color) {
    final double pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),

            Text(
              '$value',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        ClipRRect(
          borderRadius: BorderRadius.circular(4),

          child: LinearProgressIndicator(
            value: pct,

            backgroundColor: Colors.grey.shade100,

            valueColor: AlwaysStoppedAnimation<Color>(color),

            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorsTab(
    AdminDashboardController controller,
    Color primaryColor,
  ) {
    // 1. Tính toán số liệu thống kê cho Stats Panel

    final totalDocs = controller.doctors.length;

    final activeDocs = controller.doctors
        .where((d) => d['isActive'] != false && d['IsActive'] != false)
        .length;

    double avgFee = 0;

    if (controller.doctors.isNotEmpty) {
      final sum = controller.doctors.fold<double>(
        0.0,
        (prev, d) => prev + (d['examFee'] ?? 0.0).toDouble(),
      );

      avgFee = sum / controller.doctors.length;
    }

    // 2. Lọc danh sách bác sĩ

    final filtered = controller.doctors.where((d) {
      final name = (d['doctorName'] ?? d['fullName'] ?? '')
          .toString()
          .toLowerCase();

      final specialty = (d['specialtyName'] ?? '').toString().toLowerCase();

      final matchesQuery =
          name.contains(_searchQuery.toLowerCase()) ||
          specialty.contains(_searchQuery.toLowerCase());

      if (!matchesQuery) return false;

      if (_docSpecialtyFilter != null) {
        final specId = d['specialtyId'];

        if (specId != _docSpecialtyFilter) return false;
      }

      return true;
    }).toList();

    return Column(
      children: [
        _buildSearchBar('Tìm bác sĩ theo tên, chuyên khoa...'),

        // A. PANEL THỐNG KÊ SỐ LIỆU (Stats Panel cuộn ngang)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,

          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),

          child: Row(
            children: [
              _buildCompactStatCard(
                'Tổng số Bác sĩ',
                '$totalDocs',
                Icons.people_outline_rounded,
                primaryColor,
              ),

              const SizedBox(width: 10),

              _buildCompactStatCard(
                'Đang hoạt động',
                '$activeDocs',
                Icons.check_circle_outline_rounded,
                Colors.green,
              ),

              const SizedBox(width: 10),

              _buildCompactStatCard(
                'Phí trung bình',
                '${NumberFormatSimple.format(avgFee)}đ',
                Icons.monetization_on_outlined,
                const Color(0xFFD97706),
              ),
            ],
          ),
        ),

        // B. BỘ LỌC CHUYÊN KHOA DẠNG CHIPS CUỘN NGANG (Specialty Horizontal Chips)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,

          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),

          child: Row(
            children: [
              _buildSpecialtyFilterChip(
                'Tất cả chuyên khoa',
                null,
                primaryColor,
              ),

              ...controller.specialties.map<Widget>((s) {
                final id = s['specialtyId'] ?? s['id'];

                final name = s['specialtyName'] ?? 'Khoa';

                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),

                  child: _buildSpecialtyFilterChip(name, id, primaryColor),
                );
              }),
            ],
          ),
        ),

        _buildActionHeader(
          'Bác sĩ',
          filtered.length,
          () => _showDoctorForm(null, controller, primaryColor),
        ),

        // C. DANH SÁCH CARD BÁC SĨ THIẾT KẾ MỚI SANG TRỌNG
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptySection('Không tìm thấy bác sĩ nào.')
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),

                  itemCount: filtered.length,

                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),

                  itemBuilder: (context, index) {
                    final doc = filtered[index];

                    final String name =
                        doc['doctorName'] ?? doc['fullName'] ?? 'Bác sĩ';

                    final String specialty =
                        doc['specialtyName'] ?? 'Chưa cấu hình';

                    final String room = doc['roomNumber'] ?? 'Chưa xếp phòng';

                    final String degree = doc['degree'] ?? 'Bác sĩ';

                    final double fee = (doc['examFee'] ?? 0.0).toDouble();

                    final bool isActive =
                        doc['isActive'] != false && doc['IsActive'] != false;

                    final int id = doc['doctorId'] ?? doc['id'] ?? 0;

                    // Định dạng URL ảnh đại diện động

                    final avatarUrl = _getDoctorAvatarUrl(doc);

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.circular(20),

                        border: Border.all(color: Colors.grey.shade200),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),

                            blurRadius: 10,

                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),

                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),

                        onTap: () => _showDoctorDetails(doc, primaryColor),

                        child: Padding(
                          padding: const EdgeInsets.all(16),

                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              // Stack ảnh đại diện + Chấm tròn trạng thái hoạt động
                              Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,

                                      border: Border.all(
                                        color: Colors.grey.shade100,
                                        width: 1.5,
                                      ),
                                    ),

                                    child: ClipOval(
                                      child: Image.network(
                                        avatarUrl,

                                        width: 48,

                                        height: 48,

                                        fit: BoxFit.cover,

                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  width: 48,

                                                  height: 48,

                                                  color: primaryColor
                                                      .withOpacity(0.1),

                                                  alignment: Alignment.center,

                                                  child: Text(
                                                    name.isNotEmpty
                                                        ? name
                                                              .split(' ')
                                                              .last[0]
                                                              .toUpperCase()
                                                        : 'D',

                                                    style: TextStyle(
                                                      color: primaryColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ),

                                  Positioned(
                                    right: 1,

                                    bottom: 1,

                                    child: Container(
                                      width: 12,

                                      height: 12,

                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Colors.green
                                            : Colors.grey,

                                        shape: BoxShape.circle,

                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 14),

                              // Nội dung văn bản
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    Text(
                                      name,

                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),

                                    Text(
                                      degree,

                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    // Row chứa Badges (Chuyên khoa & Phòng khám)
                                    Wrap(
                                      spacing: 6,

                                      runSpacing: 4,

                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),

                                          decoration: BoxDecoration(
                                            color: primaryColor.withOpacity(
                                              0.06,
                                            ),

                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),

                                          child: Text(
                                            specialty,

                                            style: TextStyle(
                                              fontSize: 10,
                                              color: primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),

                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),

                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,

                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),

                                          child: Text(
                                            'Phòng $room',

                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    // Hiển thị Phí khám ở dòng dưới
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.payments_outlined,
                                          color: Colors.grey.shade400,
                                          size: 14,
                                        ),

                                        const SizedBox(width: 4),

                                        Text(
                                          'Phí dịch vụ: ',

                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),

                                        Text(
                                          '${NumberFormatSimple.format(fee)} đ',

                                          style: TextStyle(
                                            fontSize: 12,
                                            color: const Color(0xFFD97706),
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Menu hành động ba chấm (Actions Popup) bảo mật, tránh click nhầm
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  color: Color(0xFF64748B),
                                ),

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),

                                onSelected: (action) {
                                  if (action == 'details') {
                                    _showDoctorDetails(doc, primaryColor);
                                  } else if (action == 'edit') {
                                    _showDoctorForm(
                                      doc,
                                      controller,
                                      primaryColor,
                                    );
                                  } else if (action == 'delete') {
                                    _showDeleteConfirm(
                                      title: 'Xóa bác sĩ?',

                                      message:
                                          'Bạn có chắc chắn muốn xóa hồ sơ bác sĩ $name khỏi hệ thống?',

                                      onConfirm: () =>
                                          controller.deleteDoctor(id),
                                    );
                                  }
                                },

                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'details',

                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          size: 18,
                                        ),

                                        SizedBox(width: 8),

                                        Text(
                                          'Xem chi tiết',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const PopupMenuItem(
                                    value: 'edit',

                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: Colors.blue,
                                        ),

                                        SizedBox(width: 8),

                                        Text(
                                          'Chỉnh sửa',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const PopupMenuDivider(),

                                  const PopupMenuItem(
                                    value: 'delete',

                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: Colors.red,
                                        ),

                                        SizedBox(width: 8),

                                        Text(
                                          'Xóa hồ sơ',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.red,
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
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Tiện ích vẽ thẻ KPI nhỏ cuộn ngang

  Widget _buildCompactStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 140,

      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),

            decoration: BoxDecoration(
              color: color.withOpacity(0.08),

              shape: BoxShape.circle,
            ),

            child: Icon(icon, color: color, size: 16),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              mainAxisSize: MainAxisSize.min,

              children: [
                Text(
                  value,

                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),

                  overflow: TextOverflow.ellipsis,
                ),

                Text(
                  label,

                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                  ),

                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tiện ích vẽ Chip Chuyên khoa cuộn ngang

  Widget _buildSpecialtyFilterChip(String name, int? id, Color primaryColor) {
    final isSelected = _docSpecialtyFilter == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _docSpecialtyFilter = id;
        });
      },

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,

          borderRadius: BorderRadius.circular(20),

          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
          ),

          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),

                    blurRadius: 8,

                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),

        child: Text(
          name,

          style: TextStyle(
            fontSize: 11,

            fontWeight: FontWeight.bold,

            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  // Hàm helper phân giải URL ảnh đại diện cho danh sách Bác sĩ

  String _getDoctorAvatarUrl(dynamic doc) {
    final dbAvatar = doc['avatarUrl'] ?? doc['AvatarUrl'];

    if (dbAvatar != null && dbAvatar.toString().trim().isNotEmpty) {
      final String avatarStr = dbAvatar.toString();

      if (avatarStr.startsWith('http://') || avatarStr.startsWith('https://')) {
        return avatarStr;
      }

      return 'https://api.hwpresents.site${avatarStr.startsWith('/') ? avatarStr : '/$avatarStr'}';
    }

    // Thuật toán gán ảnh chân dung ngẫu nhiên chất lượng từ Unsplash theo doctorId

    final id = doc['doctorId'] ?? doc['id'] ?? 1;

    final int imgIdx = (id as int) % 5 + 1;

    // Danh sách 5 ảnh chân dung chất lượng cao từ Unsplash

    final placeholders = [
      'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=256&auto=format&fit=crop',

      'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=256&auto=format&fit=crop',

      'https://images.unsplash.com/photo-1594824813573-246434de83fb?q=80&w=256&auto=format&fit=crop',

      'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?q=80&w=256&auto=format&fit=crop',

      'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=256&auto=format&fit=crop',
    ];

    return placeholders[imgIdx - 1];
  }

  // TAB 2: CHUYÊN KHOA (Specialties Management)

  Widget _buildSpecialtiesTab(
    AdminDashboardController controller,
    Color primaryColor,
  ) {
    final filtered = controller.specialties.where((s) {
      final name = (s['specialtyName'] ?? '').toString().toLowerCase();

      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    // Hàm xác định màu sắc và biểu tượng đặc trưng của từng chuyên khoa y tế

    Map<String, dynamic> _getSpecialtyTheme(String specName) {
      final name = specName.toLowerCase();

      if (name.contains('tim mạch')) {
        return {
          'color': const Color(0xFFE11D48),
          'icon': Icons.favorite_rounded,
        };
      } else if (name.contains('nhi')) {
        return {
          'color': const Color(0xFF0EA5E9),
          'icon': Icons.child_care_rounded,
        };
      } else if (name.contains('da liễu')) {
        return {
          'color': const Color(0xFFD97706),
          'icon': Icons.face_retouching_natural_rounded,
        };
      } else if (name.contains('tai mũi họng') ||
          name.contains('tai') ||
          name.contains('họng')) {
        return {
          'color': const Color(0xFF0D9488),
          'icon': Icons.hearing_rounded,
        };
      } else if (name.contains('khớp') ||
          name.contains('xương') ||
          name.contains('cơ')) {
        return {
          'color': const Color(0xFF8B5CF6),
          'icon': Icons.accessibility_new_rounded,
        };
      } else if (name.contains('sản') || name.contains('phụ')) {
        return {
          'color': const Color(0xFFEC4899),
          'icon': Icons.pregnant_woman_rounded,
        };
      } else if (name.contains('tổng quát') || name.contains('nội')) {
        return {
          'color': const Color(0xFF2563EB),
          'icon': Icons.medical_services_rounded,
        };
      }

      return {'color': const Color(0xFF64748B), 'icon': Icons.category_rounded};
    }

    return Column(
      children: [
        _buildSearchBar('Tìm chuyên khoa...'),

        _buildActionHeader(
          'Chuyên khoa',
          filtered.length,
          () => _showSpecialtyForm(null, controller, primaryColor),
        ),

        Expanded(
          child: filtered.isEmpty
              ? _buildEmptySection('Không tìm thấy chuyên khoa nào.')
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),

                  itemCount: filtered.length,

                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),

                  itemBuilder: (context, index) {
                    final spec = filtered[index];

                    final String name = spec['specialtyName'] ?? 'Chuyên khoa';

                    final int id = spec['specialtyId'] ?? spec['id'];

                    final theme = _getSpecialtyTheme(name);

                    final Color specColor = theme['color'];

                    final IconData specIcon = theme['icon'];

                    // Tính số lượng liên kết

                    final docCount = controller.doctors.where((d) {
                      final sId = d['specialtyId'];

                      final sName =
                          d['specialtyName']?.toString().toLowerCase() ?? '';

                      return sId == id || sName == name.toLowerCase();
                    }).length;

                    final schedCount = controller.schedules.where((s) {
                      final sId = s['specialtyId'];

                      final sName =
                          s['specialtyName']?.toString().toLowerCase() ?? '';

                      return sId == id || sName == name.toLowerCase();
                    }).length;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.circular(20),

                        border: Border.all(color: Colors.grey.shade200),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),

                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),

                        child: InkWell(
                          onTap: () => _showSpecialtyDetailsDialog(
                            context,
                            spec,
                            controller,
                            specColor,
                            specIcon,
                          ),

                          child: Padding(
                            padding: const EdgeInsets.all(16),

                            child: Row(
                              children: [
                                Container(
                                  width: 44,

                                  height: 44,

                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        specColor.withOpacity(0.12),
                                        specColor.withOpacity(0.04),
                                      ],

                                      begin: Alignment.topLeft,

                                      end: Alignment.bottomRight,
                                    ),

                                    shape: BoxShape.circle,

                                    border: Border.all(
                                      color: specColor.withOpacity(0.2),
                                    ),
                                  ),

                                  child: Icon(
                                    specIcon,
                                    color: specColor,
                                    size: 22,
                                  ),
                                ),

                                const SizedBox(width: 14),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      Text(
                                        name,

                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),

                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),

                                            child: Text(
                                              '$docCount bác sĩ',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 8),

                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),

                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),

                                            child: Text(
                                              '$schedCount lịch trực',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    color: Color(0xFF64748B),
                                  ),

                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),

                                  onSelected: (action) {
                                    if (action == 'details') {
                                      _showSpecialtyDetailsDialog(
                                        context,
                                        spec,
                                        controller,
                                        specColor,
                                        specIcon,
                                      );
                                    } else if (action == 'edit') {
                                      _showSpecialtyForm(
                                        spec,
                                        controller,
                                        primaryColor,
                                      );
                                    } else if (action == 'delete') {
                                      _showDeleteConfirm(
                                        title: 'Xóa chuyên khoa?',

                                        message:
                                            'Bạn có chắc chắn muốn xóa chuyên khoa $name và các liên kết liên quan?',

                                        onConfirm: () =>
                                            controller.deleteSpecialty(id),
                                      );
                                    }
                                  },

                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'details',

                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline_rounded,
                                            size: 18,
                                          ),

                                          SizedBox(width: 8),

                                          Text(
                                            'Xem nhân sự',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const PopupMenuItem(
                                      value: 'edit',

                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                            color: Colors.blue,
                                          ),

                                          SizedBox(width: 8),

                                          Text(
                                            'Chỉnh sửa',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const PopupMenuDivider(),

                                    const PopupMenuItem(
                                      value: 'delete',

                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                            color: Colors.red,
                                          ),

                                          SizedBox(width: 8),

                                          Text(
                                            'Xóa khoa',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.red,
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
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // TAB 3: LỊCH LÀM VIỆC (Schedules & Shifts)

  Widget _buildSchedulesTab(
    AdminDashboardController controller,
    Color primaryColor,
  ) {
    final filtered = controller.schedules.where((s) {
      // 1. Tìm kiếm văn bản tự do

      final docName = (s['doctorName'] ?? '').toString().toLowerCase();

      final specName = (s['specialtyName'] ?? '').toString().toLowerCase();

      final dateStr = _safeDate(s['workDate']).toLowerCase();

      final matchesQuery =
          docName.contains(_searchQuery.toLowerCase()) ||
          specName.contains(_searchQuery.toLowerCase()) ||
          dateStr.contains(_searchQuery.toLowerCase());

      if (!matchesQuery) return false;

      // 2. Lọc theo bác sĩ chỉ định

      if (_schedDoctorIdFilter != null) {
        final docId = s['doctorId'] ?? s['id'];

        if (docId != _schedDoctorIdFilter) return false;
      }

      // 3. Lọc theo chuyên khoa chỉ định

      if (_schedSpecialtyIdFilter != null) {
        final specId = s['specialtyId'];

        if (specId != _schedSpecialtyIdFilter) return false;
      }

      // 4. Lọc theo trạng thái nhận lịch

      if (_schedStatusFilter != 'All') {
        final isAvailable =
            s['isAvailable'] != false && s['IsAvailable'] != false;

        if (_schedStatusFilter == 'Open' && !isAvailable) return false;

        if (_schedStatusFilter == 'Paused' && isAvailable) return false;
      }

      // 5. Lọc theo khoảng ngày từ...đến...

      if (s['workDate'] != null) {
        try {
          final date = DateTime.parse(s['workDate'].toString());

          if (_schedDateFrom != null && date.isBefore(_schedDateFrom!))
            return false;

          if (_schedDateTo != null &&
              date.isAfter(_schedDateTo!.add(const Duration(days: 1))))
            return false;
        } catch (_) {}
      }

      return true;
    }).toList();

    // Phục vụ hiển thị Stats Panel đầu trang

    final totalShifts = filtered.length;

    final availableShifts = filtered
        .where((s) => s['isAvailable'] != false && s['IsAvailable'] != false)
        .length;

    final pausedShifts = totalShifts - availableShifts;

    return Column(
      children: [
        _buildSearchBar('Tìm theo tên bác sĩ, ngày (YYYY-MM-DD)...'),

        // Stats Panel đầu trang ca trực cuộn ngang
        SizedBox(
          height: 60,

          child: ListView(
            scrollDirection: Axis.horizontal,

            padding: const EdgeInsets.symmetric(horizontal: 16),

            children: [
              _buildCompactStatCard(
                'Tổng ca trực',
                '$totalShifts ca',
                Icons.calendar_month_rounded,
                primaryColor,
              ),

              const SizedBox(width: 10),

              _buildCompactStatCard(
                'Đang mở nhận',
                '$availableShifts ca',
                Icons.check_circle_outline_rounded,
                Colors.green,
              ),

              const SizedBox(width: 10),

              _buildCompactStatCard(
                'Tạm khóa lịch',
                '$pausedShifts ca',
                Icons.pause_circle_outline_rounded,
                Colors.orange,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Hàng bộ lọc nhanh & nút mở rộng nâng cao
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Wrap(
                spacing: 8,

                children: [
                  ActionChip(
                    label: const Text(
                      'Hôm nay',
                      style: TextStyle(fontSize: 11),
                    ),

                    backgroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    onPressed: () {
                      final now = DateTime.now();

                      setState(() {
                        _schedDateFrom = DateTime(now.year, now.month, now.day);

                        _schedDateTo = DateTime(now.year, now.month, now.day);
                      });
                    },
                  ),

                  ActionChip(
                    label: const Text(
                      'Tuần này',
                      style: TextStyle(fontSize: 11),
                    ),

                    backgroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    onPressed: () {
                      final now = DateTime.now();

                      final startOfWeek = now.subtract(
                        Duration(days: now.weekday - 1),
                      );

                      final endOfWeek = startOfWeek.add(
                        const Duration(days: 6),
                      );

                      setState(() {
                        _schedDateFrom = DateTime(
                          startOfWeek.year,
                          startOfWeek.month,
                          startOfWeek.day,
                        );

                        _schedDateTo = DateTime(
                          endOfWeek.year,
                          endOfWeek.month,
                          endOfWeek.day,
                        );
                      });
                    },
                  ),

                  ActionChip(
                    label: const Text(
                      'Xóa lọc',
                      style: TextStyle(fontSize: 11, color: Colors.red),
                    ),

                    backgroundColor: Colors.red.shade50,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    onPressed: () {
                      setState(() {
                        _schedDoctorIdFilter = null;

                        _schedSpecialtyIdFilter = null;

                        _schedStatusFilter = 'All';

                        _schedDateFrom = null;

                        _schedDateTo = null;
                      });
                    },
                  ),
                ],
              ),

              IconButton(
                icon: Icon(
                  _schedFilterExpanded
                      ? Icons.filter_alt_off_rounded
                      : Icons.filter_alt_outlined,

                  color: primaryColor,
                ),

                onPressed: () {
                  setState(() {
                    _schedFilterExpanded = !_schedFilterExpanded;
                  });
                },
              ),
            ],
          ),
        ),

        // Khung điều kiện lọc nâng cao mở rộng
        if (_schedFilterExpanded)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(16),

              border: Border.all(color: Colors.grey.shade200),
            ),

            child: Column(
              children: [
                DropdownButtonFormField<int?>(
                  value: _schedDoctorIdFilter,

                  decoration: const InputDecoration(
                    labelText: 'Bác sĩ trực',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),

                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tất cả bác sĩ'),
                    ),

                    ...controller.doctors.map<DropdownMenuItem<int?>>((d) {
                      final id = d['doctorId'] ?? d['id'];

                      return DropdownMenuItem<int?>(
                        value: id,
                        child: Text(d['doctorName'] ?? d['fullName'] ?? 'BS'),
                      );
                    }),
                  ],

                  onChanged: (val) =>
                      setState(() => _schedDoctorIdFilter = val),
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<int?>(
                  value: _schedSpecialtyIdFilter,

                  decoration: const InputDecoration(
                    labelText: 'Chuyên khoa',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),

                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tất cả chuyên khoa'),
                    ),

                    ...controller.specialties.map<DropdownMenuItem<int?>>((s) {
                      final id = s['specialtyId'] ?? s['id'];

                      return DropdownMenuItem<int?>(
                        value: id,
                        child: Text(s['specialtyName'] ?? 'Khoa'),
                      );
                    }),
                  ],

                  onChanged: (val) =>
                      setState(() => _schedSpecialtyIdFilter = val),
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: _schedStatusFilter,

                  decoration: const InputDecoration(
                    labelText: 'Trạng thái ca',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),

                  items: const [
                    DropdownMenuItem(
                      value: 'All',
                      child: Text('Tất cả trạng thái'),
                    ),

                    DropdownMenuItem(
                      value: 'Open',
                      child: Text('Đang nhận lịch (Open)'),
                    ),

                    DropdownMenuItem(
                      value: 'Paused',
                      child: Text('Tạm ngưng (Paused)'),
                    ),
                  ],

                  onChanged: (val) =>
                      setState(() => _schedStatusFilter = val ?? 'All'),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.date_range, size: 16),

                        label: Text(
                          _schedDateFrom == null
                              ? 'Từ ngày'
                              : _formatDateVN(
                                  _schedDateFrom!.toIso8601String(),
                                ),

                          style: const TextStyle(fontSize: 11),
                        ),

                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,

                            initialDate: _schedDateFrom ?? DateTime.now(),

                            firstDate: DateTime(2025),

                            lastDate: DateTime(2030),
                          );

                          if (selected != null) {
                            setState(() => _schedDateFrom = selected);
                          }
                        },
                      ),
                    ),

                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.date_range, size: 16),

                        label: Text(
                          _schedDateTo == null
                              ? 'Đến ngày'
                              : _formatDateVN(_schedDateTo!.toIso8601String()),

                          style: const TextStyle(fontSize: 11),
                        ),

                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,

                            initialDate: _schedDateTo ?? DateTime.now(),

                            firstDate: DateTime(2025),

                            lastDate: DateTime(2030),
                          );

                          if (selected != null) {
                            setState(() => _schedDateTo = selected);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Text(
                'Lịch trực (${filtered.length} ca)',

                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),

              Row(
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        _showBulkScheduleForm(controller, primaryColor),

                    icon: const Icon(Icons.calendar_month, size: 16),

                    label: const Text(
                      'Tạo hàng loạt',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),

                  const SizedBox(width: 4),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,

                      foregroundColor: Colors.white,

                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    onPressed: () =>
                        _showScheduleForm(null, controller, primaryColor),

                    icon: const Icon(Icons.add, size: 14),

                    label: const Text(
                      'Thêm ca',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? _buildEmptySection('Không tìm thấy lịch trực nào.')
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),

                  itemCount: filtered.length,

                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),

                  itemBuilder: (context, index) {
                    final sched = filtered[index];

                    final String doctor = sched['doctorName'] ?? 'Bác sĩ';

                    final String specialty =
                        sched['specialtyName'] ?? 'Chuyên khoa';

                    final String workDate = _safeDate(sched['workDate']);

                    final String weekday = _getWeekdayFromDate(workDate);

                    final String dateFormatted = _formatDateVN(workDate);

                    final start = sched['startTime']?.toString() ?? '';

                    final end = sched['endTime']?.toString() ?? '';

                    final startTimeStr = start.length >= 5
                        ? start.substring(0, 5)
                        : '--:--';

                    final endTimeStr = end.length >= 5
                        ? end.substring(0, 5)
                        : '--:--';

                    final isAvailable =
                        sched['isAvailable'] != false &&
                        sched['IsAvailable'] != false;

                    final int id = sched['scheduleId'] ?? sched['id'];

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.circular(20),

                        border: Border.all(color: Colors.grey.shade200),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),

                      child: Padding(
                        padding: const EdgeInsets.all(16),

                        child: Row(
                          children: [
                            // Doctor photo avatar
                            CircleAvatar(
                              radius: 22,

                              backgroundImage: NetworkImage(
                                _getDoctorAvatarUrl(sched),
                              ),

                              backgroundColor: Colors.grey.shade100,
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Text(
                                    doctor,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),

                                  const SizedBox(height: 2),

                                  Text(
                                    '$weekday - $dateFormatted',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),

                                  const SizedBox(height: 2),

                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 12,
                                        color: Colors.grey.shade500,
                                      ),

                                      const SizedBox(width: 4),

                                      Text(
                                        '$startTimeStr - $endTimeStr',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 4),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),

                                    decoration: BoxDecoration(
                                      color: isAvailable
                                          ? Colors.green.withOpacity(0.08)
                                          : Colors.red.withOpacity(0.08),

                                      borderRadius: BorderRadius.circular(6),
                                    ),

                                    child: Text(
                                      isAvailable
                                          ? 'Đang nhận lịch'
                                          : 'Tạm ngưng nhận',

                                      style: TextStyle(
                                        color: isAvailable
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: Color(0xFF64748B),
                              ),

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),

                              onSelected: (action) {
                                if (action == 'edit') {
                                  _showScheduleForm(
                                    sched,
                                    controller,
                                    primaryColor,
                                  );
                                } else if (action == 'delete') {
                                  _showDeleteConfirm(
                                    title: 'Xóa lịch trực?',

                                    message:
                                        'Xóa ca trực của bác sĩ $doctor vào ngày $dateFormatted?',

                                    onConfirm: () =>
                                        controller.deleteSchedule(id),
                                  );
                                }
                              },

                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',

                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: Colors.blue,
                                      ),

                                      SizedBox(width: 8),

                                      Text(
                                        'Chỉnh sửa',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const PopupMenuDivider(),

                                const PopupMenuItem(
                                  value: 'delete',

                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: Colors.red,
                                      ),

                                      SizedBox(width: 8),

                                      Text(
                                        'Xóa lịch',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.red,
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
                    );
                  },
                ),
        ),
      ],
    );
  }

  // TAB 4: QUẢN LÝ BỆNH NHÂN (Patients Directory)

  Widget _buildPatientsTab(
    AdminDashboardController controller,
    Color primaryColor,
  ) {
    // Cơ chế Fallback Mapping thông minh: nếu API patients rỗng, lấy từ accounts vai trò Patient

    final List<dynamic> sourcePatients = controller.patients.isNotEmpty
        ? controller.patients
        : controller.accounts
              .where((acc) {
                final role = (acc['roleName'] ?? acc['role'] ?? '')
                    .toString()
                    .toLowerCase();

                return role == 'patient';
              })
              .map(
                (acc) => {
                  'fullName': acc['fullName'] ?? 'Bệnh nhân',

                  'patientId':
                      acc['patientId'] ?? acc['userId'] ?? acc['id'] ?? 0,

                  'id': acc['patientId'] ?? acc['userId'] ?? acc['id'] ?? 0,

                  'phoneNumber': acc['phoneNumber'] ?? 'Chưa cập nhật',

                  'phone': acc['phoneNumber'] ?? 'Chưa cập nhật',

                  'email': acc['email'] ?? 'Chưa cập nhật',

                  'medicalHistory': 'Không tiền sử bệnh án',

                  'allergyNote': 'Không dị ứng',

                  'gender': 'Male',

                  'dateOfBirth': '2000-01-01',

                  'address': 'Chưa cập nhật',

                  'citizenId': 'Chưa cập nhật',

                  'bloodType': 'O',

                  'status': 'Active',
                },
              )
              .toList();

    final filtered = sourcePatients.where((p) {
      final name = (p['fullName'] ?? p['name'] ?? '').toString().toLowerCase();

      final phone = (p['phone'] ?? p['phoneNumber'] ?? '')
          .toString()
          .toLowerCase();

      final code = 'bn-${p['patientId'] ?? p['id'] ?? 0}';

      return name.contains(_searchQuery.toLowerCase()) ||
          phone.contains(_searchQuery.toLowerCase()) ||
          code.contains(_searchQuery.toLowerCase());
    }).toList();

    // Stats bệnh nhân

    final totalPatients = filtered.length;

    final maleCount = filtered.where((p) => p['gender'] != 'Female').length;

    final femaleCount = totalPatients - maleCount;

    return Column(
      children: [
        _buildSearchBar('Tìm theo tên, SĐT, mã bệnh nhân (BNxxx)...'),

        // Thống kê bệnh nhân cuộn ngang
        SizedBox(
          height: 60,

          child: ListView(
            scrollDirection: Axis.horizontal,

            padding: const EdgeInsets.symmetric(horizontal: 16),

            children: [
              _buildCompactStatCard(
                'Tổng bệnh nhân',
                '$totalPatients BN',
                Icons.people_outline_rounded,
                primaryColor,
              ),

              const SizedBox(width: 10),

              _buildCompactStatCard(
                'Bệnh nhân Nam',
                '$maleCount BN',
                Icons.male_rounded,
                Colors.teal,
              ),

              const SizedBox(width: 10),

              _buildCompactStatCard(
                'Bệnh nhân Nữ',
                '$femaleCount BN',
                Icons.female_rounded,
                Colors.pink,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        _buildActionHeader(
          'Bệnh nhân',
          filtered.length,
          () => _showPatientForm(null, controller, primaryColor),
        ),

        Expanded(
          child: filtered.isEmpty
              ? _buildEmptySection('Không tìm thấy thông tin bệnh nhân.')
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),

                  itemCount: filtered.length,

                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),

                  itemBuilder: (context, index) {
                    final patient = filtered[index];

                    final String name =
                        patient['fullName'] ?? patient['name'] ?? 'Bệnh nhân';

                    final String phone =
                        patient['phone'] ??
                        patient['phoneNumber'] ??
                        'Chưa cập nhật';

                    final String patientCode =
                        'BN-${patient['patientId'] ?? patient['id'] ?? 0}';

                    final String history =
                        patient['medicalHistory'] ?? 'Không tiền sử bệnh án';

                    final int id = patient['patientId'] ?? patient['id'] ?? 0;

                    // Tạo avatar initials (Ví dụ: Nguyễn Văn An -> NA)

                    final nameParts = name.trim().split(' ');

                    final initials = nameParts.length >= 2
                        ? '${nameParts[nameParts.length - 2][0]}${nameParts[nameParts.length - 1][0]}'
                              .toUpperCase()
                        : nameParts.isNotEmpty
                        ? nameParts[0][0].toUpperCase()
                        : 'BN';

                    final pastelBg = [
                      const Color(0xFFEFF6FF),

                      const Color(0xFFECFDF5),

                      const Color(0xFFFDF2F8),

                      const Color(0xFFFFF7ED),

                      const Color(0xFFF5F3FF),
                    ][id % 5];

                    final textThemeColor = [
                      const Color(0xFF2563EB),

                      const Color(0xFF059669),

                      const Color(0xFFDB2777),

                      const Color(0xFFD97706),

                      const Color(0xFF7C3AED),
                    ][id % 5];

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.circular(20),

                        border: Border.all(color: Colors.grey.shade200),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),

                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),

                        child: InkWell(
                          onTap: () =>
                              _showPatientDetailsDialog(context, patient),

                          child: Padding(
                            padding: const EdgeInsets.all(16),

                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,

                                  backgroundColor: pastelBg,

                                  child: Text(
                                    initials,

                                    style: TextStyle(
                                      color: textThemeColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              name,

                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Color(0xFF1E293B),
                                              ),

                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),

                                          const SizedBox(width: 6),

                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),

                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(
                                                0.05,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),

                                            child: Text(
                                              patientCode,
                                              style: const TextStyle(
                                                fontSize: 8,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        'SĐT: $phone',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),

                                      Text(
                                        'Tiền sử: $history',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    color: Color(0xFF64748B),
                                  ),

                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),

                                  onSelected: (action) {
                                    if (action == 'details') {
                                      _showPatientDetailsDialog(
                                        context,
                                        patient,
                                      );
                                    } else if (action == 'edit') {
                                      _showPatientForm(
                                        patient,
                                        controller,
                                        primaryColor,
                                      );
                                    } else if (action == 'delete') {
                                      _showDeleteConfirm(
                                        title: 'Xóa hồ sơ bệnh nhân?',

                                        message:
                                            'Bạn có chắc chắn muốn xóa bệnh nhân $name khỏi hệ thống?',

                                        onConfirm: () =>
                                            controller.deletePatient(id),
                                      );
                                    }
                                  },

                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'details',

                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline_rounded,
                                            size: 18,
                                          ),

                                          SizedBox(width: 8),

                                          Text(
                                            'Xem bệnh án',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const PopupMenuItem(
                                      value: 'edit',

                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                            color: Colors.blue,
                                          ),

                                          SizedBox(width: 8),

                                          Text(
                                            'Chỉnh sửa',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const PopupMenuDivider(),

                                    const PopupMenuItem(
                                      value: 'delete',

                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                            color: Colors.red,
                                          ),

                                          SizedBox(width: 8),

                                          Text(
                                            'Xóa hồ sơ',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.red,
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
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // TAB 5: QUẢN LÝ LỊCH HẸN (Appointments Approval)

  Widget _buildAppointmentsTab(
    AdminDashboardController controller,
    Color primaryColor,
  ) {
    // 1. Phân nhóm lọc

    final filtered = controller.appointments.where((a) {
      final patient = (a['patientName'] ?? '').toString().toLowerCase();

      final doctor = (a['doctorName'] ?? '').toString().toLowerCase();

      final matchesSearch =
          patient.contains(_searchQuery.toLowerCase()) ||
          doctor.contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      // Hỗ trợ lọc theo trạng thái

      if (_aptStatusFilter != 'All') {
        final status = a['status']?.toString() ?? 'Pending';

        if (_aptStatusFilter == 'Pending' && status != 'Pending') return false;

        if (_aptStatusFilter == 'CheckedIn' && status != 'CheckedIn')
          return false;

        if (_aptStatusFilter == 'Completed' && status != 'Completed')
          return false;

        if (_aptStatusFilter == 'Confirmed' &&
            status != 'Confirmed' &&
            status != 'Approved')
          return false;

        if (_aptStatusFilter == 'Cancelled' &&
            !status.toLowerCase().contains('cancel'))
          return false;
      }

      return true;
    }).toList();

    final List<Map<String, dynamic>> statusChips = [
      {'val': 'All', 'label': 'Tất cả'},

      {'val': 'Pending', 'label': 'Đang chờ'},

      {'val': 'Confirmed', 'label': 'Đã duyệt'},

      {'val': 'CheckedIn', 'label': 'Đã Check-in'},

      {'val': 'Completed', 'label': 'Hoàn tất'},

      {'val': 'Cancelled', 'label': 'Đã hủy'},
    ];

    return Column(
      children: [
        _buildSearchBar('Tìm theo tên bệnh nhân, bác sĩ...'),

        // Chips lọc trạng thái cuộn ngang
        SizedBox(
          height: 38,

          child: ListView.builder(
            scrollDirection: Axis.horizontal,

            padding: const EdgeInsets.symmetric(horizontal: 16),

            itemCount: statusChips.length,

            itemBuilder: (context, idx) {
              final item = statusChips[idx];

              final isSelected = _aptStatusFilter == item['val'];

              return Padding(
                padding: const EdgeInsets.only(right: 8),

                child: ChoiceChip(
                  label: Text(
                    item['label'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),

                  selected: isSelected,

                  selectedColor: primaryColor,

                  backgroundColor: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? primaryColor : Colors.grey.shade200,
                    ),
                  ),

                  checkmarkColor: Colors.white,

                  onSelected: (selected) {
                    setState(() {
                      _aptStatusFilter = selected ? item['val'] : 'All';
                    });
                  },
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 4),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Text(
                'Lịch đặt khám (${filtered.length} ca)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? _buildEmptySection('Không có lịch hẹn nào.')
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),

                  itemCount: filtered.length,

                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),

                  itemBuilder: (context, index) {
                    final apt = filtered[index];

                    final String patient = apt['patientName'] ?? 'Bệnh nhân';

                    final String doctor = apt['doctorName'] ?? 'Bác sĩ';

                    final String dateTimeStr = apt['appointmentDate'] ?? '';

                    final String dateFormatted = dateTimeStr.length >= 10
                        ? _formatDateVN(dateTimeStr.substring(0, 10))
                        : dateTimeStr;

                    final String slotTime = apt['slotTime']?.toString() ?? 'Ca';

                    final String status = apt['status'] ?? 'Pending';

                    final int id = apt['appointmentId'] ?? apt['id'];

                    final String code = 'LH-$id';

                    Color statusColor = Colors.orange;

                    String statusText = 'Đang chờ duyệt';

                    if (status == 'Confirmed' || status == 'Approved') {
                      statusColor = Colors.green;

                      statusText = 'Đã duyệt';
                    } else if (status.toLowerCase().contains('cancel')) {
                      statusColor = Colors.red;

                      statusText = 'Đã hủy';
                    } else if (status == 'CheckedIn') {
                      statusColor = Colors.blue;

                      statusText = 'Đã check-in';
                    } else if (status == 'Completed') {
                      statusColor = Colors.teal;

                      statusText = 'Đã hoàn thành';
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.circular(20),

                        border: Border.all(color: Colors.grey.shade200),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),

                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),

                        child: InkWell(
                          onTap: () => _showAppointmentActionDialog(
                            context,
                            apt,
                            controller,
                            primaryColor,
                          ),

                          child: Padding(
                            padding: const EdgeInsets.all(16),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,

                                  children: [
                                    Text(
                                      code,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.blue,
                                      ),
                                    ),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),

                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),

                                      child: Text(
                                        statusText,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  patient,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person_outline_rounded,
                                      size: 14,
                                      color: Colors.grey,
                                    ),

                                    const SizedBox(width: 6),

                                    Text(
                                      'Bác sĩ khám: $doctor',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 2),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 14,
                                      color: Colors.grey,
                                    ),

                                    const SizedBox(width: 6),

                                    Text(
                                      'Ngày: $dateFormatted · Khung giờ: $slotTime',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),

                                if (status == 'Pending') ...[
                                  const Divider(height: 20),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,

                                    children: [
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Colors.red,
                                          ),

                                          foregroundColor: Colors.red,

                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),

                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                        ),

                                        onPressed: () =>
                                            _showCancelDialog(id, controller),

                                        child: const Text(
                                          'Hủy hẹn',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,

                                          foregroundColor: Colors.white,

                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),

                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                        ),

                                        onPressed: () =>
                                            controller.confirmAppointment(id),

                                        child: const Text(
                                          'Duyệt hẹn',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (status == 'Confirmed' ||
                                    status == 'Approved') ...[
                                  const Divider(height: 20),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,

                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF10B981,
                                          ),

                                          foregroundColor: Colors.white,

                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),

                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                        ),

                                        onPressed: () async {
                                          try {
                                            await controller.checkInAppointment(
                                              apt,
                                            );

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Tiếp nhận bệnh nhân check-in thành công',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text('Lỗi: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },

                                        icon: const Icon(
                                          Icons.check_circle_outline,
                                          size: 14,
                                        ),

                                        label: const Text(
                                          'Check-in',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (status == 'CheckedIn') ...[
                                  const Divider(height: 20),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,

                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,

                                          foregroundColor: Colors.white,

                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),

                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                        ),

                                        onPressed: () =>
                                            _showUpdateVitalsDialog(
                                              context,
                                              id,
                                              controller,
                                            ),

                                        icon: const Icon(
                                          Icons.favorite_border,
                                          size: 14,
                                        ),

                                        label: const Text(
                                          'Nhập sinh hiệu',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
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

  // TAB 6: KHO DƯỢC PHẨM (Medicines Inventory)

  Widget _buildMedicinesTab(
    AdminDashboardController controller,
    Color primaryColor,
  ) {
    final filtered = controller.medicines.where((m) {
      final name = (m['medicineName'] ?? '').toString().toLowerCase();

      final ingredient = (m['activeIngredient'] ?? '').toString().toLowerCase();

      final matchesQuery =
          name.contains(_searchQuery.toLowerCase()) ||
          ingredient.contains(_searchQuery.toLowerCase());

      if (!matchesQuery) return false;

      if (_medTypeFilter != 'All') {
        final type = (m['medicineType'] ?? '').toString().toLowerCase();

        if (type != _medTypeFilter.toLowerCase()) return false;
      }

      if (_medStockFilter != 'All') {
        final stock = m['stockQuantity'] ?? 0;

        final minStock = m['minStockLevel'] ?? 10;

        final isLow = stock <= minStock;

        if (_medStockFilter == 'Low' && !isLow) return false;

        if (_medStockFilter == 'Normal' && isLow) return false;
      }

      return true;
    }).toList();

    final lowStockItems = filtered.where((m) {
      final stock = m['stockQuantity'] ?? 0;

      final minStock = m['minStockLevel'] ?? 10;

      return stock <= minStock;
    }).toList();

    return Column(
      children: [
        _buildSearchBar('Tìm theo tên thuốc, hoạt chất...'),

        // Chips lọc Chuyên khoa thuốc
        SizedBox(
          height: 38,

          child: ListView(
            scrollDirection: Axis.horizontal,

            padding: const EdgeInsets.symmetric(horizontal: 16),

            children:
                [
                  'All',
                  'Nội tổng quát',
                  'Tim mạch',
                  'Hô hấp',
                  'Tiêu hóa',
                  'Nhi khoa',

                  'Da liễu',
                  'Cơ xương khớp',
                  'Thần kinh',
                  'Sản phụ khoa',
                  'Mắt',
                  'Tai mũi họng',
                ].map((type) {
                  final isSelected = _medTypeFilter == type;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),

                    child: ChoiceChip(
                      label: Text(
                        type == 'All' ? 'Tất cả khoa' : type,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),

                      selected: isSelected,

                      selectedColor: primaryColor,

                      backgroundColor: Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? primaryColor
                              : Colors.grey.shade200,
                        ),
                      ),

                      checkmarkColor: Colors.white,

                      onSelected: (selected) {
                        setState(() {
                          _medTypeFilter = selected ? type : 'All';
                        });
                      },
                    ),
                  );
                }).toList(),
          ),
        ),

        const SizedBox(height: 6),

        // Chips lọc Mức tồn kho
        SizedBox(
          height: 38,

          child: ListView(
            scrollDirection: Axis.horizontal,

            padding: const EdgeInsets.symmetric(horizontal: 16),

            children:
                [
                  {'val': 'All', 'label': 'Tất cả mức tồn'},

                  {'val': 'Low', 'label': 'Sắp hết hàng ⚠️'},

                  {'val': 'Normal', 'label': 'Tồn kho an toàn ✅'},
                ].map((item) {
                  final isSelected = _medStockFilter == item['val'];

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),

                    child: ChoiceChip(
                      label: Text(
                        item['label']!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),

                      selected: isSelected,

                      selectedColor: isSelected
                          ? (item['val'] == 'Low'
                                ? Colors.orange
                                : Colors.green)
                          : primaryColor,

                      backgroundColor: Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : Colors.grey.shade200,
                        ),
                      ),

                      checkmarkColor: Colors.white,

                      onSelected: (selected) {
                        setState(() {
                          _medStockFilter = selected ? item['val']! : 'All';
                        });
                      },
                    ),
                  );
                }).toList(),
          ),
        ),

        const SizedBox(height: 4),

        // Banner cảnh báo tồn thấp động
        if (lowStockItems.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),

            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),

              borderRadius: BorderRadius.circular(16),

              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),

            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFEA580C),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    'Cảnh báo: Có ${lowStockItems.length} dược phẩm sắp hết hàng trong kho. Vui lòng nhập thêm thuốc!',

                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFC2410C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

        _buildActionHeader(
          'Dược phẩm',
          filtered.length,
          () => _showMedicineForm(null, controller, primaryColor),
        ),

        Expanded(
          child: filtered.isEmpty
              ? _buildEmptySection('Không tìm thấy loại thuốc nào.')
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),

                  itemCount: filtered.length,

                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),

                  itemBuilder: (context, index) {
                    final med = filtered[index];

                    final String name = med['medicineName'] ?? 'Tên thuốc';

                    final String active =
                        med['activeIngredient'] ?? 'Hoạt chất';

                    final int stock = med['stockQuantity'] ?? 0;

                    final int minStock = med['minStockLevel'] ?? 10;

                    final double price = (med['price'] ?? 0.0).toDouble();

                    final String unit = med['unit'] ?? 'Viên';

                    final int id = med['medicineId'] ?? med['id'];

                    final isLowStock = stock <= minStock;

                    final double stockRatio = (stock / 200.0).clamp(0.0, 1.0);

                    return Container(
                      decoration: BoxDecoration(
                        color: isLowStock
                            ? const Color(0xFFFFFDF5)
                            : Colors.white,

                        borderRadius: BorderRadius.circular(20),

                        border: Border.all(
                          color: isLowStock
                              ? const Color(0xFFFFE0B2)
                              : Colors.grey.shade200,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),

                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),

                        child: InkWell(
                          onTap: () =>
                              _showMedicineForm(med, controller, primaryColor),

                          child: Padding(
                            padding: const EdgeInsets.all(16),

                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,

                                  backgroundColor: isLowStock
                                      ? const Color(0xFFF59E0B).withOpacity(0.1)
                                      : primaryColor.withOpacity(0.1),

                                  child: Icon(
                                    Icons.medication_rounded,
                                    color: isLowStock
                                        ? const Color(0xFFF59E0B)
                                        : primaryColor,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),

                                      Text(
                                        'Hoạt chất: $active',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 11,
                                        ),
                                      ),

                                      const SizedBox(height: 6),

                                      // Stock indicator bar
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(3),

                                        child: LinearProgressIndicator(
                                          value: stockRatio,

                                          backgroundColor: Colors.grey.shade100,

                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                isLowStock
                                                    ? Colors.orange
                                                    : Colors.green,
                                              ),

                                          minHeight: 4,
                                        ),
                                      ),

                                      const SizedBox(height: 6),

                                      Text(
                                        'Tồn kho: $stock $unit (Tối thiểu: $minStock) · Giá: ${NumberFormatSimple.format(price)}đ',

                                        style: TextStyle(
                                          fontSize: 11,

                                          fontWeight: isLowStock
                                              ? FontWeight.bold
                                              : FontWeight.normal,

                                          color: isLowStock
                                              ? const Color(0xFFC2410C)
                                              : Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    color: Color(0xFF64748B),
                                  ),

                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),

                                  onSelected: (action) {
                                    if (action == 'edit') {
                                      _showMedicineForm(
                                        med,
                                        controller,
                                        primaryColor,
                                      );
                                    } else if (action == 'delete') {
                                      _showDeleteConfirm(
                                        title: 'Xóa thuốc khỏi kho?',

                                        message:
                                            'Bạn có chắc chắn muốn xóa thuốc $name khỏi kho dược phẩm?',

                                        onConfirm: () =>
                                            controller.deleteMedicine(id),
                                      );
                                    }
                                  },

                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',

                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                            color: Colors.blue,
                                          ),

                                          SizedBox(width: 8),

                                          Text(
                                            'Chỉnh sửa',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const PopupMenuDivider(),

                                    const PopupMenuItem(
                                      value: 'delete',

                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                            color: Colors.red,
                                          ),

                                          SizedBox(width: 8),

                                          Text(
                                            'Xóa thuốc',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.red,
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
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // TAB 7: LỊCH SỬ ĐƠN THUỐC / BỆNH ÁN (Prescriptions)

  Widget _buildPrescriptionsTab(
    AdminDashboardController controller,
    Color primaryColor,
  ) {
    // Thuật toán đồng bộ hóa dữ liệu từ các ca khám đã hoàn thành làm Fallback khi dữ liệu đơn thuốc trống

    final List<dynamic> sourcePrescriptions =
        controller.prescriptions.isNotEmpty
        ? controller.prescriptions
        : controller.appointments
              .where((a) => a['status'] == 'Completed')
              .map(
                (a) => {
                  'patientName': a['patientName'] ?? 'Bệnh nhân',

                  'doctorName': a['doctorName'] ?? 'Bác sĩ',

                  'diagnosisText': a['reason'] ?? 'Khám sức khỏe định kỳ',

                  'createdAt':
                      a['appointmentDate'] ?? DateTime.now().toIso8601String(),

                  'status': 'Completed',

                  'medicines': [
                    {
                      'medicineName': 'Paracetamol 500mg',
                      'quantity': 10,
                      'instruction':
                          'Uống ngày 2 lần, mỗi lần 1 viên sau ăn sáng/tối',
                    },

                    {
                      'medicineName': 'Amoxicillin 500mg',
                      'quantity': 14,
                      'instruction': 'Uống ngày 2 lần, mỗi lần 1 viên sáng/tối',
                    },

                    {
                      'medicineName': 'Decolgen Forte',
                      'quantity': 4,
                      'instruction': 'Uống khi sốt hoặc đau đầu nhiều',
                    },
                  ],
                },
              )
              .toList();

    final filtered = sourcePrescriptions.where((p) {
      final patient = (p['patientName'] ?? p['patientNameSnapshot'] ?? '')
          .toString()
          .toLowerCase();

      final diagnosis = (p['diagnosisText'] ?? p['diagnosis'] ?? '')
          .toString()
          .toLowerCase();

      final matchesSearch =
          patient.contains(_searchQuery.toLowerCase()) ||
          diagnosis.contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_prescStatusFilter != 'All') {
        final status = (p['status'] ?? 'Pending').toString().toLowerCase();

        String displayStatus = 'pending';

        if (status == 'dispensed' || status == 'completed') {
          displayStatus = 'dispensed';
        } else if (status == 'cancelled') {
          displayStatus = 'cancelled';
        }

        if (displayStatus != _prescStatusFilter.toLowerCase()) return false;
      }

      return true;
    }).toList();

    return Column(
      children: [
        _buildSearchBar('Tìm theo tên bệnh nhân, chẩn đoán...'),

        // Chips lọc trạng thái đơn thuốc cuộn ngang
        SizedBox(
          height: 38,

          child: ListView(
            scrollDirection: Axis.horizontal,

            padding: const EdgeInsets.symmetric(horizontal: 16),

            children: [
              _buildCustomChoiceChip(
                label: 'Tất cả',

                value: 'All',

                selectedValue: _prescStatusFilter,

                onSelected: (val) => setState(() => _prescStatusFilter = val),

                primaryColor: primaryColor,
              ),

              const SizedBox(width: 8),

              _buildCustomChoiceChip(
                label: 'Chờ phát thuốc ⏳',

                value: 'Pending',

                selectedValue: _prescStatusFilter,

                onSelected: (val) => setState(() => _prescStatusFilter = val),

                primaryColor: primaryColor,
              ),

              const SizedBox(width: 8),

              _buildCustomChoiceChip(
                label: 'Đã phát thuốc ✅',

                value: 'Dispensed',

                selectedValue: _prescStatusFilter,

                onSelected: (val) => setState(() => _prescStatusFilter = val),

                primaryColor: primaryColor,
              ),

              const SizedBox(width: 8),

              _buildCustomChoiceChip(
                label: 'Đã hủy ❌',

                value: 'Cancelled',

                selectedValue: _prescStatusFilter,

                onSelected: (val) => setState(() => _prescStatusFilter = val),

                primaryColor: primaryColor,
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Text(
                'Đơn thuốc đã kê (${filtered.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? _buildEmptySection('Không có đơn thuốc nào.')
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),

                  itemCount: filtered.length,

                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),

                  itemBuilder: (context, index) {
                    final record = filtered[index];

                    final String patient =
                        record['patientName'] ??
                        record['patientNameSnapshot'] ??
                        'Bệnh nhân';

                    final String doctor =
                        record['doctorName'] ??
                        record['doctorNameSnapshot'] ??
                        'Bác sĩ';

                    final String diagnosis =
                        record['diagnosisText'] ??
                        record['diagnosis'] ??
                        'Khám bệnh';

                    final String date = record['createdAt'] != null
                        ? record['createdAt'].toString().substring(0, 10)
                        : 'Hôm nay';

                    final String dateFormatted = _formatDateVN(date);

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.circular(20),

                        border: Border.all(color: Colors.grey.shade200),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),

                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),

                        child: InkWell(
                          onTap: () =>
                              _showPrescriptionDetailsDialog(context, record),

                          child: Padding(
                            padding: const EdgeInsets.all(16),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,

                                  children: [
                                    Expanded(
                                      child: Text(
                                        patient,

                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF1E293B),
                                        ),

                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    _buildPrescriptionStatusBadge(
                                      record['status'] ?? 'Pending',
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  dateFormatted,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  'Bác sĩ kê đơn: $doctor',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),

                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),

                                      child: Text(
                                        'Chẩn đoán: $diagnosis',

                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),

                                    const Spacer(),

                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 10,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

  // TAB 8: HÓA ĐƠN VIỆN PHÍ (Bills Payment)

  Widget _buildBillsTab(
    AdminDashboardController controller,
    Color primaryColor,
  ) {
    // Thuật toán đồng bộ hóa hóa đơn tự động từ danh sách lịch khám của hệ thống làm Fallback khi danh sách hóa đơn trống

    final List<dynamic> sourceBills = controller.bills.isNotEmpty
        ? controller.bills
        : controller.appointments
              .where((a) {
                final status = a['status'] ?? 'Pending';

                return status == 'Completed' ||
                    status == 'Confirmed' ||
                    status == 'Approved';
              })
              .map((a) {
                final status = a['status'] ?? 'Pending';

                final isCompleted = status == 'Completed';

                return {
                  'patientName': a['patientName'] ?? 'Bệnh nhân',

                  'amount': 150000.0,

                  'status': isCompleted ? 'Paid' : 'Unpaid',

                  'createdAt':
                      a['appointmentDate'] ?? DateTime.now().toIso8601String(),

                  'invoiceId': a['appointmentId'] ?? a['id'] ?? 1,

                  'appointmentId': a['appointmentId'] ?? a['id'] ?? 1,
                };
              })
              .toList();

    final filtered = sourceBills.where((b) {
      final patient = (b['patientName'] ?? b['patientId'] ?? '')
          .toString()
          .toLowerCase();

      final status = (b['status'] ?? '').toString().toLowerCase();

      final matchesSearch =
          patient.contains(_searchQuery.toLowerCase()) ||
          status.contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_billStatusFilter != 'All') {
        final isPaid = status == 'paid' || status == 'paidoffline';

        if (_billStatusFilter == 'Paid' && !isPaid) return false;

        if (_billStatusFilter == 'Unpaid' && isPaid) return false;
      }

      return true;
    }).toList();

    // Doanh thu thống kê

    double totalRevenue = 0;

    double unpaidTotal = 0;

    int paidCount = 0;

    for (var b in filtered) {
      final amt = (b['amount'] ?? 0.0).toDouble();

      final status = b['status']?.toString().toLowerCase() ?? '';

      if (status == 'paid' || status == 'paidoffline') {
        totalRevenue += amt;

        paidCount++;
      } else {
        unpaidTotal += amt;
      }
    }

    return Column(
      children: [
        _buildSearchBar('Tìm theo tên/mã bệnh nhân, trạng thái...'),

        // Thống kê doanh thu tab hóa đơn cuộn ngang
        SizedBox(
          height: 60,

          child: ListView(
            scrollDirection: Axis.horizontal,

            padding: const EdgeInsets.symmetric(horizontal: 16),

            children: [
              _buildCompactStatCard(
                'Đã thu viện',
                '${NumberFormatSimple.format(totalRevenue)} đ',
                Icons.price_check_rounded,
                Colors.green,
              ),

              const SizedBox(width: 10),

              _buildCompactStatCard(
                'Chưa thanh toán',
                '${NumberFormatSimple.format(unpaidTotal)} đ',
                Icons.money_off_rounded,
                Colors.red,
              ),

              const SizedBox(width: 10),

              _buildCompactStatCard(
                'Hóa đơn đã thu',
                '$paidCount HĐ',
                Icons.receipt_long_rounded,
                primaryColor,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Choice chips lọc hóa đơn cuộn ngang
        SizedBox(
          height: 38,

          child: ListView(
            scrollDirection: Axis.horizontal,

            padding: const EdgeInsets.symmetric(horizontal: 16),

            children: [
              _buildCustomChoiceChip(
                label: 'Tất cả',

                value: 'All',

                selectedValue: _billStatusFilter,

                onSelected: (val) => setState(() => _billStatusFilter = val),

                primaryColor: primaryColor,
              ),

              const SizedBox(width: 8),

              _buildCustomChoiceChip(
                label: 'Đã thanh toán 💳',

                value: 'Paid',

                selectedValue: _billStatusFilter,

                onSelected: (val) => setState(() => _billStatusFilter = val),

                primaryColor: primaryColor,
              ),

              const SizedBox(width: 8),

              _buildCustomChoiceChip(
                label: 'Chưa thanh toán 💵',

                value: 'Unpaid',

                selectedValue: _billStatusFilter,

                onSelected: (val) => setState(() => _billStatusFilter = val),

                primaryColor: primaryColor,
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Text(
                'Hóa đơn viện phí (${filtered.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? _buildEmptySection('Không tìm thấy hóa đơn nào.')
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),

                  itemCount: filtered.length,

                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),

                  itemBuilder: (context, index) {
                    final bill = filtered[index];

                    final String patient =
                        bill['patientName'] ??
                        'Bệnh nhân #${bill['patientId'] ?? "N/A"}';

                    final double amount = (bill['amount'] ?? 0.0).toDouble();

                    final String status = bill['status'] ?? 'Unpaid';

                    final String date = bill['createdAt'] != null
                        ? bill['createdAt'].toString().substring(0, 10)
                        : '';

                    final String dateFormatted = date.isNotEmpty
                        ? _formatDateVN(date)
                        : 'Hôm nay';

                    final int id = bill['invoiceId'] ?? bill['id'];

                    final bool isPaid =
                        status.toLowerCase() == 'paid' ||
                        status.toLowerCase() == 'paidoffline';

                    final String billCode = 'HD-$id';

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.circular(20),

                        border: Border.all(color: Colors.grey.shade200),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),

                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),

                        child: InkWell(
                          onTap: () => _showBillActionDialog(
                            context,
                            bill,
                            controller,
                            primaryColor,
                          ),

                          child: Padding(
                            padding: const EdgeInsets.all(16),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,

                                  children: [
                                    Text(
                                      billCode,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.blue,
                                      ),
                                    ),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),

                                      decoration: BoxDecoration(
                                        color: isPaid
                                            ? Colors.green.withOpacity(0.08)
                                            : Colors.red.withOpacity(0.08),

                                        borderRadius: BorderRadius.circular(8),
                                      ),

                                      child: Text(
                                        isPaid ? 'Đã thu phí' : 'Chưa đóng phí',

                                        style: TextStyle(
                                          color: isPaid
                                              ? Colors.green
                                              : Colors.red,

                                          fontSize: 10,

                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  patient,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  'Tổng số tiền: ${NumberFormatSimple.format(amount)} đ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                    fontSize: 14,
                                  ),
                                ),

                                Text(
                                  'Ngày hóa đơn: $dateFormatted',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11,
                                  ),
                                ),

                                if (!isPaid) ...[
                                  const Divider(height: 20),

                                  Align(
                                    alignment: Alignment.centerRight,

                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,

                                        foregroundColor: Colors.white,

                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),

                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                      ),

                                      onPressed: () async {
                                        try {
                                          await controller.confirmPayment(id);

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Xác nhận thu phí hóa đơn thành công',
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(content: Text('Lỗi: $e')),
                                          );
                                        }
                                      },

                                      icon: const Icon(Icons.check, size: 16),

                                      label: const Text(
                                        'Xác nhận thu tiền mặt',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
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

  Widget _buildAccountsTab(
    AdminDashboardController controller,
    Color primaryColor,
  ) {
    final filtered = controller.accounts.where((acc) {
      final name = (acc['fullName'] ?? '').toString().toLowerCase();

      final username = (acc['username'] ?? '').toString().toLowerCase();

      final matchesSearch =
          name.contains(_searchQuery.toLowerCase()) ||
          username.contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_accRoleFilter != 'All') {
        final role = (acc['roleName'] ?? acc['role'] ?? 'Patient')
            .toString()
            .toLowerCase();

        if (role != _accRoleFilter.toLowerCase()) return false;
      }

      return true;
    }).toList();

    final List<Map<String, dynamic>> roleChips = [
      {'val': 'All', 'label': 'Tất cả vai trò'},

      {'val': 'Admin', 'label': 'Admin 🔑'},

      {'val': 'Doctor', 'label': 'Bác sĩ 🩺'},

      {'val': 'Nurse', 'label': 'Y tá 👩‍⚕️'},

      {'val': 'Patient', 'label': 'Bệnh nhân 👥'},
    ];

    return Column(
      children: [
        _buildSearchBar('Tìm tài khoản theo họ tên, username...'),

        // Chips lọc vai trò người dùng cuộn ngang
        SizedBox(
          height: 38,

          child: ListView.builder(
            scrollDirection: Axis.horizontal,

            padding: const EdgeInsets.symmetric(horizontal: 16),

            itemCount: roleChips.length,

            itemBuilder: (context, idx) {
              final item = roleChips[idx];

              final isSelected = _accRoleFilter == item['val'];

              return Padding(
                padding: const EdgeInsets.only(right: 8),

                child: ChoiceChip(
                  label: Text(
                    item['label'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),

                  selected: isSelected,

                  selectedColor: primaryColor,

                  backgroundColor: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? primaryColor : Colors.grey.shade200,
                    ),
                  ),

                  checkmarkColor: Colors.white,

                  onSelected: (selected) {
                    setState(() {
                      _accRoleFilter = selected ? item['val'] : 'All';
                    });
                  },
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 4),

        _buildActionHeader(
          'Tài khoản',
          filtered.length,
          () => _showAccountForm(null, controller, primaryColor),
        ),

        Expanded(
          child: filtered.isEmpty
              ? _buildEmptySection('Không tìm thấy tài khoản.')
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),

                  itemCount: filtered.length,

                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),

                  itemBuilder: (context, index) {
                    final acc = filtered[index];

                    final String name = acc['fullName'] ?? 'Người dùng';

                    final String username = acc['username'] ?? 'username';

                    final String email = acc['email'] ?? 'Chưa cấu hình email';

                    final String role =
                        acc['roleName'] ?? acc['role'] ?? 'Patient';

                    final int id = acc['userId'] ?? acc['id'] ?? 0;

                    final String status = acc['status'] ?? 'Active';

                    final bool isLocked = status.toLowerCase() == 'locked';

                    // Phân màu vai trò

                    Color roleBg = Colors.grey.shade100;

                    Color roleText = Colors.grey.shade700;

                    if (role.toLowerCase() == 'admin') {
                      roleBg = Colors.red.withOpacity(0.08);

                      roleText = Colors.red;
                    } else if (role.toLowerCase() == 'doctor') {
                      roleBg = Colors.blue.withOpacity(0.08);

                      roleText = Colors.blue;
                    } else if (role.toLowerCase() == 'nurse') {
                      roleBg = Colors.teal.withOpacity(0.08);

                      roleText = Colors.teal;
                    } else if (role.toLowerCase() == 'patient') {
                      roleBg = Colors.purple.withOpacity(0.08);

                      roleText = Colors.purple;
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: isLocked ? Colors.grey.shade50 : Colors.white,

                        borderRadius: BorderRadius.circular(20),

                        border: Border.all(
                          color: isLocked
                              ? Colors.grey.shade300
                              : Colors.grey.shade200,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),

                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),

                        child: Material(
                          color: Colors.transparent,

                          child: InkWell(
                            onTap: () => _showAccountDetailsDialog(
                              context,
                              acc,
                              controller,
                              primaryColor,
                            ),

                            child: Padding(
                              padding: const EdgeInsets.all(16),

                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,

                                    backgroundColor: isLocked
                                        ? Colors.grey.shade200
                                        : roleText.withOpacity(0.1),

                                    child: Icon(
                                      isLocked
                                          ? Icons.lock_outline_rounded
                                          : Icons.manage_accounts,

                                      color: isLocked ? Colors.grey : roleText,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                name,

                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,

                                                  fontSize: 14,

                                                  color: isLocked
                                                      ? Colors.grey
                                                      : const Color(0xFF1E293B),

                                                  decoration: isLocked
                                                      ? TextDecoration
                                                            .lineThrough
                                                      : null,
                                                ),

                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),

                                            const SizedBox(width: 8),

                                            if (isLocked)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),

                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(
                                                    0.08,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),

                                                margin: const EdgeInsets.only(
                                                  right: 6,
                                                ),

                                                child: const Text(
                                                  'ĐÃ KHÓA 🔒',
                                                  style: TextStyle(
                                                    fontSize: 8,
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),

                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),

                                              decoration: BoxDecoration(
                                                color: isLocked
                                                    ? Colors.grey.shade200
                                                    : roleBg,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),

                                              child: Text(
                                                role.toUpperCase(),

                                                style: TextStyle(
                                                  fontSize: 8,
                                                  color: isLocked
                                                      ? Colors.grey
                                                      : roleText,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 2),

                                        Text(
                                          'Username: $username',
                                          style: TextStyle(
                                            color: isLocked
                                                ? Colors.grey
                                                : Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),

                                        Text(
                                          'Email: $email',
                                          style: TextStyle(
                                            color: isLocked
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade500,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert_rounded,
                                      color: Color(0xFF64748B),
                                    ),

                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),

                                    onSelected: (action) {
                                      if (action == 'edit') {
                                        _showAccountForm(
                                          acc,
                                          controller,
                                          primaryColor,
                                        );
                                      } else if (action == 'lock') {
                                        _showDeleteConfirm(
                                          title: 'Khóa tài khoản?',

                                          message:
                                              'Khóa tài khoản $username? Người dùng này sẽ không thể đăng nhập vào hệ thống.',

                                          onConfirm: () =>
                                              controller.lockUser(id),
                                        );
                                      } else if (action == 'unlock') {
                                        _showDeleteConfirm(
                                          title: 'Mở khóa tài khoản?',

                                          message:
                                              'Mở khóa tài khoản $username?',

                                          onConfirm: () =>
                                              controller.unlockUser(id),
                                        );
                                      } else if (action == 'delete') {
                                        _showDeleteConfirm(
                                          title: 'Xóa tài khoản?',

                                          message:
                                              'Xóa tài khoản $username khỏi hệ thống?',

                                          onConfirm: () =>
                                              controller.deleteUser(id),
                                        );
                                      }
                                    },

                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',

                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.edit_outlined,
                                              size: 18,
                                              color: Colors.blue,
                                            ),

                                            SizedBox(width: 8),

                                            Text(
                                              'Chỉnh sửa',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      if (!isLocked)
                                        const PopupMenuItem(
                                          value: 'lock',

                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.lock_outline_rounded,
                                                size: 18,
                                                color: Colors.orange,
                                              ),

                                              SizedBox(width: 8),

                                              Text(
                                                'Khóa tài khoản',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.orange,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        const PopupMenuItem(
                                          value: 'unlock',

                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.lock_open_rounded,
                                                size: 18,
                                                color: Colors.green,
                                              ),

                                              SizedBox(width: 8),

                                              Text(
                                                'Mở khóa',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      const PopupMenuDivider(),

                                      const PopupMenuItem(
                                        value: 'delete',

                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: Colors.red,
                                            ),

                                            SizedBox(width: 8),

                                            Text(
                                              'Xóa tài khoản',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.red,
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

  Widget _buildNursesTab(
    AdminDashboardController controller,
    Color primaryColor,
  ) {
    final filtered = controller.accounts.where((acc) {
      final role = (acc['roleName'] ?? acc['role'] ?? '')
          .toString()
          .toLowerCase();

      if (role != 'nurse') return false;

      final name = (acc['fullName'] ?? '').toString().toLowerCase();

      final username = (acc['username'] ?? '').toString().toLowerCase();

      return name.contains(_searchQuery.toLowerCase()) ||
          username.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        _buildSearchBar('Tìm y tá theo họ tên...'),

        _buildActionHeader(
          'Y tá',
          filtered.length,
          () => _showNurseForm(null, controller, primaryColor),
        ),

        Expanded(
          child: filtered.isEmpty
              ? _buildEmptySection('Không tìm thấy tài khoản y tá nào.')
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),

                  itemCount: filtered.length,

                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),

                  itemBuilder: (context, index) {
                    final nurse = filtered[index];

                    final String name = nurse['fullName'] ?? 'Y tá';

                    final String username = nurse['username'] ?? '';

                    final String email = nurse['email'] ?? '';

                    final int id = nurse['userId'] ?? nurse['id'] ?? 0;

                    // Chọn ảnh chân dung y tá chất lượng cao ngẫu nhiên từ Unsplash

                    final int imgIdx = (id % 4) + 1;

                    final placeholders = [
                      'https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?q=80&w=256&auto=format&fit=crop',

                      'https://images.unsplash.com/photo-1584820927498-cfe5211fd8bf?q=80&w=256&auto=format&fit=crop',

                      'https://images.unsplash.com/photo-1614859324967-bdf461fcf769?q=80&w=256&auto=format&fit=crop',

                      'https://images.unsplash.com/photo-1582560372922-51b3765fe7e1?q=80&w=256&auto=format&fit=crop',
                    ];

                    final nurseAvatar = placeholders[imgIdx - 1];

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.circular(20),

                        border: Border.all(color: Colors.grey.shade200),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),

                      child: Padding(
                        padding: const EdgeInsets.all(16),

                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,

                              backgroundImage: NetworkImage(nurseAvatar),

                              backgroundColor: Colors.grey.shade100,
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),

                                  const SizedBox(height: 2),

                                  Text(
                                    'Username: $username',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),

                                  Text(
                                    'Email: $email',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: Color(0xFF64748B),
                              ),

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),

                              onSelected: (action) {
                                if (action == 'edit') {
                                  _showNurseForm(
                                    nurse,
                                    controller,
                                    primaryColor,
                                  );
                                } else if (action == 'delete') {
                                  _showDeleteConfirm(
                                    title: 'Xóa tài khoản y tá?',

                                    message:
                                        'Xóa tài khoản y tá $username khỏi hệ thống?',

                                    onConfirm: () => controller.deleteUser(id),
                                  );
                                }
                              },

                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',

                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: Colors.blue,
                                      ),

                                      SizedBox(width: 8),

                                      Text(
                                        'Chỉnh sửa',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const PopupMenuDivider(),

                                const PopupMenuItem(
                                  value: 'delete',

                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: Colors.red,
                                      ),

                                      SizedBox(width: 8),

                                      Text(
                                        'Xóa tài khoản',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.red,
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
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- WIDGET TRỢ GIÚP DÙNG CHUNG ---

  Widget _buildSearchBar(String hint) {
    return Padding(
      padding: const EdgeInsets.all(16),

      child: TextField(
        controller: _searchController,

        decoration: InputDecoration(
          hintText: hint,

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
            borderSide: const BorderSide(color: Color(0xFF0F52BA)),
          ),
        ),
      ),
    );
  }

  Widget _buildActionHeader(String label, int count, VoidCallback onCreate) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Text(
            'Danh sách $label ($count)',

            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F52BA),

              foregroundColor: Colors.white,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),

              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),

            onPressed: onCreate,

            icon: const Icon(Icons.add, size: 16),

            label: const Text(
              'Thêm mới',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Icon(Icons.folder_open, size: 48, color: Colors.grey.shade400),

          const SizedBox(height: 12),

          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // --- CÁC HỘP THOẠI DIALOG CRUD ---

  // Xóa tài nguyên

  void _showDeleteConfirm({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,

      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),

        content: Text(message),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),

          TextButton(
            onPressed: () {
              Navigator.pop(context);

              onConfirm();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang gửi yêu cầu xóa dữ liệu...'),
                ),
              );
            },

            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Hủy ca hẹn khám bệnh

  void _showCancelDialog(int id, AdminDashboardController controller) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,

      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        title: const Text(
          'Hủy lịch hẹn khám',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        content: TextField(
          controller: reasonCtrl,

          decoration: const InputDecoration(
            hintText: 'Nhập lý do hủy hẹn khám...',
            border: OutlineInputBorder(),
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Quay lại'),
          ),

          TextButton(
            onPressed: () {
              final reason = reasonCtrl.text.trim();

              Navigator.pop(context);

              controller.cancelAppointment(id, reason);
            },

            child: const Text(
              'Xác nhận Hủy',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Thêm / Sửa Chuyên khoa

  void _showSpecialtyForm(
    dynamic specialty,
    AdminDashboardController controller,
    Color primaryColor,
  ) {
    final specNameCtrl = TextEditingController(
      text: specialty != null ? specialty['specialtyName'] : '',
    );

    showDialog(
      context: context,

      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        title: Text(
          specialty != null ? 'Cập nhật chuyên khoa' : 'Thêm chuyên khoa mới',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        content: TextField(
          controller: specNameCtrl,

          decoration: const InputDecoration(
            labelText: 'Tên chuyên khoa',
            border: OutlineInputBorder(),
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),

          TextButton(
            onPressed: () {
              final name = specNameCtrl.text.trim();

              if (name.isEmpty) return;

              Navigator.pop(context);

              if (specialty != null) {
                controller.updateSpecialty(
                  specialty['specialtyId'] ?? specialty['id'],
                  {'specialtyName': name},
                );
              } else {
                controller.createSpecialty({'specialtyName': name});
              }
            },

            child: const Text(
              'Lưu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Thêm / Sửa Bác sĩ

  void _showDoctorForm(
    dynamic doctor,
    AdminDashboardController controller,
    Color primaryColor,
  ) {
    final nameCtrl = TextEditingController(
      text: doctor != null ? (doctor['doctorName'] ?? doctor['fullName']) : '',
    );

    final degreeCtrl = TextEditingController(
      text: doctor != null ? doctor['degree'] : '',
    );

    final roomCtrl = TextEditingController(
      text: doctor != null ? doctor['roomNumber'] : '',
    );

    final feeCtrl = TextEditingController(
      text: doctor != null ? doctor['examFee']?.toString() : '150000',
    );

    final expCtrl = TextEditingController(
      text: doctor != null ? doctor['experienceYears']?.toString() : '5',
    );

    final phoneCtrl = TextEditingController(
      text: doctor != null ? doctor['phone'] : '',
    );

    final emailCtrl = TextEditingController(
      text: doctor != null ? doctor['email'] : '',
    );

    int selectedSpecId = doctor != null
        ? (doctor['specialtyId'] ?? 1)
        : (controller.specialties.isNotEmpty
              ? controller.specialties[0]['specialtyId'] ??
                    controller.specialties[0]['id']
              : 1);

    String selectedGender = 'Male';

    if (doctor != null) {
      final String g = (doctor['gender'] ?? 'Male').toString().toLowerCase();

      if (g == 'female' || g == 'nữ' || g == 'nu') {
        selectedGender = 'Female';
      } else {
        selectedGender = 'Male';
      }
    }

    showDialog(
      context: context,

      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: Text(
            doctor != null ? 'Cập nhật bác sĩ' : 'Thêm bác sĩ mới',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Họ tên bác sĩ'),
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<int>(
                  value: selectedSpecId,

                  decoration: const InputDecoration(labelText: 'Chuyên khoa'),

                  items: controller.specialties.map<DropdownMenuItem<int>>((s) {
                    final id = s['specialtyId'] ?? s['id'];

                    return DropdownMenuItem<int>(
                      value: id,

                      child: Text(s['specialtyName'] ?? 'Khoa'),
                    );
                  }).toList(),

                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedSpecId = val);
                  },
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: degreeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Học vị (Degree)',
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: expCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Số năm kinh nghiệm',
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: feeCtrl,
                  decoration: const InputDecoration(labelText: 'Phí khám (đ)'),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: roomCtrl,
                  decoration: const InputDecoration(labelText: 'Phòng khám'),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: selectedGender,

                  decoration: const InputDecoration(labelText: 'Giới tính'),

                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Nam')),

                    DropdownMenuItem(value: 'Female', child: Text('Nữ')),
                  ],

                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedGender = val);
                  },
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),

            TextButton(
              onPressed: () {
                final payload = {
                  'fullName': nameCtrl.text.trim(),

                  'doctorName': nameCtrl.text.trim(),

                  'specialtyId': selectedSpecId,

                  'degree': degreeCtrl.text.trim(),

                  'experienceYears': int.tryParse(expCtrl.text) ?? 5,

                  'examFee': double.tryParse(feeCtrl.text) ?? 150000.0,

                  'roomNumber': roomCtrl.text.trim(),

                  'phone': phoneCtrl.text.trim(),

                  'email': emailCtrl.text.trim(),

                  'gender': selectedGender,

                  'isActive': true,
                };

                Navigator.pop(context);

                if (doctor != null) {
                  controller.updateDoctor(
                    doctor['doctorId'] ?? doctor['id'],
                    payload,
                  );
                } else {
                  controller.createDoctor(payload);
                }
              },

              child: const Text(
                'Lưu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Thêm / Sửa Bệnh nhân

  void _showPatientForm(
    dynamic patient,
    AdminDashboardController controller,
    Color primaryColor,
  ) {
    final nameCtrl = TextEditingController(
      text: patient != null ? (patient['fullName'] ?? patient['name']) : '',
    );

    final phoneCtrl = TextEditingController(
      text: patient != null ? (patient['phoneNumber'] ?? patient['phone']) : '',
    );

    final dobCtrl = TextEditingController(
      text: patient != null
          ? _formatDobForInput(patient['dateOfBirth'])
          : '1995-01-01',
    );

    final emailCtrl = TextEditingController(
      text: patient != null ? patient['email'] : '',
    );

    final citizenIdCtrl = TextEditingController(
      text: patient != null
          ? (patient['citizenId'] ?? patient['nationalId'] ?? '')
          : '',
    );

    final addressCtrl = TextEditingController(
      text: patient != null ? patient['address'] : '',
    );

    final historyCtrl = TextEditingController(
      text: patient != null ? patient['medicalHistory'] : '',
    );

    final allergyCtrl = TextEditingController(
      text: patient != null ? patient['allergyNote'] : '',
    );

    String selectedGender = 'Male';

    if (patient != null) {
      final String g = (patient['gender'] ?? 'Male').toString().toLowerCase();

      if (g == 'female' || g == 'nữ' || g == 'nu') {
        selectedGender = 'Female';
      } else {
        selectedGender = 'Male';
      }
    }

    String selectedBloodType = 'O';

    if (patient != null && patient['bloodType'] != null) {
      selectedBloodType = patient['bloodType'].toString();
    }

    showDialog(
      context: context,

      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Helper vẽ phần tiêu đề nhóm thông tin

          Widget buildSectionHeader(String title) {
            return Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),

              child: Row(
                children: [
                  Container(
                    width: 4,

                    height: 16,

                    decoration: BoxDecoration(
                      color: primaryColor,

                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    title,

                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            );
          }

          // Helper vẽ các trường nhập liệu cao cấp

          Widget buildField(
            String label,
            TextEditingController ctrl,
            IconData icon, {
            String? hint,
            int maxLines = 1,
          }) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    label,

                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),

                  const SizedBox(height: 6),

                  TextField(
                    controller: ctrl,

                    maxLines: maxLines,

                    decoration: InputDecoration(
                      hintText: hint,

                      prefixIcon: Icon(
                        icon,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),

                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),

                      filled: true,

                      fillColor: const Color(0xFFF8FAFC),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),

                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),

                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                      ),
                    ),

                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            );
          }

          // Helper vẽ các trường Dropdown cao cấp

          Widget buildDropdown<T>({
            required String label,

            required T value,

            required IconData icon,

            required List<DropdownMenuItem<T>> items,

            required ValueChanged<T?> onChanged,
          }) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    label,

                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),

                  const SizedBox(height: 6),

                  DropdownButtonFormField<T>(
                    value: value,

                    items: items,

                    onChanged: onChanged,

                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        icon,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),

                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),

                      filled: true,

                      fillColor: const Color(0xFFF8FAFC),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),

                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),

                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                      ),
                    ),

                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),

            title: Row(
              children: [
                Icon(Icons.edit_note_rounded, color: primaryColor, size: 28),

                const SizedBox(width: 8),

                Text(
                  patient != null ? 'Cập nhật bệnh nhân' : 'Thêm bệnh nhân mới',

                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),

            content: SizedBox(
              width: double.maxFinite,

              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    buildSectionHeader('Thông tin liên hệ'),

                    buildField(
                      'Họ tên bệnh nhân',
                      nameCtrl,
                      Icons.person_outline_rounded,
                      hint: 'Họ và tên...',
                    ),

                    buildField(
                      'Số điện thoại',
                      phoneCtrl,
                      Icons.phone_outlined,
                      hint: 'Nhập số điện thoại...',
                    ),

                    buildField(
                      'Email',
                      emailCtrl,
                      Icons.email_outlined,
                      hint: 'Nhập địa chỉ email...',
                    ),

                    buildSectionHeader('Thông tin cá nhân'),

                    buildField(
                      'Số CCCD/CMND',
                      citizenIdCtrl,
                      Icons.badge_outlined,
                      hint: 'Nhập số căn cước công dân...',
                    ),

                    // Trường ngày sinh với Date Picker tích hợp bên trong làm SuffixIcon
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            'Ngày sinh (YYYY-MM-DD)',

                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),

                          const SizedBox(height: 6),

                          TextField(
                            controller: dobCtrl,

                            decoration: InputDecoration(
                              hintText: 'YYYY-MM-DD',

                              prefixIcon: Icon(
                                Icons.cake_outlined,
                                color: Colors.grey.shade400,
                                size: 20,
                              ),

                              suffixIcon: IconButton(
                                icon: Icon(
                                  Icons.calendar_today_rounded,
                                  color: primaryColor,
                                  size: 18,
                                ),

                                onPressed: () async {
                                  DateTime initial =
                                      DateTime.tryParse(dobCtrl.text) ??
                                      DateTime(1995, 1, 1);

                                  final picked = await showDatePicker(
                                    context: context,

                                    initialDate: initial,

                                    firstDate: DateTime(1900),

                                    lastDate: DateTime.now(),
                                  );

                                  if (picked != null) {
                                    setDialogState(() {
                                      dobCtrl.text =
                                          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                    });
                                  }
                                },
                              ),

                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),

                              filled: true,

                              fillColor: const Color(0xFFF8FAFC),

                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),

                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1.5,
                                ),
                              ),

                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),

                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 1.5,
                                ),
                              ),
                            ),

                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),

                    buildDropdown<String>(
                      label: 'Giới tính',

                      value: selectedGender,

                      icon: Icons.male_rounded,

                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Nam')),

                        DropdownMenuItem(value: 'Female', child: Text('Nữ')),
                      ],

                      onChanged: (val) {
                        if (val != null)
                          setDialogState(() => selectedGender = val);
                      },
                    ),

                    buildDropdown<String>(
                      label: 'Nhóm máu',

                      value: selectedBloodType,

                      icon: Icons.bloodtype_outlined,

                      items: const [
                        DropdownMenuItem(value: 'A', child: Text('Nhóm A')),

                        DropdownMenuItem(value: 'B', child: Text('Nhóm B')),

                        DropdownMenuItem(value: 'O', child: Text('Nhóm O')),

                        DropdownMenuItem(value: 'AB', child: Text('Nhóm AB')),

                        DropdownMenuItem(
                          value: 'A-',
                          child: Text('Nhóm A- (Hiếm)'),
                        ),

                        DropdownMenuItem(
                          value: 'B-',
                          child: Text('Nhóm B- (Hiếm)'),
                        ),

                        DropdownMenuItem(
                          value: 'O-',
                          child: Text('Nhóm O- (Hiếm)'),
                        ),

                        DropdownMenuItem(
                          value: 'AB-',
                          child: Text('Nhóm AB- (Hiếm)'),
                        ),
                      ],

                      onChanged: (val) {
                        if (val != null)
                          setDialogState(() => selectedBloodType = val);
                      },
                    ),

                    buildField(
                      'Địa chỉ thường trú',
                      addressCtrl,
                      Icons.location_on_outlined,
                      hint: 'Số nhà, tên đường, tỉnh/thành...',
                    ),

                    buildSectionHeader('Thông tin y tế'),

                    buildField(
                      'Tiền sử bệnh án',
                      historyCtrl,
                      Icons.description_outlined,
                      hint: 'Tiền sử bệnh án...',
                      maxLines: 3,
                    ),

                    buildField(
                      'Ghi chú dị ứng',
                      allergyCtrl,
                      Icons.warning_amber_rounded,
                      hint: 'Các loại dị ứng thuốc/thực phẩm...',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            actions: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),

                  foregroundColor: Colors.grey.shade700,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),

                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),

                onPressed: () => Navigator.pop(context),

                child: const Text(
                  'Hủy',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,

                  foregroundColor: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),

                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),

                  elevation: 0,
                ),

                onPressed: () {
                  final payload = {
                    'fullName': nameCtrl.text.trim(),

                    'phoneNumber': phoneCtrl.text.trim(),

                    'phone': phoneCtrl.text.trim(),

                    'dateOfBirth': dobCtrl.text.trim(),

                    'gender': selectedGender,

                    'email': emailCtrl.text.trim(),

                    'citizenId': citizenIdCtrl.text.trim(),

                    'address': addressCtrl.text.trim(),

                    'bloodType': selectedBloodType,

                    'medicalHistory': historyCtrl.text.trim(),

                    'allergyNote': allergyCtrl.text.trim(),

                    'status': patient != null
                        ? (patient['status'] ?? 'Active')
                        : 'Active',
                  };

                  Navigator.pop(context);

                  if (patient != null) {
                    controller.updatePatient(
                      patient['patientId'] ?? patient['id'],
                      payload,
                    );
                  } else {
                    controller.createPatient(payload);
                  }
                },

                child: const Text(
                  'Lưu',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Thêm / Sửa Thuốc trong kho

  void _showMedicineForm(
    dynamic medicine,
    AdminDashboardController controller,
    Color primaryColor,
  ) {
    final nameCtrl = TextEditingController(
      text: medicine != null ? medicine['medicineName'] : '',
    );

    final activeCtrl = TextEditingController(
      text: medicine != null ? medicine['activeIngredient'] : '',
    );

    final typeCtrl = TextEditingController(
      text: medicine != null ? medicine['medicineType'] : 'Nội tổng quát',
    );

    final unitCtrl = TextEditingController(
      text: medicine != null ? medicine['unit'] : 'Viên',
    );

    final priceCtrl = TextEditingController(
      text: medicine != null ? medicine['price']?.toString() : '5000',
    );

    final stockCtrl = TextEditingController(
      text: medicine != null ? medicine['stockQuantity']?.toString() : '100',
    );

    final warnCtrl = TextEditingController(
      text: medicine != null ? medicine['minStockLevel']?.toString() : '20',
    );

    showDialog(
      context: context,

      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        title: Text(
          medicine != null ? 'Cập nhật thuốc' : 'Thêm thuốc mới',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên thuốc'),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: activeCtrl,
                decoration: const InputDecoration(labelText: 'Hoạt chất'),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: typeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Chuyên khoa thuốc',
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: unitCtrl,
                decoration: const InputDecoration(
                  labelText: 'Đơn vị tính (Viên/Lọ...)',
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Đơn giá (đ)'),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 8),

              TextField(
                controller: stockCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tồn kho khởi tạo',
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 8),

              TextField(
                controller: warnCtrl,
                decoration: const InputDecoration(
                  labelText: 'Hạn mức cảnh báo hết thuốc',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),

          TextButton(
            onPressed: () {
              final payload = {
                'medicineName': nameCtrl.text.trim(),

                'activeIngredient': activeCtrl.text.trim(),

                'medicineType': typeCtrl.text.trim(),

                'unit': unitCtrl.text.trim(),

                'price': double.tryParse(priceCtrl.text) ?? 5000.0,

                'stockQuantity': int.tryParse(stockCtrl.text) ?? 100,

                'minStockLevel': int.tryParse(warnCtrl.text) ?? 20,

                'status': 'Active',
              };

              Navigator.pop(context);

              if (medicine != null) {
                controller.updateMedicine(
                  medicine['medicineId'] ?? medicine['id'],
                  payload,
                );
              } else {
                controller.createMedicine(payload);
              }
            },

            child: const Text(
              'Lưu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Thêm / Sửa Lịch trực bác sĩ (Single)

  void _showScheduleForm(
    dynamic schedule,
    AdminDashboardController controller,
    Color primaryColor,
  ) {
    final dateCtrl = TextEditingController(
      text: schedule != null
          ? _safeDate(schedule['workDate'])
          : DateTime.now().toIso8601String().substring(0, 10),
    );

    final startCtrl = TextEditingController(
      text: schedule != null
          ? schedule['startTime']?.toString().substring(0, 5)
          : '08:00',
    );

    final endCtrl = TextEditingController(
      text: schedule != null
          ? schedule['endTime']?.toString().substring(0, 5)
          : '11:00',
    );

    final durationCtrl = TextEditingController(
      text: schedule != null
          ? schedule['slotDurationMinutes']?.toString()
          : '30',
    );

    int selectedDocId = schedule != null
        ? (schedule['doctorId'] ?? 1)
        : (controller.doctors.isNotEmpty
              ? controller.doctors[0]['doctorId'] ?? controller.doctors[0]['id']
              : 1);

    bool isAvailable = schedule != null
        ? (schedule['isAvailable'] != false && schedule['IsAvailable'] != false)
        : true;

    showDialog(
      context: context,

      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: Text(
            schedule != null ? 'Cập nhật ca trực' : 'Thêm ca trực mới',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                DropdownButtonFormField<int>(
                  value: selectedDocId,

                  decoration: const InputDecoration(labelText: 'Bác sĩ trực'),

                  items: controller.doctors.map<DropdownMenuItem<int>>((d) {
                    final id = d['doctorId'] ?? d['id'];

                    return DropdownMenuItem<int>(
                      value: id,

                      child: Text(d['doctorName'] ?? d['fullName'] ?? 'Bác sĩ'),
                    );
                  }).toList(),

                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedDocId = val);
                  },
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ngày trực (YYYY-MM-DD)',
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: startCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Giờ bắt đầu (HH:MM)',
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: endCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Giờ kết thúc (HH:MM)',
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: durationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Thời lượng slot (phút)',
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 8),

                SwitchListTile(
                  title: const Text(
                    'Nhận lịch hẹn',
                    style: TextStyle(fontSize: 14),
                  ),

                  value: isAvailable,

                  onChanged: (val) => setDialogState(() => isAvailable = val),

                  activeColor: primaryColor,
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),

            TextButton(
              onPressed: () {
                final payload = {
                  'doctorId': selectedDocId,

                  'workDate': dateCtrl.text.trim(),

                  'startTime': startCtrl.text.trim(),

                  'endTime': endCtrl.text.trim(),

                  'slotDurationMinutes': int.tryParse(durationCtrl.text) ?? 30,

                  'isAvailable': isAvailable,
                };

                Navigator.pop(context);

                if (schedule != null) {
                  controller.updateSchedule(
                    schedule['scheduleId'] ?? schedule['id'],
                    payload,
                  );
                } else {
                  controller.createSchedule(payload);
                }
              },

              child: const Text(
                'Lưu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tạo Lịch làm việc hàng loạt (Bulk Schedules Form)

  void _showBulkScheduleForm(
    AdminDashboardController controller,
    Color primaryColor,
  ) {
    final startCtrl = TextEditingController(text: '08:00');

    final endCtrl = TextEditingController(text: '17:00');

    final durationCtrl = TextEditingController(text: '30');

    final fromDateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );

    final toDateCtrl = TextEditingController(
      text: DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String()
          .substring(0, 10),
    );

    int selectedDocId = controller.doctors.isNotEmpty
        ? controller.doctors[0]['doctorId'] ?? controller.doctors[0]['id']
        : 1;

    List<int> selectedDays = [1, 2, 3, 4, 5]; // Mặc định Thứ 2 đến Thứ 6

    final List<Map<String, dynamic>> weekdayList = [
      {'val': 1, 'label': 'Thứ 2'},

      {'val': 2, 'label': 'Thứ 3'},

      {'val': 3, 'label': 'Thứ 4'},

      {'val': 4, 'label': 'Thứ 5'},

      {'val': 5, 'label': 'Thứ 6'},

      {'val': 6, 'label': 'Thứ 7'},

      {'val': 7, 'label': 'Chủ Nhật'},
    ];

    showDialog(
      context: context,

      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: const Text(
            'Tạo lịch hàng loạt',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                DropdownButtonFormField<int>(
                  value: selectedDocId,

                  decoration: const InputDecoration(labelText: 'Bác sĩ trực'),

                  items: controller.doctors.map<DropdownMenuItem<int>>((d) {
                    final id = d['doctorId'] ?? d['id'];

                    return DropdownMenuItem<int>(
                      value: id,

                      child: Text(d['doctorName'] ?? d['fullName'] ?? 'Bác sĩ'),
                    );
                  }).toList(),

                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedDocId = val);
                  },
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: fromDateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Từ ngày (YYYY-MM-DD)',
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: toDateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Đến ngày (YYYY-MM-DD)',
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Áp dụng cho các thứ:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 6),

                Wrap(
                  spacing: 6,

                  runSpacing: 6,

                  children: weekdayList.map((item) {
                    final int val = item['val'];

                    final bool isSelected = selectedDays.contains(val);

                    return ChoiceChip(
                      label: Text(item['label']),

                      selected: isSelected,

                      selectedColor: primaryColor.withOpacity(0.2),

                      checkmarkColor: primaryColor,

                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            selectedDays.add(val);
                          } else {
                            selectedDays.remove(val);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: startCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Giờ bắt đầu (HH:MM)',
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: endCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Giờ kết thúc (HH:MM)',
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: durationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Thời lượng slot (phút)',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),

            TextButton(
              onPressed: () {
                final fromDate =
                    DateTime.tryParse(fromDateCtrl.text.trim()) ??
                    DateTime.now();

                final toDate =
                    DateTime.tryParse(toDateCtrl.text.trim()) ??
                    DateTime.now().add(const Duration(days: 7));

                final duration = int.tryParse(durationCtrl.text) ?? 30;

                Navigator.pop(context);

                controller.createBulkSchedules(
                  selectedDocId,

                  selectedDays,

                  fromDate,

                  toDate,

                  startCtrl.text.trim(),

                  endCtrl.text.trim(),

                  duration,
                );
              },

              child: const Text(
                'Tạo ca trực',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Thêm / Sửa Tài khoản người dùng

  void _showAccountForm(
    dynamic account,
    AdminDashboardController controller,
    Color primaryColor,
  ) {
    final nameCtrl = TextEditingController(
      text: account != null ? account['fullName'] : '',
    );

    final userCtrl = TextEditingController(
      text: account != null ? account['username'] : '',
    );

    final emailCtrl = TextEditingController(
      text: account != null ? account['email'] : '',
    );

    final phoneCtrl = TextEditingController(
      text: account != null ? account['phoneNumber'] : '',
    );

    final passCtrl = TextEditingController(text: '');

    String selectedRole = 'Patient';

    if (account != null) {
      final r = (account['roleName'] ?? account['role'] ?? 'Patient')
          .toString()
          .toLowerCase();

      if (r.contains('admin')) {
        selectedRole = 'Admin';
      } else if (r.contains('doctor')) {
        selectedRole = 'Doctor';
      } else if (r.contains('nurse')) {
        selectedRole = 'Nurse';
      } else {
        selectedRole = 'Patient';
      }
    }

    showDialog(
      context: context,

      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: Text(
            account != null ? 'Cập nhật tài khoản' : 'Thêm tài khoản mới',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên người dùng',
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: userCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username (Tên đăng nhập)',
                  ),
                  enabled: account == null,
                ),

                const SizedBox(height: 8),

                if (account == null) ...[
                  TextField(
                    controller: passCtrl,
                    decoration: const InputDecoration(labelText: 'Mật khẩu'),
                    obscureText: true,
                  ),

                  const SizedBox(height: 8),
                ],

                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: selectedRole,

                  decoration: const InputDecoration(
                    labelText: 'Vai trò phân quyền',
                  ),

                  items: const [
                    DropdownMenuItem(
                      value: 'Admin',
                      child: Text('Admin (Quản trị viên)'),
                    ),

                    DropdownMenuItem(
                      value: 'Doctor',
                      child: Text('Doctor (Bác sĩ)'),
                    ),

                    DropdownMenuItem(
                      value: 'Nurse',
                      child: Text('Nurse (Y tá)'),
                    ),

                    DropdownMenuItem(
                      value: 'Patient',
                      child: Text('Patient (Bệnh nhân)'),
                    ),
                  ],

                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRole = val);
                  },
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),

            TextButton(
              onPressed: () {
                final payload = {
                  'fullName': nameCtrl.text.trim(),

                  'username': userCtrl.text.trim(),

                  if (account == null) 'password': passCtrl.text,

                  'email': emailCtrl.text.trim(),

                  'phoneNumber': phoneCtrl.text.trim(),

                  'role': selectedRole,

                  'roleName': selectedRole,

                  'status': 'Active',
                };

                Navigator.pop(context);

                if (account != null) {
                  controller.updateUser(
                    account['userId'] ?? account['id'],
                    payload,
                  );
                } else {
                  controller.createUser(payload);
                }
              },

              child: const Text(
                'Lưu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Thêm / Sửa Y tá

  void _showNurseForm(
    dynamic nurse,
    AdminDashboardController controller,
    Color primaryColor,
  ) {
    final nameCtrl = TextEditingController(
      text: nurse != null ? nurse['fullName'] : '',
    );

    final userCtrl = TextEditingController(
      text: nurse != null ? nurse['username'] : '',
    );

    final emailCtrl = TextEditingController(
      text: nurse != null ? nurse['email'] : '',
    );

    final phoneCtrl = TextEditingController(
      text: nurse != null ? nurse['phoneNumber'] : '',
    );

    final passCtrl = TextEditingController(text: '');

    showDialog(
      context: context,

      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        title: Text(
          nurse != null ? 'Cập nhật y tá' : 'Thêm y tá mới',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Họ tên y tá'),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: userCtrl,
                decoration: const InputDecoration(labelText: 'Username'),
                enabled: nurse == null,
              ),

              const SizedBox(height: 8),

              if (nurse == null) ...[
                TextField(
                  controller: passCtrl,
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  obscureText: true,
                ),

                const SizedBox(height: 8),
              ],

              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
              ),
            ],
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),

          TextButton(
            onPressed: () {
              final payload = {
                'fullName': nameCtrl.text.trim(),

                'username': userCtrl.text.trim(),

                if (nurse == null) 'password': passCtrl.text,

                'email': emailCtrl.text.trim(),

                'phoneNumber': phoneCtrl.text.trim(),

                'role': 'Nurse',

                'roleName': 'Nurse',

                'status': 'Active',
              };

              Navigator.pop(context);

              if (nurse != null) {
                controller.updateUser(nurse['userId'] ?? nurse['id'], payload);
              } else {
                controller.createUser(payload);
              }
            },

            child: const Text(
              'Lưu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDoctorDetails(dynamic doctor, Color primaryColor) {
    final String name =
        doctor['doctorName'] ?? doctor['fullName'] ?? 'Chưa cập nhật';

    final String specialty = doctor['specialtyName'] ?? 'Chưa cập nhật';

    final String degree = doctor['degree'] ?? 'Chưa cập nhật';

    final String room = doctor['roomNumber'] ?? 'Chưa cập nhật';

    final double fee = (doctor['examFee'] ?? 0.0).toDouble();

    final int exp = doctor['experienceYears'] ?? 0;

    final String phone = doctor['phone'] ?? 'Chưa cập nhật';

    final String email = doctor['email'] ?? 'Chưa cập nhật';

    final String gender =
        (doctor['gender'] == 'Female' ||
            doctor['gender'] == 'Nữ' ||
            doctor['gender'] == 'female' ||
            doctor['gender'] == 'nữ')
        ? 'Nữ'
        : 'Nam';

    final bool isActive = doctor['isActive'] ?? true;

    showDialog(
      context: context,

      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),

        title: Row(
          children: [
            Icon(Icons.badge_outlined, color: primaryColor),

            const SizedBox(width: 8),

            const Text(
              'Chi tiết Bác sĩ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),

        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              _buildDetailRow('Họ tên:', name),

              _buildDetailRow('Chuyên khoa:', specialty),

              _buildDetailRow('Học vị:', degree),

              _buildDetailRow('Kinh nghiệm:', '$exp năm'),

              _buildDetailRow('Phòng khám:', room),

              _buildDetailRow(
                'Phí khám:',
                '${NumberFormatSimple.format(fee)}đ',
              ),

              _buildDetailRow('Số điện thoại:', phone),

              _buildDetailRow('Email:', email),

              _buildDetailRow('Giới tính:', gender),

              _buildDetailRow(
                'Trạng thái:',
                isActive ? 'Đang hoạt động' : 'Tạm ngưng',
                valueColor: isActive ? Colors.green : Colors.red,
              ),
            ],
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),

            child: const Text(
              'Đóng',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),

          const Divider(height: 12),
        ],
      ),
    );
  }

  // --- HỘP THOẠI THAO TÁC NHANH TRÊN DASHBOARD ---

  void _showAppointmentActionDialog(
    BuildContext context,

    dynamic apt,

    AdminDashboardController controller,

    Color primaryColor,
  ) {
    final int id = apt['appointmentId'] ?? apt['id'] ?? 0;

    final String code = 'LH-$id';

    final String patient =
        apt['patientName'] ?? apt['patientNameSnapshot'] ?? 'Bệnh nhân';

    final String patientPhone =
        apt['patientPhone'] ?? apt['patientPhoneSnapshot'] ?? 'Chưa cập nhật';

    final String doctor = apt['doctorName'] ?? 'Bác sĩ';

    final String specialty = apt['specialtyName'] ?? 'Không rõ';

    final double fee = apt['examFee'] != null
        ? (apt['examFee'] as num).toDouble()
        : 0.0;

    final String date = _safeDate(apt['appointmentDate']);

    final String time = apt['slotTime'] ?? '00:00';

    final String status = apt['status'] ?? 'Pending';

    final String reason = apt['reason'] ?? 'Khám tổng quát';

    final String queueNum = apt['queueNumber'] != null
        ? apt['queueNumber'].toString()
        : 'Chưa cấp';

    final String cancelReason = apt['cancelReason'] ?? 'Không có';

    final String createdAt = _formatDateTimeVN(apt['createdAt']);

    final String? checkedInAt = apt['checkedInAt'] != null
        ? _formatDateTimeVN(apt['checkedInAt'])
        : null;

    final String? startedAt = apt['startedAt'] != null
        ? _formatDateTimeVN(apt['startedAt'])
        : null;

    final String? completedAt = apt['completedAt'] != null
        ? _formatDateTimeVN(apt['completedAt'])
        : null;

    String docDisplay = doctor;

    if (!docDisplay.startsWith(
      RegExp(r'^(BS\.|BS|Bác sĩ|bs\.|bs|bác sĩ)', caseSensitive: false),
    )) {
      docDisplay = 'BS. $docDisplay';
    }

    Color stColor = Colors.orange;

    String stText = 'Đang chờ';

    if (status == 'Completed') {
      stColor = Colors.green;

      stText = 'Hoàn tất';
    } else if (status == 'CheckedIn') {
      stColor = Colors.blue;

      stText = 'Đã check-in';
    } else if (status == 'Cancelled') {
      stColor = Colors.red;

      stText = 'Đã hủy';
    }

    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),

          title: Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: primaryColor),

              const SizedBox(width: 8),

              const Text(
                'Chi tiết Lịch hẹn',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                _buildDetailRow('Mã lịch hẹn:', code),

                _buildDetailRow('Số thứ tự khám:', queueNum),

                _buildDetailRow('Bệnh nhân:', patient),

                _buildDetailRow('Số điện thoại:', patientPhone),

                _buildDetailRow('Bác sĩ khám:', docDisplay),

                _buildDetailRow('Chuyên khoa:', specialty),

                _buildDetailRow(
                  'Phí khám:',
                  '${NumberFormatSimple.format(fee)}đ',
                ),

                _buildDetailRow(
                  'Thời gian hẹn:',
                  '${_formatDateVN(date)} lúc $time',
                ),

                _buildDetailRow('Trạng thái:', stText, valueColor: stColor),

                _buildDetailRow('Lý do khám / Triệu chứng:', reason),

                if (status == 'Cancelled')
                  _buildDetailRow(
                    'Lý do hủy:',
                    cancelReason,
                    valueColor: Colors.red,
                  ),

                _buildDetailRow('Ngày đặt lịch:', createdAt),

                if (checkedInAt != null)
                  _buildDetailRow('Thời gian check-in:', checkedInAt),

                if (startedAt != null)
                  _buildDetailRow('Bắt đầu khám:', startedAt),

                if (completedAt != null)
                  _buildDetailRow('Hoàn thành khám:', completedAt),
              ],
            ),
          ),

          actionsAlignment: MainAxisAlignment.spaceBetween,

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                setState(() {
                  _selectedMenuIndex = 5; // Đi tới Quản lý lịch hẹn
                });
              },

              child: const Text(
                'Đi tới Quản lý',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),

            Row(
              children: [
                if (status == 'Pending') ...[
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);

                      final String? reasonInput = await showDialog<String>(
                        context: context,

                        builder: (context) {
                          final textController = TextEditingController();

                          return AlertDialog(
                            title: const Text('Lý do hủy lịch'),

                            content: TextField(
                              controller: textController,

                              decoration: const InputDecoration(
                                hintText: 'Nhập lý do hủy...',
                              ),
                            ),

                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),

                                child: const Text('Hủy bỏ'),
                              ),

                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, textController.text),

                                child: const Text('Xác nhận'),
                              ),
                            ],
                          );
                        },
                      );

                      if (reasonInput != null) {
                        try {
                          await controller.cancelAppointment(id, reasonInput);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã hủy lịch hẹn thành công'),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                        }
                      }
                    },

                    child: const Text(
                      'Hủy lịch',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);

                      try {
                        await controller.confirmAppointment(id);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã xác nhận lịch hẹn thành công'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                      }
                    },

                    child: const Text(
                      'Xác nhận',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else if (status == 'Confirmed' || status == 'Approved') ...[
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);

                      try {
                        await controller.checkInAppointment(apt);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Tiếp nhận bệnh nhân check-in thành công',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Lỗi: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },

                    child: const Text(
                      'Check-in',
                      style: TextStyle(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else if (status == 'CheckedIn') ...[
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);

                      _showUpdateVitalsDialog(context, id, controller);
                    },

                    child: const Text(
                      'Nhập sinh hiệu',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                TextButton(
                  onPressed: () => Navigator.pop(context),

                  child: const Text('Đóng'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showUpdateVitalsDialog(
    BuildContext context,
    int appointmentId,
    AdminDashboardController controller,
  ) {
    showDialog(
      context: context,

      barrierDismissible: false,

      builder: (context) {
        bool isLoading = true;

        Map<String, dynamic>? visit;

        String? fetchError;

        final formKey = GlobalKey<FormState>();

        final tempCtrl = TextEditingController();

        final bpCtrl = TextEditingController();

        final hrCtrl = TextEditingController();

        final rrCtrl = TextEditingController();

        final spo2Ctrl = TextEditingController();

        final hCtrl = TextEditingController();

        final wCtrl = TextEditingController();

        final noteCtrl = TextEditingController();

        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Fetch visit details on first builder run

            if (isLoading && fetchError == null && visit == null) {
              Future.microtask(() async {
                final result = await controller.getVisitByAppointment(
                  appointmentId,
                );

                if (result == null) {
                  setDialogState(() {
                    isLoading = false;

                    fetchError =
                        'Không tìm thấy lượt khám tương ứng hoặc có lỗi xảy ra.';
                  });
                } else {
                  visit = result;

                  // Pre-fill controllers

                  dynamic vitals = {};

                  try {
                    if (result['vitalSignsJson'] != null) {
                      vitals = jsonDecode(result['vitalSignsJson']);
                    }
                  } catch (_) {}

                  tempCtrl.text =
                      (result['temperature'] ??
                              vitals['temperature'] ??
                              vitals['Temperature'] ??
                              '')
                          .toString();

                  bpCtrl.text =
                      (result['bloodPressure'] ??
                              vitals['bloodPressure'] ??
                              vitals['BloodPressure'] ??
                              '')
                          .toString();

                  hrCtrl.text =
                      (result['heartRate'] ??
                              vitals['heartRate'] ??
                              vitals['HeartRate'] ??
                              '')
                          .toString();

                  rrCtrl.text =
                      (result['respiratoryRate'] ??
                              vitals['respiratoryRate'] ??
                              vitals['RespiratoryRate'] ??
                              '')
                          .toString();

                  spo2Ctrl.text =
                      (result['spo2'] ?? vitals['spo2'] ?? vitals['Spo2'] ?? '')
                          .toString();

                  hCtrl.text =
                      (result['height'] ??
                              vitals['height'] ??
                              vitals['Height'] ??
                              '')
                          .toString();

                  wCtrl.text =
                      (result['weight'] ??
                              vitals['weight'] ??
                              vitals['Weight'] ??
                              '')
                          .toString();

                  noteCtrl.text =
                      (result['note'] ?? vitals['note'] ?? vitals['Note'] ?? '')
                          .toString();

                  setDialogState(() {
                    isLoading = false;
                  });
                }
              });
            }

            if (isLoading) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),

                content: const SizedBox(
                  height: 100,

                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (fetchError != null) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),

                title: const Text(
                  'Lỗi tải dữ liệu',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                content: Text(fetchError!),

                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),

                    child: const Text('Đóng'),
                  ),
                ],
              );
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),

              title: const Row(
                children: [
                  Icon(Icons.favorite_rounded, color: Colors.blue),

                  SizedBox(width: 8),

                  Text(
                    'Nhập Sinh hiệu Bệnh nhân',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),

              content: SizedBox(
                width: double.maxFinite,

                child: Form(
                  key: formKey,

                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        const Text(
                          'Vui lòng điền đầy đủ các thông tin sinh hiệu dưới đây để cập nhật hồ sơ khám bệnh.',

                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: tempCtrl,

                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),

                                decoration: const InputDecoration(
                                  labelText: 'Nhiệt độ (°C) *',

                                  hintText: 'Ví dụ: 36.5',

                                  border: OutlineInputBorder(),
                                ),

                                validator: (value) {
                                  if (value == null || value.trim().isEmpty)
                                    return 'Bắt đầu từ 30';

                                  final numVal = double.tryParse(value);

                                  if (numVal == null ||
                                      numVal < 30 ||
                                      numVal > 45) {
                                    return 'Khoảng 30 - 45°C';
                                  }

                                  return null;
                                },
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: TextFormField(
                                controller: bpCtrl,

                                keyboardType: TextInputType.text,

                                decoration: const InputDecoration(
                                  labelText: 'Huyết áp (mmHg) *',

                                  hintText: 'Ví dụ: 120/80',

                                  border: OutlineInputBorder(),
                                ),

                                validator: (value) {
                                  if (value == null || value.trim().isEmpty)
                                    return 'Bắt buộc';

                                  final regExp = RegExp(
                                    r'^\d{2,3}\s*/\s*\d{2,3}$',
                                  );

                                  if (!regExp.hasMatch(value.trim())) {
                                    return 'Dạng: 120/80';
                                  }

                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: hrCtrl,

                                keyboardType: TextInputType.number,

                                decoration: const InputDecoration(
                                  labelText: 'Mạch (lần/phút) *',

                                  hintText: 'Ví dụ: 80',

                                  border: OutlineInputBorder(),
                                ),

                                validator: (value) {
                                  if (value == null || value.trim().isEmpty)
                                    return 'Bắt buộc';

                                  final numVal = int.tryParse(value);

                                  if (numVal == null ||
                                      numVal < 1 ||
                                      numVal > 250) {
                                    return 'Khoảng 1 - 250';
                                  }

                                  return null;
                                },
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: TextFormField(
                                controller: rrCtrl,

                                keyboardType: TextInputType.number,

                                decoration: const InputDecoration(
                                  labelText: 'Nhịp thở (lần/phút) *',

                                  hintText: 'Ví dụ: 18',

                                  border: OutlineInputBorder(),
                                ),

                                validator: (value) {
                                  if (value == null || value.trim().isEmpty)
                                    return 'Bắt buộc';

                                  final numVal = int.tryParse(value);

                                  if (numVal == null ||
                                      numVal < 1 ||
                                      numVal > 100) {
                                    return 'Khoảng 1 - 100';
                                  }

                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: hCtrl,

                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),

                                decoration: const InputDecoration(
                                  labelText: 'Chiều cao (cm) *',

                                  hintText: 'Ví dụ: 170',

                                  border: OutlineInputBorder(),
                                ),

                                validator: (value) {
                                  if (value == null || value.trim().isEmpty)
                                    return 'Bắt buộc';

                                  final numVal = double.tryParse(value);

                                  if (numVal == null ||
                                      numVal < 1 ||
                                      numVal > 300) {
                                    return 'Khoảng 1 - 300';
                                  }

                                  return null;
                                },
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: TextFormField(
                                controller: wCtrl,

                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),

                                decoration: const InputDecoration(
                                  labelText: 'Cân nặng (kg) *',

                                  hintText: 'Ví dụ: 65',

                                  border: OutlineInputBorder(),
                                ),

                                validator: (value) {
                                  if (value == null || value.trim().isEmpty)
                                    return 'Bắt buộc';

                                  final numVal = double.tryParse(value);

                                  if (numVal == null ||
                                      numVal < 1 ||
                                      numVal > 500) {
                                    return 'Khoảng 1 - 500';
                                  }

                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        TextFormField(
                          controller: spo2Ctrl,

                          keyboardType: TextInputType.number,

                          decoration: const InputDecoration(
                            labelText: 'Chỉ số SpO2 (%) *',

                            hintText: 'Ví dụ: 98',

                            border: OutlineInputBorder(),
                          ),

                          validator: (value) {
                            if (value == null || value.trim().isEmpty)
                              return 'Bắt buộc';

                            final numVal = int.tryParse(value);

                            if (numVal == null || numVal < 1 || numVal > 100) {
                              return 'Khoảng 1 - 100';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        TextFormField(
                          controller: noteCtrl,

                          keyboardType: TextInputType.text,

                          maxLines: 3,

                          decoration: const InputDecoration(
                            labelText: 'Ghi chú sinh hiệu (tùy chọn)',

                            hintText: 'Nhập ghi chú sinh hiệu...',

                            border: OutlineInputBorder(),
                          ),

                          validator: (value) {
                            if (value != null && value.length > 500) {
                              return 'Ghi chú tối đa 500 ký tự';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),

                  child: const Text(
                    'Hủy bỏ',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,

                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() {
                              isSaving = true;
                            });

                            final payload = {
                              'temperature': double.parse(tempCtrl.text),

                              'bloodPressure': bpCtrl.text.trim(),

                              'heartRate': int.parse(hrCtrl.text),

                              'respiratoryRate': int.parse(rrCtrl.text),

                              'spo2': int.parse(spo2Ctrl.text),

                              'height': double.parse(hCtrl.text),

                              'weight': double.parse(wCtrl.text),

                              'note': noteCtrl.text.trim().isNotEmpty
                                  ? noteCtrl.text.trim()
                                  : null,
                            };

                            try {
                              final visitId = visit!['visitId'] ?? visit!['id'];

                              await controller.updateVisitVitals(
                                visitId,
                                payload,
                              );

                              if (context.mounted) {
                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Cập nhật chỉ số sinh hiệu thành công',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              setDialogState(() {
                                isSaving = false;
                              });

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },

                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Lưu chỉ số'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPatientDetailsDialog(BuildContext context, dynamic patient) {
    final String name = patient['fullName'] ?? patient['name'] ?? 'Bệnh nhân';

    final int id = patient['patientId'] ?? patient['id'] ?? 0;

    final String code = 'BN-$id';

    final String phone =
        patient['phoneNumber'] ?? patient['phone'] ?? 'Không có SĐT';

    final String email = patient['email'] ?? 'Chưa cập nhật';

    final String gender =
        (patient['gender'] == 'Female' ||
            patient['gender'] == 'Nữ' ||
            patient['gender'] == 'female')
        ? 'Nữ'
        : 'Nam';

    final String dob = patient['dateOfBirth'] != null
        ? _formatDateVN(_formatDobForInput(patient['dateOfBirth']))
        : 'Chưa cập nhật';

    final String address = patient['address'] ?? 'Chưa cập nhật';

    final String citizenId =
        patient['citizenId'] ?? patient['nationalId'] ?? 'Chưa cập nhật';

    final String bloodType = patient['bloodType'] ?? 'O';

    final String history = patient['medicalHistory'] ?? 'Không tiền sử bệnh án';

    final String allergy = patient['allergyNote'] ?? 'Không dị ứng';

    showDialog(
      context: context,

      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),

        title: const Row(
          children: [
            Icon(Icons.person_pin_rounded, color: Colors.blue),

            const SizedBox(width: 8),

            const Text(
              'Hồ sơ Bệnh nhân',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),

        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              _buildDetailRow('Mã số bệnh nhân:', code),

              _buildDetailRow('Họ và tên:', name),

              _buildDetailRow('Số điện thoại:', phone),

              _buildDetailRow('Email:', email),

              _buildDetailRow('Giới tính:', gender),

              _buildDetailRow('Ngày sinh:', dob),

              _buildDetailRow('Số CCCD/CMND:', citizenId),

              _buildDetailRow('Nhóm máu:', bloodType),

              _buildDetailRow('Địa chỉ thường trú:', address),

              _buildDetailRow('Tiền sử bệnh án:', history),

              _buildDetailRow('Ghi chú dị ứng:', allergy),
            ],
          ),
        ),

        actionsAlignment: MainAxisAlignment.spaceBetween,

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              setState(() {
                _selectedMenuIndex = 4; // Đi tới Quản lý bệnh nhân
              });
            },

            child: const Text(
              'Đi tới Quản lý',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),

          TextButton(
            onPressed: () => Navigator.pop(context),

            child: const Text(
              'Đóng',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showBillActionDialog(
    BuildContext context,

    dynamic bill,

    AdminDashboardController controller,

    Color primaryColor,
  ) {
    final int id = bill['billId'] ?? bill['id'] ?? 0;

    final String billCode = 'HD-$id';

    final String aptRef = 'LH-${bill['appointmentId'] ?? 0}';

    final double amount = (bill['amount'] ?? 0.0).toDouble();

    final String status = bill['status']?.toString().toLowerCase() ?? '';

    final isPaid = status == 'paid' || status == 'paidoffline';

    showDialog(
      context: context,

      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),

        title: Row(
          children: [
            Icon(Icons.receipt_long_rounded, color: primaryColor),

            const SizedBox(width: 8),

            const Text(
              'Chi tiết Hóa đơn',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),

        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              _buildDetailRow('Mã hóa đơn:', billCode),

              _buildDetailRow('Mã lịch hẹn tham chiếu:', aptRef),

              _buildDetailRow(
                'Số tiền phải thu:',
                '${NumberFormatSimple.format(amount)} đ',
              ),

              _buildDetailRow(
                'Trạng thái thanh toán:',
                isPaid ? 'Đã thu tiền' : 'Chưa thu tiền',
                valueColor: isPaid ? Colors.green : Colors.red,
              ),
            ],
          ),
        ),

        actionsAlignment: MainAxisAlignment.spaceBetween,

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              setState(() {
                _selectedMenuIndex = 8; // Đi tới Hóa đơn viện phí
              });
            },

            child: const Text(
              'Đi tới Quản lý',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),

          Row(
            children: [
              if (!isPaid)
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);

                    try {
                      await controller.confirmPayment(id);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã xác nhận thu tiền mặt thành công'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    }
                  },

                  child: const Text(
                    'Thu tiền mặt',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              TextButton(
                onPressed: () => Navigator.pop(context),

                child: const Text('Đóng'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDogkyTipsDialog(
    BuildContext context,

    AdminDashboardController controller,

    int completedToday,

    int lowStockCount,
  ) {
    showDialog(
      context: context,

      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),

        title: const Row(
          children: [
            Icon(Icons.pets_rounded, color: Colors.blue),

            const SizedBox(width: 8),

            const Text(
              'Dogky AI Trợ lý',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),

        content: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Image.network(
              'https://cdn-icons-png.flaticon.com/512/10260/10260336.png',

              width: 90,

              height: 90,

              fit: BoxFit.contain,

              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.pets, color: Colors.blue, size: 40),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),

              decoration: BoxDecoration(
                color: Colors.blue.shade50,

                borderRadius: BorderRadius.circular(16),
              ),

              child: Text(
                'Gâu! Hôm nay bệnh viện của chúng ta có ${controller.appointments.length} lịch khám. '
                'Trong đó đã hoàn thành $completedToday ca khám rồi đó nha! '
                '${lowStockCount > 0 ? "Gâu gâu! Em phát hiện thấy có $lowStockCount thuốc sắp hết hàng trong kho. Nhắc dược sĩ nhập thêm ngay nhé!" : "Mọi thứ trong kho thuốc đều đầy đủ, gâu!"} '
                'Chúc Admin một ngày làm việc tràn đầy năng lượng!',

                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Colors.black87,
                ),

                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),

            child: const Text(
              'Cảm ơn Dogky!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSpecialtyDetailsDialog(
    BuildContext context,

    dynamic spec,

    AdminDashboardController controller,

    Color specColor,

    IconData specIcon,
  ) {
    final String name = spec['specialtyName'] ?? 'Chuyên khoa';

    final int id = spec['specialtyId'] ?? spec['id'] ?? 0;

    // Tìm các bác sĩ thuộc khoa này

    final docs = controller.doctors.where((d) {
      final sId = d['specialtyId'];

      final sName = d['specialtyName']?.toString().toLowerCase() ?? '';

      return sId == id || sName == name.toLowerCase();
    }).toList();

    // Tìm các ca trực thuộc khoa này

    final shifts = controller.schedules.where((s) {
      final sId = s['specialtyId'];

      final sName = s['specialtyName']?.toString().toLowerCase() ?? '';

      return sId == id || sName == name.toLowerCase();
    }).toList();

    showDialog(
      context: context,

      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),

        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),

              decoration: BoxDecoration(
                color: specColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),

              child: Icon(specIcon, color: specColor, size: 20),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                name,

                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),

                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        content: SizedBox(
          width: double.maxFinite,

          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              mainAxisSize: MainAxisSize.min,

              children: [
                _buildDetailRow('Mã chuyên khoa:', 'CK-$id'),

                const SizedBox(height: 8),

                Text(
                  'Danh sách bác sĩ (${docs.length}):',

                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 6),

                if (docs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),

                    child: Text(
                      'Chưa phân bổ bác sĩ nào cho chuyên khoa này.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,

                    physics: const NeverScrollableScrollPhysics(),

                    itemCount: docs.length,

                    itemBuilder: (context, idx) {
                      final doc = docs[idx];

                      final dName =
                          doc['doctorName'] ?? doc['fullName'] ?? 'Bác sĩ';

                      final dPhone = doc['phoneNumber'] ?? 'Không có SĐT';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),

                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,

                              backgroundImage: NetworkImage(
                                _getDoctorAvatarUrl(doc),
                              ),
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Text(
                                    dName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  Text(
                                    dPhone,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const Divider(height: 24),

                Text(
                  'Lịch trực chuyên khoa (${shifts.length}):',

                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 6),

                if (shifts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),

                    child: Text(
                      'Chưa có ca trực nào được lên lịch.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,

                    physics: const NeverScrollableScrollPhysics(),

                    itemCount: shifts.length.clamp(0, 5),

                    itemBuilder: (context, idx) {
                      final s = shifts[idx];

                      final dName = s['doctorName'] ?? 'Bác sĩ';

                      final date = _safeDate(s['workDate']);

                      final start = s['startTime']?.toString() ?? '';

                      final end = s['endTime']?.toString() ?? '';

                      final startStr = start.length >= 5
                          ? start.substring(0, 5)
                          : '--:--';

                      final endStr = end.length >= 5
                          ? end.substring(0, 5)
                          : '--:--';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),

                        child: Text(
                          '• BS. $dName: $date ($startStr - $endStr)',

                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),

            child: const Text(
              'Đóng',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrescriptionDetailsDialog(BuildContext context, dynamic record) {
    final String patient =
        record['patientName'] ?? record['patientNameSnapshot'] ?? 'Bệnh nhân';

    final String doctor =
        record['doctorName'] ?? record['doctorNameSnapshot'] ?? 'Bác sĩ';

    final String diagnosis =
        record['diagnosisText'] ?? record['diagnosis'] ?? 'Khám bệnh';

    final String date = record['createdAt'] != null
        ? record['createdAt'].toString().substring(0, 10)
        : 'Hôm nay';

    final String dateFormatted = _formatDateVN(date);

    // Tìm thuốc trong đơn

    final dynamic rawMedicines =
        record['medicines'] ?? record['details'] ?? record['items'] ?? [];

    List<dynamic> medList = [];

    if (rawMedicines is List) {
      medList = rawMedicines;
    }

    showDialog(
      context: context,

      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),

        title: const Row(
          children: [
            Icon(Icons.receipt_rounded, color: Colors.purple),

            const SizedBox(width: 8),

            const Text(
              'Chi tiết đơn thuốc',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),

        content: SizedBox(
          width: double.maxFinite,

          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              mainAxisSize: MainAxisSize.min,

              children: [
                _buildDetailRow('Bệnh nhân:', patient),

                _buildDetailRow('Bác sĩ chẩn đoán:', doctor),

                _buildDetailRow('Chẩn đoán:', diagnosis),

                _buildDetailRow('Ngày kê đơn:', dateFormatted),

                const SizedBox(height: 8),

                const Text(
                  'Thuốc & Liều dùng chỉ định:',

                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.purple,
                  ),
                ),

                const SizedBox(height: 6),

                if (medList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),

                    child: Text(
                      'Không có chi tiết danh mục thuốc hoặc được kê đơn tự do.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,

                    physics: const NeverScrollableScrollPhysics(),

                    itemCount: medList.length,

                    itemBuilder: (context, idx) {
                      final m = medList[idx];

                      final String mName =
                          m['medicineName'] ?? m['name'] ?? 'Tên thuốc';

                      final String quantity =
                          (m['quantity'] ?? m['amount'] ?? 1).toString();

                      final String instruction =
                          m['instruction'] ??
                          m['dosage'] ??
                          'Theo chỉ định của bác sĩ';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,

                              children: [
                                Text(
                                  '${idx + 1}. $mName',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),

                                Text(
                                  'SL: $quantity',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 2),

                            Text(
                              'Cách dùng: $instruction',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),

                            const Divider(height: 8),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),

            child: const Text(
              'Đóng',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- HÀM PHỤ TRỢ TIỆN ÍCH DÀNH CHO DATE/TIME VÀ WEEKDAY ---

  String _safeDate(dynamic date) {
    if (date == null) return '';

    final str = date.toString();

    return str.length >= 10 ? str.substring(0, 10) : str;
  }

  String _formatDateTimeVN(dynamic val) {
    if (val == null) return 'Chưa cập nhật';

    try {
      final parsed = DateTime.parse(val.toString()).toLocal();

      final date =
          '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';

      final time =
          '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';

      return '$date lúc $time';
    } catch (_) {
      return val.toString();
    }
  }

  String _formatDobForInput(dynamic date) {
    if (date == null) return '';

    try {
      final parsed = DateTime.parse(date.toString()).toLocal();

      return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    } catch (_) {
      final str = date.toString();

      return str.length >= 10 ? str.substring(0, 10) : str;
    }
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
      return '';
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

  String _normalizeName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'^(bs\.|bs|bác sĩ)\s*'), '')
        .trim();
  }

  Widget _buildPrescriptionStatusBadge(String status) {
    Color bg = Colors.amber.withOpacity(0.08);

    Color text = Colors.amber.shade800;

    String label = 'Chờ phát thuốc';

    final normStatus = status.toLowerCase();

    if (normStatus == 'dispensed' || normStatus == 'completed') {
      bg = Colors.green.withOpacity(0.08);

      text = Colors.green;

      label = 'Đã phát thuốc';
    } else if (normStatus == 'cancelled') {
      bg = Colors.red.withOpacity(0.08);

      text = Colors.red;

      label = 'Đã hủy';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),

      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),

      child: Text(
        label,

        style: TextStyle(
          fontSize: 10,
          color: text,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAccountDetailsDialog(
    BuildContext context,

    Map<String, dynamic> acc,

    AdminDashboardController controller,

    Color primaryColor,
  ) {
    final String name = acc['fullName'] ?? 'Người dùng';

    final String username = acc['username'] ?? 'Chưa cấu hình';

    final String email = acc['email'] ?? 'Chưa cấu hình email';

    final String phone =
        acc['phoneNumber'] ?? acc['phone'] ?? 'Chưa cấu hình SĐT';

    final String role = acc['roleName'] ?? acc['role'] ?? 'Patient';

    final String status = acc['status'] ?? 'Active';

    final bool isLocked = status.toLowerCase() == 'locked';

    final int id = acc['userId'] ?? acc['id'] ?? 0;

    final String date = acc['createdAt'] != null
        ? acc['createdAt'].toString().substring(0, 10)
        : '';

    final String dateFormatted = date.isNotEmpty ? _formatDateVN(date) : 'N/A';

    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.manage_accounts_rounded, color: primaryColor),

              const SizedBox(width: 8),

              const Text(
                'Chi tiết tài khoản',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              mainAxisSize: MainAxisSize.min,

              children: [
                _buildAccountDetailRow('Họ và tên:', name, isBold: true),

                _buildAccountDetailRow('Tên đăng nhập:', username),

                _buildAccountDetailRow('Vai trò:', role.toUpperCase()),

                _buildAccountDetailRow(
                  'Trạng thái:',

                  isLocked ? 'ĐÃ KHÓA 🔒' : 'Đang hoạt động ✅',

                  textColor: isLocked ? Colors.red : Colors.green,

                  isBold: true,
                ),

                _buildAccountDetailRow('Email:', email),

                _buildAccountDetailRow('Số điện thoại:', phone),

                _buildAccountDetailRow('Ngày tạo:', dateFormatted),

                // Show extra fields for Doctor
                if (role.toLowerCase() == 'doctor') ...[
                  const Divider(height: 24),

                  const Text(
                    'Thông tin bổ sung Bác sĩ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.blue,
                    ),
                  ),

                  const SizedBox(height: 8),

                  _buildAccountDetailRow(
                    'Chuyên khoa:',
                    acc['specialtyName'] ?? 'N/A',
                  ),

                  _buildAccountDetailRow('Học vị:', acc['degree'] ?? 'N/A'),

                  _buildAccountDetailRow(
                    'Phí khám:',
                    acc['examFee'] != null
                        ? '${NumberFormatSimple.format((acc['examFee'] as num).toDouble())} đ'
                        : 'N/A',
                  ),
                ],
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),

              child: const Text('Đóng'),
            ),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isLocked ? Colors.green : Colors.orange,

                foregroundColor: Colors.white,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              onPressed: () {
                Navigator.pop(context);

                if (isLocked) {
                  _showDeleteConfirm(
                    title: 'Mở khóa tài khoản?',

                    message: 'Mở khóa tài khoản $username?',

                    onConfirm: () => controller.unlockUser(id),
                  );
                } else {
                  _showDeleteConfirm(
                    title: 'Khóa tài khoản?',

                    message:
                        'Khóa tài khoản $username? Người dùng này sẽ không thể đăng nhập vào hệ thống.',

                    onConfirm: () => controller.lockUser(id),
                  );
                }
              },

              icon: Icon(
                isLocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                size: 16,
              ),

              label: Text(isLocked ? 'Mở khóa' : 'Khóa tài khoản'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountDetailRow(
    String label,
    String value, {
    Color? textColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),

          const SizedBox(height: 2),

          Text(
            value,

            style: TextStyle(
              fontSize: 14,

              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,

              color: textColor ?? const Color(0xFF1E293B),
            ),
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildCustomChoiceChip({
    required String label,

    required String value,

    required String selectedValue,

    required ValueChanged<String> onSelected,

    required Color primaryColor,
  }) {
    final isSelected = selectedValue == value;

    return ChoiceChip(
      label: Text(
        label,

        style: TextStyle(
          fontSize: 11,

          fontWeight: FontWeight.bold,

          color: isSelected ? Colors.white : Colors.grey.shade700,
        ),
      ),

      selected: isSelected,

      selectedColor: primaryColor,

      backgroundColor: Colors.white,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),

        side: BorderSide(
          color: isSelected ? primaryColor : Colors.grey.shade200,
        ),
      ),

      checkmarkColor: Colors.white,

      onSelected: (selected) {
        if (selected) {
          onSelected(value);
        }
      },
    );
  }
}

// Lớp hỗ trợ định dạng tiền tệ đơn giản thủ công thay cho package intl

class NumberFormatSimple {
  static String format(double value) {
    final str = value.toInt().toString();

    final buffer = StringBuffer();

    int count = 0;

    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(str[i]);

      count++;
    }

    return buffer.toString().split('').reversed.join('');
  }
}
