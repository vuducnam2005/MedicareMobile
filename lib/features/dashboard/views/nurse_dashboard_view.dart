import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';
import '../controllers/nurse_dashboard_controller.dart';
import '../widgets/role_dashboard_shell.dart';
import '../widgets/weather_greeting_card.dart';
import '../widgets/notification_bell.dart';

class NurseDashboardView extends StatefulWidget {
  const NurseDashboardView({super.key});

  @override
  State<NurseDashboardView> createState() => _NurseDashboardViewState();
}

class _NurseDashboardViewState extends State<NurseDashboardView> {
  static const _primary = Color(0xFF0891B2);
  static const _primaryDark = Color(0xFF0E7490);
  static const _bg = Color(0xFFF8FAFC);
  static const _text = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _success = Color(0xFF10B981);
  static const _pending = Color(0xFFF59E0B);
  static const _danger = Color(0xFFEF4444);
  static const _info = Color(0xFF2563EB);

  int _selectedMenuIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final _aptSearchController = TextEditingController();
  final _patientSearchController = TextEditingController();
  final _billSearchController = TextEditingController();
  final _prescriptionSearchController = TextEditingController();
  final _medicineSearchController = TextEditingController();

  String _aptSearch = '';
  String _patientSearch = '';
  String _queueSearch = '';
  String _billSearch = '';
  String _prescriptionSearch = '';
  String _medicineSearch = '';
  String _slipSearch = '';

  String _aptStatus = 'All';
  String _aptDate = 'Today';
  String _queueStatus = 'All';
  String _billStatus = 'All';
  String _prescriptionStatus = 'All';
  String _medicineStock = 'All';
  String _slipStatus = 'All';

  @override
  void initState() {
    super.initState();
    _aptSearchController.addListener(() {
      setState(() => _aptSearch = _aptSearchController.text);
    });
    _patientSearchController.addListener(() {
      setState(() => _patientSearch = _patientSearchController.text);
    });
    _billSearchController.addListener(() {
      setState(() => _billSearch = _billSearchController.text);
    });
    _prescriptionSearchController.addListener(() {
      setState(() => _prescriptionSearch = _prescriptionSearchController.text);
    });
    _medicineSearchController.addListener(() {
      setState(() => _medicineSearch = _medicineSearchController.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
  }

  @override
  void dispose() {
    _aptSearchController.dispose();
    _patientSearchController.dispose();
    _billSearchController.dispose();
    _prescriptionSearchController.dispose();
    _medicineSearchController.dispose();
    super.dispose();
  }

  void _refreshData() {
    context.read<NurseDashboardController>().loadAllNurseData();
  }

  Future<void> _refreshDataAsync() {
    return context.read<NurseDashboardController>().loadAllNurseData();
  }

  void _changeTab(int index) {
    setState(() {
      _selectedMenuIndex = index;
      _aptSearchController.clear();
      _patientSearchController.clear();
      _billSearchController.clear();
      _prescriptionSearchController.clear();
      _medicineSearchController.clear();
      _aptSearch = '';
      _patientSearch = '';
      _queueSearch = '';
      _billSearch = '';
      _prescriptionSearch = '';
      _medicineSearch = '';
      _slipSearch = '';
      _aptStatus = 'All';
      _aptDate = index == 1 ? 'Today' : 'All';
      _queueStatus = 'All';
      _billStatus = 'All';
      _prescriptionStatus = 'All';
      _medicineStock = 'All';
      _slipStatus = 'All';
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final controller = context.watch<NurseDashboardController>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: Text('Không tìm thấy thông tin người dùng.')),
      );
    }

    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return RoleDashboardShell(
      scaffoldKey: _scaffoldKey,
      title: _title(),
      userName: user.fullName,
      roleLabel: 'Điều phối y tế',
      roleSubtitle: user.email,
      primaryColor: _primary,
      backgroundColor: _bg,
      menuItems: _nurseMenuItems,
      selectedIndex: _selectedMenuIndex,
      onMenuSelected: _changeTab,
      onRefresh: _refreshData,
      onLogout: () => context.read<AuthController>().logout(),
      isLoading:
          controller.isLoading &&
          controller.appointments.isEmpty &&
          controller.patients.isEmpty &&
          controller.queue.isEmpty,
      avatarIcon: Icons.local_hospital_rounded,
      bottomNavigationBar: isWideScreen ? null : _buildBottomNav(context, _primary),
      appBarActions: [
        NotificationBell(
          role: 'Nurse',
          onTabChanged: _changeTab,
        ),
      ],
      body: _buildBody(user, controller),
    );
  }

  int _mapMenuIndexToBottomBarIndex(int menuIndex) {
    switch (menuIndex) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 3:
        return 2;
      case 4:
        return 3;
      case 5:
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
        return 3;
      case 3:
        return 4;
      case 4:
        return 5;
      default:
        return 0;
    }
  }

  Widget _buildBottomNav(BuildContext context, Color primaryColor) {
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
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Tổng quan',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month_rounded),
          label: 'Lịch hẹn',
        ),
        NavigationDestination(
          icon: Icon(Icons.queue_outlined),
          selectedIcon: Icon(Icons.queue_rounded),
          label: 'Hàng đợi',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: 'Thu phí',
        ),
        NavigationDestination(
          icon: Icon(Icons.medication_outlined),
          selectedIcon: Icon(Icons.medication_rounded),
          label: 'Phát thuốc',
        ),
      ],
    );
  }

  static const List<RoleDashboardMenuItem> _nurseMenuItems = [
    RoleDashboardMenuItem(
      title: 'Tổng quan',
      icon: Icons.dashboard_rounded,
      index: 0,
      section: 'Điều phối',
    ),
    RoleDashboardMenuItem(
      title: 'Lịch hẹn',
      icon: Icons.calendar_month_rounded,
      index: 1,
      section: 'Tiếp nhận',
    ),
    RoleDashboardMenuItem(
      title: 'Bệnh nhân',
      icon: Icons.people_alt_rounded,
      index: 2,
      section: 'Tiếp nhận',
    ),
    RoleDashboardMenuItem(
      title: 'Hàng đợi khám',
      icon: Icons.queue_rounded,
      index: 3,
      section: 'Tiếp nhận',
    ),
    RoleDashboardMenuItem(
      title: 'Thu viện phí',
      icon: Icons.receipt_long_rounded,
      index: 4,
      section: 'Dịch vụ',
    ),
    RoleDashboardMenuItem(
      title: 'Phát thuốc',
      icon: Icons.medication_rounded,
      index: 5,
      section: 'Dịch vụ',
    ),
    RoleDashboardMenuItem(
      title: 'Kho thuốc',
      icon: Icons.inventory_2_rounded,
      index: 6,
      section: 'Kho dược',
    ),
    RoleDashboardMenuItem(
      title: 'Nhập kho',
      icon: Icons.assignment_rounded,
      index: 7,
      section: 'Kho dược',
    ),
  ];

  String _title() {
    switch (_selectedMenuIndex) {
      case 1:
        return 'Quản lý lịch hẹn';
      case 2:
        return 'Hồ sơ bệnh nhân';
      case 3:
        return 'Hàng đợi khám';
      case 4:
        return 'Thu viện phí';
      case 5:
        return 'Cấp phát thuốc';
      case 6:
        return 'Kho thuốc';
      case 7:
        return 'Yêu cầu nhập kho';
      default:
        return 'Trung tâm điều phối';
    }
  }

  Widget _buildBody(UserModel user, NurseDashboardController controller) {
    switch (_selectedMenuIndex) {
      case 1:
        return _appointmentsTab(controller);
      case 2:
        return _patientsTab(controller);
      case 3:
        return _queueTab(controller);
      case 4:
        return _billingTab(controller);
      case 5:
        return _prescriptionsTab(controller);
      case 6:
        return _medicinesTab(controller);
      case 7:
        return _slipsTab(controller);
      default:
        return _dashboardTab(user, controller);
    }
  }

  Widget _dashboardTab(UserModel user, NurseDashboardController controller) {
    final today = _todayIso();
    final todayAppointments = controller.appointments
        .where(
          (item) =>
              _safeDate(_value(item, ['appointmentDate', 'scheduledAt'])) ==
              today,
        )
        .toList();
    final waitingQueue = controller.queue
        .where((item) => _bucket(_value(item, ['status'])) == 'pending')
        .toList();
    final unpaidBills = controller.bills
        .where((item) => !_isPaid(item))
        .toList();
    final pendingPrescriptions = controller.prescriptions
        .where((item) => _prescriptionBucket(item) == 'pending')
        .toList();
    final lowStock = controller.medicines.where(_isLowStockMedicine).toList();
    final pendingApts = controller.appointments
        .where(
          (item) => [
            'pending',
            'confirmed',
          ].contains(_bucket(_value(item, ['status']))),
        )
        .toList();

    return RefreshIndicator(
      onRefresh: _refreshDataAsync,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          _commandHeader(user),
          const SizedBox(height: 14),
          _sectionTitle('Truy cập nhanh'),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.72,
            children: [
              _quickCard(
                'Lịch hẹn',
                '${todayAppointments.length} hôm nay',
                Icons.event_available_rounded,
                _info,
                () => _changeTab(1),
              ),
              _quickCard(
                'Bệnh nhân',
                '${controller.patients.length} hồ sơ',
                Icons.people_alt_rounded,
                _primary,
                () => _changeTab(2),
              ),
              _quickCard(
                'Hàng đợi',
                '${controller.queue.length} lượt',
                Icons.queue_rounded,
                const Color(0xFF7C3AED),
                () => _changeTab(3),
              ),
              _quickCard(
                'Thu viện phí',
                '${unpaidBills.length} cần thu',
                Icons.payments_outlined,
                _success,
                () => _changeTab(4),
              ),
              _quickCard(
                'Phát thuốc',
                '${pendingPrescriptions.length} chờ phát',
                Icons.medication_liquid_rounded,
                _pending,
                () => _changeTab(5),
              ),
              _quickCard(
                'Kho thuốc',
                '${lowStock.length} cảnh báo',
                Icons.inventory_2_rounded,
                _danger,
                () => _changeTab(6),
              ),
              _quickCard(
                'Nhập kho',
                '${controller.slips.length} phiếu',
                Icons.assignment_rounded,
                _primaryDark,
                () => _changeTab(7),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _sectionTitle('Tình trạng hôm nay'),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.75,
            children: [
              _metricCard(
                'Lịch hẹn hôm nay',
                '${todayAppointments.length}',
                'cần tiếp nhận',
                Icons.today_rounded,
                _info,
              ),
              _metricCard(
                'Hàng đợi khám',
                '${waitingQueue.length}',
                'đang chờ',
                Icons.queue_play_next_rounded,
                _pending,
              ),
              _metricCard(
                'Hóa đơn chưa thu',
                '${unpaidBills.length}',
                'cần xử lý',
                Icons.receipt_long_rounded,
                _danger,
              ),
              _metricCard(
                'Đơn chờ phát',
                '${pendingPrescriptions.length}',
                'đơn thuốc',
                Icons.medication_rounded,
                _success,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _sectionTitle('Cần xử lý'),
          const SizedBox(height: 10),
          if (pendingApts.isEmpty &&
              waitingQueue.isEmpty &&
              unpaidBills.isEmpty &&
              pendingPrescriptions.isEmpty &&
              lowStock.isEmpty)
            _emptyState(
              'Không có việc cần xử lý',
              'Các khu vực tiếp nhận, viện phí và kho thuốc đang ổn định.',
            )
          else ...[
            if (pendingApts.isNotEmpty)
              _attentionItem(
                'Lịch chờ xác nhận',
                pendingApts.length,
                _pending,
                Icons.pending_actions_rounded,
                () => _changeTab(1),
              ),
            if (waitingQueue.isNotEmpty)
              _attentionItem(
                'Bệnh nhân chờ khám',
                waitingQueue.length,
                _info,
                Icons.airline_seat_recline_normal_rounded,
                () => _changeTab(3),
              ),
            if (unpaidBills.isNotEmpty)
              _attentionItem(
                'Hóa đơn chưa thanh toán',
                unpaidBills.length,
                _danger,
                Icons.price_check_rounded,
                () => _changeTab(4),
              ),
            if (pendingPrescriptions.isNotEmpty)
              _attentionItem(
                'Đơn thuốc chờ phát',
                pendingPrescriptions.length,
                _success,
                Icons.local_pharmacy_rounded,
                () => _changeTab(5),
              ),
            if (lowStock.isNotEmpty)
              _attentionItem(
                'Thuốc sắp hết hàng',
                lowStock.length,
                _pending,
                Icons.warning_amber_rounded,
                () => _changeTab(6),
              ),
          ],
        ],
      ),
    );
  }

  Widget _appointmentsTab(NurseDashboardController controller) {
    final rows =
        controller.appointments.where((item) {
          final q = _normalize(_aptSearch);
          final status = _bucket(_value(item, ['status']));
          final date = _safeDate(
            _value(item, ['appointmentDate', 'scheduledAt']),
          );
          final today = _todayIso();
          final haystack = _normalize(
            [
              _idText(item, ['appointmentId', 'id']),
              _value(item, [
                'patientName',
                'patientNameSnapshot',
                'patientPhone',
              ]),
              _value(item, ['doctorName', 'doctorNameSnapshot']),
              _value(item, ['specialtyName', 'reason']),
            ].join(' '),
          );

          if (q.isNotEmpty && !haystack.contains(q)) {
            return false;
          }
          if (_aptStatus != 'All' && status != _aptStatus.toLowerCase()) {
            return false;
          }
          if (_aptDate == 'Today' && date != today) {
            return false;
          }
          if (_aptDate == 'Upcoming') {
            final parsed = DateTime.tryParse(date);
            final now = DateTime.tryParse(today);
            if (parsed == null || now == null || parsed.isBefore(now)) {
              return false;
            }
          }
          return true;
        }).toList()..sort(
          (a, b) => _safeDate(
            _value(b, ['appointmentDate', 'scheduledAt']),
          ).compareTo(_safeDate(_value(a, ['appointmentDate', 'scheduledAt']))),
        );

    return _tabScaffold(
      searchController: _aptSearchController,
      searchHint: 'Tìm bệnh nhân, SĐT, bác sĩ, mã lịch...',
      chips: [
        _choice(
          'All',
          'Tất cả',
          _aptStatus,
          (v) => setState(() => _aptStatus = v),
        ),
        _choice(
          'pending',
          'Chờ xác nhận',
          _aptStatus,
          (v) => setState(() => _aptStatus = v),
        ),
        _choice(
          'confirmed',
          'Đã xác nhận',
          _aptStatus,
          (v) => setState(() => _aptStatus = v),
        ),
        _choice(
          'checkedin',
          'Check-in',
          _aptStatus,
          (v) => setState(() => _aptStatus = v),
        ),
        _choice(
          'inprogress',
          'Đang khám',
          _aptStatus,
          (v) => setState(() => _aptStatus = v),
        ),
        _choice(
          'completed',
          'Hoàn tất',
          _aptStatus,
          (v) => setState(() => _aptStatus = v),
        ),
        _choice(
          'cancelled',
          'Đã hủy',
          _aptStatus,
          (v) => setState(() => _aptStatus = v),
        ),
        _choice(
          'Today',
          'Hôm nay',
          _aptDate,
          (v) => setState(() => _aptDate = v),
          color: _info,
        ),
        _choice(
          'Upcoming',
          'Sắp tới',
          _aptDate,
          (v) => setState(() => _aptDate = v),
          color: _success,
        ),
      ],
      itemCount: rows.length,
      emptyTitle: 'Chưa có lịch hẹn phù hợp',
      itemBuilder: (context, index) =>
          _appointmentCard(rows[index], controller),
    );
  }

  Widget _patientsTab(NurseDashboardController controller) {
    final rows = controller.patients.where((item) {
      final q = _normalize(_patientSearch);
      final haystack = _normalize(
        [
          _idText(item, ['patientId', 'id']),
          _value(item, ['fullName', 'name']),
          _value(item, ['phoneNumber', 'phone']),
          _value(item, ['email', 'citizenId', 'address']),
        ].join(' '),
      );
      return q.isEmpty || haystack.contains(q);
    }).toList();

    return _tabScaffold(
      searchController: _patientSearchController,
      searchHint: 'Tìm tên, SĐT, email, mã bệnh nhân...',
      action: FilledButton.icon(
        onPressed: () => _showPatientForm(controller),
        icon: const Icon(Icons.person_add_alt_rounded, size: 18),
        label: const Text('Thêm'),
        style: FilledButton.styleFrom(backgroundColor: _primary),
      ),
      itemCount: rows.length,
      emptyTitle: 'Chưa có hồ sơ bệnh nhân',
      itemBuilder: (context, index) => _patientCard(rows[index], controller),
    );
  }

  Widget _queueTab(NurseDashboardController controller) {
    final rows = controller.queue.where((item) {
      final q = _normalize(_queueSearch);
      final status = _bucket(_value(item, ['status']));
      final haystack = _normalize(
        [
          _idText(item, ['visitId', 'id', 'appointmentId']),
          _value(item, [
            'patientName',
            'doctorName',
            'specialtyName',
            'reason',
          ]),
        ].join(' '),
      );
      if (q.isNotEmpty && !haystack.contains(q)) {
        return false;
      }
      if (_queueStatus != 'All' && status != _queueStatus.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();

    return _tabScaffold(
      onSearchChanged: (v) => setState(() => _queueSearch = v),
      searchHint: 'Tìm bệnh nhân, bác sĩ, trạng thái...',
      chips: [
        _choice(
          'All',
          'Tất cả',
          _queueStatus,
          (v) => setState(() => _queueStatus = v),
        ),
        _choice(
          'pending',
          'Chờ khám',
          _queueStatus,
          (v) => setState(() => _queueStatus = v),
        ),
        _choice(
          'inprogress',
          'Đang khám',
          _queueStatus,
          (v) => setState(() => _queueStatus = v),
        ),
        _choice(
          'completed',
          'Hoàn tất',
          _queueStatus,
          (v) => setState(() => _queueStatus = v),
        ),
      ],
      itemCount: rows.length,
      emptyTitle: 'Hàng đợi khám đang trống',
      itemBuilder: (context, index) => _queueCard(rows[index], controller),
    );
  }

  Widget _billingTab(NurseDashboardController controller) {
    final rows = controller.bills.where((item) {
      final q = _normalize(_billSearch);
      final paid = _isPaid(item);
      final cancelled = _bucket(_value(item, ['status'])) == 'cancelled';
      final haystack = _normalize(
        [
          _idText(item, ['invoiceId', 'billId', 'id']),
          _value(item, [
            'invoiceCode',
            'invoiceNo',
            'patientName',
            'patientCode',
          ]),
        ].join(' '),
      );
      if (q.isNotEmpty && !haystack.contains(q)) return false;
      if (_billStatus == 'Paid' && !paid) return false;
      if (_billStatus == 'Unpaid' && (paid || cancelled)) return false;
      if (_billStatus == 'Cancelled' && !cancelled) return false;
      return true;
    }).toList();

    return _tabScaffold(
      searchController: _billSearchController,
      searchHint: 'Tìm mã hóa đơn, bệnh nhân...',
      chips: [
        _choice(
          'All',
          'Tất cả',
          _billStatus,
          (v) => setState(() => _billStatus = v),
        ),
        _choice(
          'Unpaid',
          'Chưa thanh toán',
          _billStatus,
          (v) => setState(() => _billStatus = v),
          color: _danger,
        ),
        _choice(
          'Paid',
          'Đã thanh toán',
          _billStatus,
          (v) => setState(() => _billStatus = v),
          color: _success,
        ),
        _choice(
          'Cancelled',
          'Đã hủy',
          _billStatus,
          (v) => setState(() => _billStatus = v),
          color: _danger,
        ),
      ],
      itemCount: rows.length,
      emptyTitle: 'Chưa có hóa đơn phù hợp',
      itemBuilder: (context, index) => _billCard(rows[index], controller),
    );
  }

  Widget _prescriptionsTab(NurseDashboardController controller) {
    final rows = controller.prescriptions.where((item) {
      final q = _normalize(_prescriptionSearch);
      final bucket = _prescriptionBucket(item);
      final haystack = _normalize(
        [
          _idText(item, ['prescriptionId', 'id']),
          _prescriptionPatientName(item, controller),
          _prescriptionDoctorName(item, controller),
          _value(item, [
            'patientName',
            'doctorName',
            'diagnosis',
            'medicineName',
          ]),
          _medicineSummary(item),
        ].join(' '),
      );
      if (q.isNotEmpty && !haystack.contains(q)) return false;
      if (_prescriptionStatus != 'All' &&
          bucket != _prescriptionStatus.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();

    return _tabScaffold(
      searchController: _prescriptionSearchController,
      searchHint: 'Tìm đơn thuốc, bệnh nhân, bác sĩ, thuốc...',
      chips: [
        _choice(
          'All',
          'Tất cả',
          _prescriptionStatus,
          (v) => setState(() => _prescriptionStatus = v),
        ),
        _choice(
          'pending',
          'Chờ phát',
          _prescriptionStatus,
          (v) => setState(() => _prescriptionStatus = v),
          color: _pending,
        ),
        _choice(
          'ready',
          'Sẵn sàng',
          _prescriptionStatus,
          (v) => setState(() => _prescriptionStatus = v),
          color: _info,
        ),
        _choice(
          'dispensed',
          'Đã phát',
          _prescriptionStatus,
          (v) => setState(() => _prescriptionStatus = v),
          color: _success,
        ),
        _choice(
          'cancelled',
          'Đã hủy',
          _prescriptionStatus,
          (v) => setState(() => _prescriptionStatus = v),
          color: _danger,
        ),
      ],
      itemCount: rows.length,
      emptyTitle: 'Chưa có đơn thuốc phù hợp',
      itemBuilder: (context, index) =>
          _prescriptionDetailCard(rows[index], controller),
    );
  }

  Widget _medicinesTab(NurseDashboardController controller) {
    final rows = controller.medicines.where((item) {
      final q = _normalize(_medicineSearch);
      final haystack = _normalize(
        [
          _idText(item, ['medicineId', 'id']),
          _value(item, [
            'medicineName',
            'name',
            'activeIngredient',
            'medicineType',
            'unit',
          ]),
        ].join(' '),
      );
      if (q.isNotEmpty && !haystack.contains(q)) {
        return false;
      }
      if (_medicineStock != 'All' &&
          !_medicineMatchesFilter(item, _medicineStock)) {
        return false;
      }
      return true;
    }).toList();

    return _tabScaffold(
      searchController: _medicineSearchController,
      action: FilledButton.icon(
        onPressed: () => _showMedicineForm(controller),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Thêm'),
        style: FilledButton.styleFrom(backgroundColor: _primary),
      ),
      searchHint: 'Tìm tên thuốc, mã thuốc, hoạt chất...',
      chips: [
        _choice(
          'All',
          'Tất cả',
          _medicineStock,
          (v) => setState(() => _medicineStock = v),
        ),
        _choice(
          'low',
          'Sắp hết',
          _medicineStock,
          (v) => setState(() => _medicineStock = v),
          color: _pending,
        ),
        _choice(
          'normal',
          'Còn hàng',
          _medicineStock,
          (v) => setState(() => _medicineStock = v),
          color: _success,
        ),
        _choice(
          'expiring',
          'Sắp hết hạn',
          _medicineStock,
          (v) => setState(() => _medicineStock = v),
          color: _pending,
        ),
        _choice(
          'expired',
          'Đã hết hạn',
          _medicineStock,
          (v) => setState(() => _medicineStock = v),
          color: _danger,
        ),
        _choice(
          'out',
          'Hết hàng',
          _medicineStock,
          (v) => setState(() => _medicineStock = v),
          color: _danger,
        ),
      ],
      itemCount: rows.length,
      emptyTitle: 'Chưa có thuốc phù hợp',
      itemBuilder: (context, index) =>
          _medicineManagementCard(rows[index], controller),
    );
  }

  Widget _slipsTab(NurseDashboardController controller) {
    final rows = controller.slips.where((item) {
      final q = _normalize(_slipSearch);
      final status = _value(item, ['status']).toString();
      final haystack = _normalize(
        [
          _idText(item, ['slipId', 'id']),
          _value(item, ['supplierName', 'createdByName', 'note']),
          status,
        ].join(' '),
      );
      if (q.isNotEmpty && !haystack.contains(q)) return false;
      if (_slipStatus != 'All' &&
          status.toLowerCase() != _slipStatus.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();

    return _tabScaffold(
      onSearchChanged: (v) => setState(() => _slipSearch = v),
      searchHint: 'Tìm mã phiếu, nhà cung cấp, trạng thái...',
      action: FilledButton.icon(
        onPressed: () => _showInventorySlipForm(controller),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Tạo phiếu'),
        style: FilledButton.styleFrom(backgroundColor: _primary),
      ),
      chips: [
        _choice(
          'All',
          'Tất cả',
          _slipStatus,
          (v) => setState(() => _slipStatus = v),
        ),
        _choice(
          'Pending',
          'Chờ duyệt',
          _slipStatus,
          (v) => setState(() => _slipStatus = v),
          color: _pending,
        ),
        _choice(
          'Approved',
          'Đã duyệt',
          _slipStatus,
          (v) => setState(() => _slipStatus = v),
          color: _success,
        ),
        _choice(
          'Rejected',
          'Từ chối',
          _slipStatus,
          (v) => setState(() => _slipStatus = v),
          color: _danger,
        ),
        _choice(
          'Voided',
          'Đã hủy',
          _slipStatus,
          (v) => setState(() => _slipStatus = v),
          color: _muted,
        ),
      ],
      itemCount: rows.length,
      emptyTitle: 'Chưa có phiếu nhập kho',
      itemBuilder: (context, index) => _slipCard(rows[index], controller),
    );
  }

  Widget _tabScaffold({
    TextEditingController? searchController,
    ValueChanged<String>? onSearchChanged,
    required String searchHint,
    List<Widget> chips = const [],
    Widget? action,
    required int itemCount,
    required String emptyTitle,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    return RefreshIndicator(
      onRefresh: _refreshDataAsync,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: searchHint,
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: _bg,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (action != null) ...[const SizedBox(width: 10), action],
                  ],
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: chips),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: itemCount == 0
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _emptyState(emptyTitle, 'Kéo xuống để tải lại dữ liệu.'),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: itemCount,
                    itemBuilder: itemBuilder,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _choice(
    String value,
    String label,
    String selected,
    ValueChanged<String> onSelected, {
    Color color = _primary,
  }) {
    final active = selected.toLowerCase() == value.toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        selectedColor: color,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: active ? Colors.white : _muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: active ? color : const Color(0xFFE2E8F0)),
        showCheckmark: false,
        onSelected: (_) => onSelected(value),
      ),
    );
  }

  Widget _appointmentCard(dynamic item, NurseDashboardController controller) {
    final status = _bucket(_value(item, ['status']));
    final id = _id(item, ['appointmentId', 'id']);
    final date = _safeDate(_value(item, ['appointmentDate', 'scheduledAt']));
    final time = _str(
      _value(item, ['slotTime', 'appointmentTime', 'time']),
      '--:--',
    );
    final patient = _str(
      _value(item, ['patientName', 'patientNameSnapshot']),
      'Bệnh nhân',
    );
    final doctor = _str(
      _value(item, ['doctorName', 'doctorNameSnapshot']),
      'Bác sĩ',
    );
    final specialty = _str(
      _value(item, ['specialtyName']),
      'Chưa rõ chuyên khoa',
    );
    final reason = _str(
      _value(item, ['reason', 'note']),
      'Chưa ghi nhận lý do',
    );

    return _baseCard(
      onTap: () => _showDetails('Chi tiết lịch hẹn', [
        _detail('Mã lịch', 'LH-$id'),
        _detail('Bệnh nhân', patient),
        _detail('Bác sĩ', doctor),
        _detail('Chuyên khoa', specialty),
        _detail('Thời gian', '${_formatDate(date)} $time'),
        _detail('Lý do', reason),
        _detail('Trạng thái', _statusLabel(status)),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            icon: Icons.event_note_rounded,
            color: _statusColor(status),
            title: patient,
            subtitle: 'LH-$id • ${_formatDate(date)} $time',
            status: _statusLabel(status),
          ),
          const SizedBox(height: 10),
          _infoLine(
            Icons.medical_services_outlined,
            'BS. $doctor • $specialty',
          ),
          _infoLine(Icons.notes_rounded, reason),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (status == 'pending')
                _smallButton(
                  'Xác nhận',
                  _info,
                  () => _run(() => controller.confirmAppointment(id)),
                ),
              if (status == 'confirmed')
                _smallButton(
                  'Tiếp nhận',
                  _success,
                  () => _run(() => controller.checkInAppointment(_asMap(item))),
                ),
              if (!['completed', 'cancelled'].contains(status))
                _smallButton(
                  'Hủy',
                  _danger,
                  () => _confirmCancelAppointment(controller, id),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _patientCard(dynamic item, NurseDashboardController controller) {
    final id = _id(item, ['patientId', 'id']);
    final name = _str(_value(item, ['fullName', 'name']), 'Bệnh nhân');
    final phone = _str(_value(item, ['phoneNumber', 'phone']), 'Chưa có SĐT');
    final email = _str(_value(item, ['email']), 'Chưa có email');
    final dob = _formatDate(_safeDate(_value(item, ['dateOfBirth', 'dob'])));

    return _baseCard(
      onTap: () => _showPatientDetails(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            icon: Icons.person_rounded,
            color: _primary,
            title: name,
            subtitle: 'BN-$id • $phone',
            status: _str(_value(item, ['status']), 'Hoạt động'),
          ),
          const SizedBox(height: 10),
          _infoLine(Icons.cake_outlined, dob),
          _infoLine(Icons.email_outlined, email),
          const SizedBox(height: 10),
          _smallButton(
            'Cập nhật',
            _info,
            () => _showPatientForm(controller, patient: item),
          ),
        ],
      ),
    );
  }

  Widget _queueCard(dynamic item, NurseDashboardController controller) {
    final status = _bucket(_value(item, ['status']));
    final visitId = _id(item, ['visitId', 'id']);
    final patient = _str(
      _value(item, ['patientName', 'patientNameSnapshot']),
      'Bệnh nhân',
    );
    final doctor = _str(
      _value(item, ['doctorName', 'doctorNameSnapshot']),
      'Bác sĩ',
    );
    final queueNo = _str(_value(item, ['queueNumber']), '--');
    final reason = _str(
      _value(item, ['reason', 'chiefComplaint']),
      'Chưa ghi nhận',
    );

    return _baseCard(
      onTap: () => _showDetails('Chi tiết hàng đợi', [
        _detail('Mã lượt khám', 'LK-$visitId'),
        _detail('Số thứ tự', queueNo),
        _detail('Bệnh nhân', patient),
        _detail('Bác sĩ', doctor),
        _detail('Lý do', reason),
        _detail('Trạng thái', _statusLabel(status)),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            icon: Icons.queue_rounded,
            color: _statusColor(status),
            title: patient,
            subtitle: 'STT $queueNo • BS. $doctor',
            status: _statusLabel(status),
          ),
          const SizedBox(height: 10),
          _infoLine(Icons.notes_rounded, reason),
          if (visitId > 0 && status != 'completed') ...[
            const SizedBox(height: 10),
            _smallButton(
              'Nhập sinh hiệu',
              _info,
              () => _showVitalsForm(controller, item),
            ),
          ],
        ],
      ),
    );
  }

  Widget _billCard(dynamic item, NurseDashboardController controller) {
    final id = _id(item, ['invoiceId', 'billId', 'id']);
    final patient = _str(_value(item, ['patientName']), 'Bệnh nhân');
    final amount = _money(
      _value(item, ['totalAmount', 'amount', 'balanceDue']),
    );
    final status = _bucket(_value(item, ['status', 'invoiceStatus']));
    final created = _formatDate(
      _safeDate(_value(item, ['createdAt', 'invoiceDate'])),
    );

    return _baseCard(
      onTap: () => _showDetails('Chi tiết hóa đơn', [
        _detail('Mã hóa đơn', 'HD-$id'),
        _detail('Bệnh nhân', patient),
        _detail('Tổng tiền', amount),
        _detail('Ngày tạo', created),
        _detail('Trạng thái', _statusLabel(status)),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            icon: Icons.receipt_long_rounded,
            color: _isPaid(item) ? _success : _danger,
            title: 'HD-$id',
            subtitle: '$patient • $created',
            status: _statusLabel(status),
          ),
          const SizedBox(height: 10),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: _text,
            ),
          ),
          if (!_isPaid(item) && status != 'cancelled') ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _smallButton(
                  'Thu tiền',
                  _success,
                  () => _run(() => controller.confirmPayment(id)),
                ),
                _smallButton(
                  'Hủy hóa đơn',
                  _danger,
                  () => _run(() => controller.cancelInvoice(id)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _prescriptionDetailCard(
    dynamic item,
    NurseDashboardController controller,
  ) {
    final id = _id(item, ['prescriptionId', 'id', 'PrescriptionId', 'Id']);
    
    // --- Detailed Patient Lookup ---
    final patientId = _id(item, ['patientId', 'PatientId']);
    Map<String, dynamic>? patientObj;
    if (patientId > 0) {
      for (final p in controller.patients) {
        if (_id(p, ['patientId', 'id', 'PatientId', 'Id']) == patientId) {
          patientObj = _asMap(p);
          break;
        }
      }
    }
    if (patientObj == null) {
      final nestedPatient = _value(item, ['patient', 'Patient']);
      if (nestedPatient != null) {
        patientObj = _asMap(nestedPatient);
      }
    }
    
    final patientName = _firstNonEmpty(patientObj, ['fullName', 'FullName', 'patientName', 'PatientName', 'name', 'Name'])
        .isNotEmpty 
        ? _firstNonEmpty(patientObj, ['fullName', 'FullName', 'patientName', 'PatientName', 'name', 'Name'])
        : _prescriptionPatientName(item, controller);
        
    final patientCode = _str(_value(patientObj, ['patientCode', 'PatientCode']), patientId > 0 ? 'BN-$patientId' : '');
    final patientPhone = _str(_value(patientObj, ['phoneNumber', 'PhoneNumber', 'phone', 'Phone', 'patientPhoneSnapshot', 'PatientPhoneSnapshot']), '');
    final patientGender = _str(_value(patientObj, ['gender', 'Gender']), '');
    final patientDob = _formatDate(_safeDate(_value(patientObj, ['dateOfBirth', 'DateOfBirth', 'dob', 'Dob'])));
    final patientAddress = _str(_value(patientObj, ['address', 'Address']), '');

    // --- Detailed Doctor Lookup ---
    final doctorId = _id(item, ['doctorId', 'DoctorId']);
    Map<String, dynamic>? doctorObj;
    if (doctorId > 0) {
      for (final appt in controller.appointments) {
        if (_id(appt, ['doctorId', 'DoctorId']) == doctorId) {
          doctorObj = _asMap(appt);
          break;
        }
      }
      if (doctorObj == null) {
        for (final q in controller.queue) {
          if (_id(q, ['doctorId', 'DoctorId']) == doctorId) {
            doctorObj = _asMap(q);
            break;
          }
        }
      }
    }
    if (doctorObj == null) {
      final nestedDoctor = _value(item, ['doctor', 'Doctor']);
      if (nestedDoctor != null) {
        doctorObj = _asMap(nestedDoctor);
      }
    }

    final doctorName = _stripDoctorPrefix(
      _firstNonEmpty(doctorObj, ['doctorName', 'DoctorName', 'doctorFullName', 'DoctorFullName', 'fullName', 'FullName', 'name', 'Name']).isNotEmpty
          ? _firstNonEmpty(doctorObj, ['doctorName', 'DoctorName', 'doctorFullName', 'DoctorFullName', 'fullName', 'FullName', 'name', 'Name'])
          : _prescriptionDoctorName(item, controller)
    );
    final doctorCode = doctorId > 0 ? 'BS-$doctorId' : _str(_value(doctorObj, ['doctorCode', 'DoctorCode']));
    final doctorSpecialty = _str(_value(doctorObj, ['specialtyName', 'SpecialtyName', 'specialty', 'Specialty', 'specialtyNameSnapshot', 'SpecialtyNameSnapshot']));

    final appointmentId = _id(item, ['appointmentId', 'AppointmentId']);
    final recordId = _id(item, ['medicalRecordId', 'MedicalRecordId']);
    final created = _formatDate(
      _safeDate(_value(item, ['createdAt', 'CreatedAt'])),
    );
    final diagnosis = _str(
      _value(item, ['diagnosis', 'diagnosisText', 'Diagnosis']),
      'Chưa có chẩn đoán',
    );
    final meds = _medicineSummary(item);
    final status = _prescriptionBucket(item);
    final stockStatus = _str(
      _value(item, ['stockStatus', 'StockStatus']),
      'Chưa kiểm tra',
    );
    final invoiceStatus = _str(
      _value(item, ['invoiceStatus', 'InvoiceStatus']),
      'Chưa có',
    );

    return _baseCard(
      onTap: () => _showPrescriptionDetails(
        id: id,
        patientName: patientName,
        patientCode: patientCode,
        patientPhone: patientPhone,
        patientGender: patientGender,
        patientDob: patientDob,
        patientAddress: patientAddress,
        doctorName: doctorName,
        doctorCode: doctorCode,
        doctorSpecialty: doctorSpecialty,
        appointmentId: appointmentId,
        recordId: recordId,
        created: created,
        diagnosis: diagnosis,
        meds: meds,
        stockStatus: stockStatus,
        invoiceStatus: invoiceStatus,
        status: status,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            icon: Icons.medication_rounded,
            color: _statusColor(status),
            title: 'Đơn DT-$id',
            subtitle: '$patientName - BS. $doctorName',
            status: _statusLabel(status),
          ),
          const SizedBox(height: 10),
          _infoLine(Icons.person_outline_rounded, patientName),
          _infoLine(Icons.medical_services_outlined, 'BS. $doctorName'),
          if (appointmentId > 0)
            _infoLine(Icons.event_note_rounded, 'Lịch hẹn LH-$appointmentId'),
          _infoLine(Icons.healing_rounded, diagnosis),
          if (meds.isNotEmpty) _infoLine(Icons.local_pharmacy_outlined, meds),
          if (!['dispensed', 'cancelled'].contains(status)) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _smallButton(
                  'Kiểm kho',
                  _info,
                  () => _showStockCheck(controller, id),
                ),
                _smallButton(
                  'Phát thuốc',
                  _success,
                  () => _run(() => controller.dispensePrescription(id)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _prescriptionCard(dynamic item, NurseDashboardController controller) {
    final id = _id(item, ['prescriptionId', 'id', 'PrescriptionId', 'Id']);
    
    // --- Detailed Patient Lookup ---
    final patientId = _id(item, ['patientId', 'PatientId']);
    Map<String, dynamic>? patientObj;
    if (patientId > 0) {
      for (final p in controller.patients) {
        if (_id(p, ['patientId', 'id', 'PatientId', 'Id']) == patientId) {
          patientObj = _asMap(p);
          break;
        }
      }
    }
    if (patientObj == null) {
      final nestedPatient = _value(item, ['patient', 'Patient']);
      if (nestedPatient != null) {
        patientObj = _asMap(nestedPatient);
      }
    }
    
    final patientName = _firstNonEmpty(patientObj, ['fullName', 'FullName', 'patientName', 'PatientName', 'name', 'Name'])
        .isNotEmpty 
        ? _firstNonEmpty(patientObj, ['fullName', 'FullName', 'patientName', 'PatientName', 'name', 'Name'])
        : _prescriptionPatientName(item, controller);
        
    final patientCode = _str(_value(patientObj, ['patientCode', 'PatientCode']), patientId > 0 ? 'BN-$patientId' : '');
    final patientPhone = _str(_value(patientObj, ['phoneNumber', 'PhoneNumber', 'phone', 'Phone', 'patientPhoneSnapshot', 'PatientPhoneSnapshot']), '');
    final patientGender = _str(_value(patientObj, ['gender', 'Gender']), '');
    final patientDob = _formatDate(_safeDate(_value(patientObj, ['dateOfBirth', 'DateOfBirth', 'dob', 'Dob'])));
    final patientAddress = _str(_value(patientObj, ['address', 'Address']), '');

    // --- Detailed Doctor Lookup ---
    final doctorId = _id(item, ['doctorId', 'DoctorId']);
    Map<String, dynamic>? doctorObj;
    if (doctorId > 0) {
      for (final appt in controller.appointments) {
        if (_id(appt, ['doctorId', 'DoctorId']) == doctorId) {
          doctorObj = _asMap(appt);
          break;
        }
      }
      if (doctorObj == null) {
        for (final q in controller.queue) {
          if (_id(q, ['doctorId', 'DoctorId']) == doctorId) {
            doctorObj = _asMap(q);
            break;
          }
        }
      }
    }
    if (doctorObj == null) {
      final nestedDoctor = _value(item, ['doctor', 'Doctor']);
      if (nestedDoctor != null) {
        doctorObj = _asMap(nestedDoctor);
      }
    }

    final doctorName = _stripDoctorPrefix(
      _firstNonEmpty(doctorObj, ['doctorName', 'DoctorName', 'doctorFullName', 'DoctorFullName', 'fullName', 'FullName', 'name', 'Name']).isNotEmpty
          ? _firstNonEmpty(doctorObj, ['doctorName', 'DoctorName', 'doctorFullName', 'DoctorFullName', 'fullName', 'FullName', 'name', 'Name'])
          : _prescriptionDoctorName(item, controller)
    );
    final doctorCode = doctorId > 0 ? 'BS-$doctorId' : _str(_value(doctorObj, ['doctorCode', 'DoctorCode']));
    final doctorSpecialty = _str(_value(doctorObj, ['specialtyName', 'SpecialtyName', 'specialty', 'Specialty', 'specialtyNameSnapshot', 'SpecialtyNameSnapshot']));

    final appointmentId = _id(item, ['appointmentId', 'AppointmentId']);
    final recordId = _id(item, ['medicalRecordId', 'MedicalRecordId']);
    final created = _formatDate(
      _safeDate(_value(item, ['createdAt', 'CreatedAt'])),
    );
    final diagnosis = _str(
      _value(item, ['diagnosis', 'diagnosisText', 'Diagnosis']),
      'Chưa có chẩn đoán',
    );
    final meds = _medicineSummary(item);
    final status = _prescriptionBucket(item);
    final stockStatus = _str(
      _value(item, ['stockStatus', 'StockStatus']),
      'Chưa kiểm tra',
    );
    final invoiceStatus = _str(
      _value(item, ['invoiceStatus', 'InvoiceStatus']),
      'Chưa có',
    );

    return _baseCard(
      onTap: () => _showPrescriptionDetails(
        id: id,
        patientName: patientName,
        patientCode: patientCode,
        patientPhone: patientPhone,
        patientGender: patientGender,
        patientDob: patientDob,
        patientAddress: patientAddress,
        doctorName: doctorName,
        doctorCode: doctorCode,
        doctorSpecialty: doctorSpecialty,
        appointmentId: appointmentId,
        recordId: recordId,
        created: created,
        diagnosis: diagnosis,
        meds: meds,
        stockStatus: stockStatus,
        invoiceStatus: invoiceStatus,
        status: status,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            icon: Icons.medication_rounded,
            color: _statusColor(status),
            title: 'Đơn DT-$id',
            subtitle: '$patientName • BS. $doctorName',
            status: _statusLabel(status),
          ),
          const SizedBox(height: 10),
          _infoLine(Icons.healing_rounded, diagnosis),
          if (meds.isNotEmpty) _infoLine(Icons.local_pharmacy_outlined, meds),
          if (!['dispensed', 'cancelled'].contains(status)) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _smallButton(
                  'Kiểm kho',
                  _info,
                  () => _showStockCheck(controller, id),
                ),
                _smallButton(
                  'Phát thuốc',
                  _success,
                  () => _run(() => controller.dispensePrescription(id)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _medicineCard(dynamic item, NurseDashboardController controller) {
    final id = _id(item, ['medicineId', 'id']);
    final name = _str(_value(item, ['medicineName', 'name']), 'Thuốc');
    final type = _str(_value(item, ['medicineType', 'type']), 'Chưa phân loại');
    final unit = _str(_value(item, ['unit']), 'đơn vị');
    final stock = _num(_value(item, ['stockQuantity', 'stock', 'quantity']));
    final minStock = _num(
      _value(item, ['minStockLevel', 'minStock']),
      fallback: 10,
    );
    final bucket = _stockBucket(item);

    return _baseCard(
      onTap: () => _showDetails('Chi tiết thuốc', [
        _detail('Mã thuốc', 'T-$id'),
        _detail('Tên thuốc', name),
        _detail('Loại', type),
        _detail('Đơn vị', unit),
        _detail('Tồn kho', '$stock'),
        _detail('Ngưỡng cảnh báo', '$minStock'),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            icon: Icons.inventory_2_rounded,
            color: _statusColor(bucket),
            title: name,
            subtitle: 'T-$id • $type',
            status: _stockLabel(bucket),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _miniStat('Tồn kho', '$stock $unit')),
              const SizedBox(width: 10),
              Expanded(child: _miniStat('Cảnh báo', '≤ $minStock')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _medicineManagementCard(
    dynamic item,
    NurseDashboardController controller,
  ) {
    final id = _id(item, ['medicineId', 'id']);
    final name = _str(_value(item, ['medicineName', 'name']), 'Thuốc');
    final type = _str(_value(item, ['medicineType', 'type']), 'Chưa phân loại');
    final unit = _str(_value(item, ['unit']), 'don vi');
    final active = _str(_value(item, ['activeIngredient']), 'Chưa có');
    final price = _value(item, ['price']);
    final stock = _num(_value(item, ['stockQuantity', 'stock', 'quantity']));
    final minStock = _num(
      _value(item, ['minStockLevel', 'minStock']),
      fallback: 10,
    );
    final expiry = _formatDate(_safeDate(_value(item, ['expiryDate'])));
    final status = _str(_value(item, ['status']), 'Active');
    final bucket = _stockBucket(item);

    return _baseCard(
      onTap: () => _showDetails('Chi tiết thuốc', [
        _detail('Mã thuốc', 'T-$id'),
        _detail('Tên thuốc', name),
        _detail('Hoạt chất', active),
        _detail('Loai', type),
        _detail('Đơn vị', unit),
        _detail('Giá bán', _money(price)),
        _detail('Tồn kho', '$stock'),
        _detail('Ngưỡng cảnh báo', '$minStock'),
        _detail('Hạn dùng', expiry),
        _detail('Trạng thái', status),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            icon: Icons.inventory_2_rounded,
            color: _statusColor(bucket),
            title: name,
            subtitle: 'T-$id - $type',
            status: _stockLabel(bucket),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _miniStat('Tồn kho', '$stock $unit')),
              const SizedBox(width: 10),
              Expanded(child: _miniStat('Cảnh báo', '<= $minStock')),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _smallButton(
                'Sửa',
                _info,
                () => _showMedicineForm(controller, medicine: item),
              ),
              _smallButton(
                'Tạm ngưng',
                _danger,
                () => _confirmDeleteMedicine(controller, id, name),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _slipCard(dynamic item, NurseDashboardController controller) {
    final id = _id(item, ['slipId', 'id']);
    final supplier = _str(_value(item, ['supplierName']), 'Nhà cung cấp');
    final status = _str(_value(item, ['status']), 'Pending');
    final note = _str(
      _value(item, ['note', 'rejectReason']),
      'Không có ghi chú',
    );
    final created = _formatDate(
      _safeDate(_value(item, ['createdAt', 'createdDate'])),
    );
    final items = _list(_value(item, ['items', 'Items']));

    return _baseCard(
      onTap: () => _showDetails('Chi tiết phiếu nhập', [
        _detail('Mã phiếu', 'PN-$id'),
        _detail('Nhà cung cấp', supplier),
        _detail('Số loại thuốc', '${items.length}'),
        _detail('Ngày tạo', created),
        _detail('Trạng thái', _statusLabel(status)),
        _detail('Ghi chú', note),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            icon: Icons.assignment_rounded,
            color: _statusColor(status),
            title: 'Phiếu PN-$id',
            subtitle: '$supplier • $created',
            status: _statusLabel(status),
          ),
          const SizedBox(height: 10),
          _infoLine(
            Icons.medication_liquid_rounded,
            '${items.length} dòng thuốc',
          ),
          _infoLine(Icons.notes_rounded, note),
          if (status.toLowerCase() == 'pending' ||
              status.toLowerCase() == 'rejected') ...[
            const SizedBox(height: 10),
            _smallButton(
              'Hủy phiếu',
              _danger,
              () => _run(() => controller.voidSlip(id)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _commandHeader(UserModel user) {
    return WeatherGreetingCard(
      displayName: user.fullName,
      primaryColor: _primary,
    );
  }

  Widget _quickCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: _box(16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
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
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _muted,
                        fontWeight: FontWeight.w600,
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

  Widget _metricCard(
    String label,
    String value,
    String note,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _box(16),
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
                    color: _muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    color: _text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _attentionItem(
    String title,
    int count,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: _box(16),
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
                      color: _text,
                    ),
                  ),
                ),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _baseCard({required Widget child, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: _box(18),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _cardHeader({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String status,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: _text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: _muted,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _statusChip(status, color),
      ],
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: _muted, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 34,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: _muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: _text,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w900,
        color: _text,
      ),
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _box(18),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: _success,
            size: 34,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: _text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: _muted),
          ),
        ],
      ),
    );
  }

  BoxDecoration _box(double radius) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật dữ liệu thành công.')),
      );
      await context.read<NurseDashboardController>().loadAllNurseData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Thao tác chưa thành công: $e')));
    }
  }

  Future<void> _confirmCancelAppointment(
    NurseDashboardController controller,
    int id,
  ) async {
    final reasonCtrl = TextEditingController(text: 'Hủy từ điều phối y tế');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy lịch hẹn'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Lý do hủy'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy lịch'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(() => controller.cancelAppointment(id, reasonCtrl.text));
    }
  }

  void _showPatientDetails(dynamic patient) {
    _showDetails('Chi tiết bệnh nhân', [
      _detail('Mã bệnh nhân', 'BN-${_id(patient, ['patientId', 'id'])}'),
      _detail(
        'Họ tên',
        _str(_value(patient, ['fullName', 'name']), 'Bệnh nhân'),
      ),
      _detail('Giới tính', _gender(_value(patient, ['gender']))),
      _detail(
        'Ngày sinh',
        _formatDate(_safeDate(_value(patient, ['dateOfBirth', 'dob']))),
      ),
      _detail(
        'Số điện thoại',
        _str(_value(patient, ['phoneNumber', 'phone']), 'Chưa có'),
      ),
      _detail('Email', _str(_value(patient, ['email']), 'Chưa có')),
      _detail('Địa chỉ', _str(_value(patient, ['address']), 'Chưa có')),
      _detail(
        'BHYT/CCCD',
        _str(
          _value(patient, [
            'healthInsuranceNo',
            'insuranceNumber',
            'citizenId',
          ]),
          'Chưa có',
        ),
      ),
      _detail(
        'Dị ứng',
        _str(_value(patient, ['allergyNote', 'allergies']), 'Không ghi nhận'),
      ),
      _detail(
        'Tiền sử',
        _str(_value(patient, ['medicalHistory', 'history']), 'Không ghi nhận'),
      ),
    ]);
  }

  Future<void> _showPatientForm(
    NurseDashboardController controller, {
    dynamic patient,
  }) async {
    final name = TextEditingController(
      text: _str(_value(patient, ['fullName', 'name']), ''),
    );
    final phone = TextEditingController(
      text: _str(_value(patient, ['phoneNumber', 'phone']), ''),
    );
    final email = TextEditingController(
      text: _str(_value(patient, ['email']), ''),
    );
    final address = TextEditingController(
      text: _str(_value(patient, ['address']), ''),
    );
    final citizen = TextEditingController(
      text: _str(_value(patient, ['citizenId']), ''),
    );
    final dob = TextEditingController(
      text: _safeDate(_value(patient, ['dateOfBirth', 'dob'])),
    );
    String gender = _str(_value(patient, ['gender']), 'Male');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  patient == null ? 'Thêm bệnh nhân' : 'Cập nhật bệnh nhân',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _input(name, 'Họ tên', Icons.person_outline_rounded),
                _input(phone, 'Số điện thoại', Icons.phone_outlined),
                _input(email, 'Email', Icons.email_outlined),
                _input(dob, 'Ngày sinh YYYY-MM-DD', Icons.cake_outlined),
                DropdownButtonFormField<String>(
                  initialValue: gender.toLowerCase().contains('female')
                      ? 'Female'
                      : 'Male',
                  decoration: const InputDecoration(labelText: 'Giới tính'),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Nam')),
                    DropdownMenuItem(value: 'Female', child: Text('Nữ')),
                  ],
                  onChanged: (value) =>
                      setSheetState(() => gender = value ?? 'Male'),
                ),
                _input(citizen, 'CCCD/BHYT', Icons.badge_outlined),
                _input(address, 'Địa chỉ', Icons.home_outlined),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _primary),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Lưu hồ sơ'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved == true) {
      final payload = {
        'fullName': name.text.trim(),
        'phoneNumber': phone.text.trim(),
        'email': email.text.trim(),
        'dateOfBirth': dob.text.trim().isEmpty ? null : dob.text.trim(),
        'gender': gender,
        'citizenId': citizen.text.trim(),
        'address': address.text.trim(),
      };
      final id = _id(patient, ['patientId', 'id']);
      await _run(
        () => id > 0
            ? controller.updatePatient(id, payload)
            : controller.createPatient(payload),
      );
    }
  }

  Future<void> _showVitalsForm(
    NurseDashboardController controller,
    dynamic visit,
  ) async {
    final raw = _asMap(visit);
    final vitals = _parseVitals(
      _value(raw, ['vitalSignsJson', 'VitalSignsJson']),
    );
    final temperature = TextEditingController(
      text: _str(
        _value(raw, ['temperature', 'Temperature']) ?? vitals['temperature'],
        '',
      ),
    );
    final bloodPressure = TextEditingController(
      text: _str(
        _value(raw, ['bloodPressure', 'BloodPressure']) ??
            vitals['bloodPressure'],
        '',
      ),
    );
    final heartRate = TextEditingController(
      text: _str(
        _value(raw, ['heartRate', 'HeartRate']) ?? vitals['heartRate'],
        '',
      ),
    );
    final respiratoryRate = TextEditingController(
      text: _str(
        _value(raw, ['respiratoryRate', 'RespiratoryRate']) ??
            vitals['respiratoryRate'],
        '',
      ),
    );
    final spo2 = TextEditingController(
      text: _str(_value(raw, ['spo2', 'Spo2', 'spO2']) ?? vitals['spo2'], ''),
    );
    final height = TextEditingController(
      text: _str(_value(raw, ['height', 'Height']) ?? vitals['height'], ''),
    );
    final weight = TextEditingController(
      text: _str(_value(raw, ['weight', 'Weight']) ?? vitals['weight'], ''),
    );
    final note = TextEditingController(
      text: _str(_value(raw, ['note', 'Note']) ?? vitals['note'], ''),
    );

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nhập sinh hiệu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              _input(
                temperature,
                'Nhiệt độ (30-45°C)',
                Icons.thermostat_rounded,
                number: true,
              ),
              _input(
                bloodPressure,
                'Huyết áp, ví dụ 120/80',
                Icons.monitor_heart_outlined,
              ),
              _input(
                heartRate,
                'Mạch (1-250)',
                Icons.favorite_border_rounded,
                number: true,
              ),
              _input(
                respiratoryRate,
                'Nhịp thở (1-100)',
                Icons.air_rounded,
                number: true,
              ),
              _input(spo2, 'SpO2 (%)', Icons.bloodtype_outlined, number: true),
              _input(
                height,
                'Chiều cao (cm)',
                Icons.height_rounded,
                number: true,
              ),
              _input(
                weight,
                'Cân nặng (kg)',
                Icons.monitor_weight_outlined,
                number: true,
              ),
              _input(note, 'Ghi chú', Icons.notes_rounded, maxLines: 3),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _primary),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Lưu sinh hiệu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved == true) {
      final validation = _validateVitals(
        temperature.text,
        bloodPressure.text,
        heartRate.text,
        respiratoryRate.text,
        spo2.text,
        height.text,
        weight.text,
        note.text,
      );
      if (validation != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(validation)));
        return;
      }
      final visitId = _id(visit, ['visitId', 'id']);
      final payload = {
        'temperature': _nullableNum(temperature.text),
        'bloodPressure': bloodPressure.text.trim(),
        'heartRate': _nullableNum(heartRate.text),
        'respiratoryRate': _nullableNum(respiratoryRate.text),
        'spo2': _nullableNum(spo2.text),
        'height': _nullableNum(height.text),
        'weight': _nullableNum(weight.text),
        'note': note.text.trim().isEmpty ? null : note.text.trim(),
      };
      await _run(() => controller.updateVisitVitals(visitId, payload));
    }
  }

  Future<void> _showStockCheck(
    NurseDashboardController controller,
    int id,
  ) async {
    try {
      final result = await controller.checkPrescriptionStock(id);
      final items = _list(
        result == null
            ? null
            : _value(result, ['items', 'Items', 'stockItems']),
      );
      if (!mounted) return;
      _showDetails('Kiểm tồn đơn DT-$id', [
        _detail(
          'Trạng thái',
          _str(_value(result, ['status', 'Status']), 'Không có dữ liệu'),
        ),
        _detail(
          'Hóa đơn',
          _str(_value(result, ['invoiceStatus', 'InvoiceStatus']), 'Chưa rõ'),
        ),
        _detail('Số dòng thuốc', '${items.length}'),
        if (items.isNotEmpty)
          _detail(
            'Thuốc',
            items
                .take(6)
                .map((e) {
                  final name = _str(
                    _value(e, ['medicineName', 'MedicineName']),
                    'Thuốc',
                  );
                  final need = _str(
                    _value(e, [
                      'requiredQuantity',
                      'RequiredQuantity',
                      'quantity',
                    ]),
                    '?',
                  );
                  final stock = _str(
                    _value(e, [
                      'currentStock',
                      'CurrentStock',
                      'stockQuantity',
                    ]),
                    '?',
                  );
                  return '$name: cần $need, tồn $stock';
                })
                .join('\n'),
          ),
      ]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không kiểm được tồn kho: $e')));
    }
  }

  Future<void> _showMedicineForm(
    NurseDashboardController controller, {
    dynamic medicine,
  }) async {
    final id = _id(medicine, ['medicineId', 'id']);
    final name = TextEditingController(
      text: _str(_value(medicine, ['medicineName', 'name']), ''),
    );
    final active = TextEditingController(
      text: _str(_value(medicine, ['activeIngredient']), ''),
    );
    final type = TextEditingController(
      text: _str(_value(medicine, ['medicineType', 'type']), ''),
    );
    final unit = TextEditingController(
      text: _str(_value(medicine, ['unit']), ''),
    );
    final price = TextEditingController(
      text: _str(_value(medicine, ['price']), ''),
    );
    final stock = TextEditingController(
      text: _str(_value(medicine, ['stockQuantity', 'stock', 'quantity']), '0'),
    );
    final minStock = TextEditingController(
      text: _str(_value(medicine, ['minStockLevel', 'minStock']), '10'),
    );
    final expiry = TextEditingController(
      text: _safeDate(_value(medicine, ['expiryDate'])),
    );
    final description = TextEditingController(
      text: _str(_value(medicine, ['description']), ''),
    );
    String status = _str(_value(medicine, ['status']), 'Active');
    if (!['Active', 'Inactive', 'OutOfStock'].contains(status)) {
      status = 'Active';
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  id > 0 ? 'Cập nhật thuốc' : 'Thêm thuốc',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _input(name, 'Tên thuốc', Icons.medication_liquid_rounded),
                _input(active, 'Hoạt chất', Icons.science_outlined),
                _input(type, 'Loại thuốc', Icons.category_outlined),
                _input(unit, 'Đơn vị tính', Icons.straighten_outlined),
                _input(price, 'Giá bán', Icons.payments_outlined, number: true),
                _input(
                  stock,
                  'Tồn kho',
                  Icons.inventory_2_outlined,
                  number: true,
                ),
                _input(
                  minStock,
                  'Ngưỡng cảnh báo',
                  Icons.warning_amber_rounded,
                  number: true,
                ),
                _input(expiry, 'Hạn dùng YYYY-MM-DD', Icons.event_outlined),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Trạng thái'),
                  items: const [
                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                    DropdownMenuItem(
                      value: 'Inactive',
                      child: Text('Inactive'),
                    ),
                    DropdownMenuItem(
                      value: 'OutOfStock',
                      child: Text('OutOfStock'),
                    ),
                  ],
                  onChanged: (value) =>
                      setSheetState(() => status = value ?? 'Active'),
                ),
                const SizedBox(height: 10),
                _input(description, 'Mô tả', Icons.notes_rounded, maxLines: 3),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _primary),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Lưu thuốc'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved != true) return;

    final validation = _validateMedicineForm(
      name.text,
      active.text,
      type.text,
      unit.text,
      price.text,
      stock.text,
      minStock.text,
      expiry.text,
    );
    if (validation != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validation)));
      return;
    }

    final payload = {
      'medicineName': name.text.trim(),
      'activeIngredient': active.text.trim(),
      'medicineType': type.text.trim(),
      'unit': unit.text.trim(),
      'price': double.tryParse(price.text.trim()) ?? 0,
      'stockQuantity': int.tryParse(stock.text.trim()) ?? 0,
      'minStockLevel': int.tryParse(minStock.text.trim()) ?? 10,
      'expiryDate': expiry.text.trim().isEmpty ? null : expiry.text.trim(),
      'status': status,
      'description': description.text.trim().isEmpty
          ? null
          : description.text.trim(),
    };

    await _run(
      () => id > 0
          ? controller.updateMedicine(id, payload)
          : controller.createMedicine(payload),
    );
  }

  Future<void> _confirmDeleteMedicine(
    NurseDashboardController controller,
    int id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạm ngưng thuốc'),
        content: Text('Tạm ngưng "$name" trong kho dược?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Đóng'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tạm ngưng'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(() => controller.deleteMedicine(id));
    }
  }

  Future<void> _showInventorySlipForm(
    NurseDashboardController controller,
  ) async {
    final supplier = TextEditingController();
    final invoiceImageUrl = TextEditingController();
    final note = TextEditingController();

    List<Map<String, TextEditingController>> rows = [_newSlipItemControllers()];

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tạo phiếu nhập kho',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                _input(supplier, 'Nhà cung cấp', Icons.business_outlined),
                _input(
                  invoiceImageUrl,
                  'Anh hoa don URL',
                  Icons.image_outlined,
                ),
                _input(note, 'Ghi chu phieu', Icons.notes_rounded, maxLines: 2),
                const SizedBox(height: 8),
                for (var i = 0; i < rows.length; i++) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: _box(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Dòng thuốc ${i + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: _text,
                                ),
                              ),
                            ),
                            if (rows.length > 1)
                              IconButton(
                                tooltip: 'Xoa dong',
                                onPressed: () => setSheetState(
                                  () => rows = [...rows]..removeAt(i),
                                ),
                                icon: const Icon(Icons.close_rounded),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _input(
                          rows[i]['medicineId']!,
                          'Mã thuốc',
                          Icons.medication_liquid_rounded,
                          number: true,
                        ),
                        _input(
                          rows[i]['batchNumber']!,
                          'So lo',
                          Icons.confirmation_number_outlined,
                        ),
                        _input(
                          rows[i]['expiryDate']!,
                          'Hạn dùng YYYY-MM-DD',
                          Icons.event_outlined,
                        ),
                        _input(
                          rows[i]['quantity']!,
                          'So luong',
                          Icons.add_box_outlined,
                          number: true,
                        ),
                        _input(
                          rows[i]['importPrice']!,
                          'Giá nhập',
                          Icons.payments_outlined,
                          number: true,
                        ),
                        _input(
                          rows[i]['note']!,
                          'Ghi chu dong',
                          Icons.notes_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => setSheetState(
                      () => rows = [...rows, _newSlipItemControllers()],
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Thêm dòng thuốc'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _primary),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Gửi yêu cầu'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved != true) return;

    final validation = _validateSlipRows(rows);
    if (validation != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validation)));
      return;
    }

    final payload = {
      'supplierName': supplier.text.trim().isEmpty
          ? null
          : supplier.text.trim(),
      'invoiceImageUrl': invoiceImageUrl.text.trim().isEmpty
          ? null
          : invoiceImageUrl.text.trim(),
      'note': note.text.trim().isEmpty ? null : note.text.trim(),
      'items': rows
          .map(
            (row) => {
              'medicineId': int.tryParse(row['medicineId']!.text.trim()) ?? 0,
              'batchNumber': row['batchNumber']!.text.trim(),
              'expiryDate': row['expiryDate']!.text.trim().isEmpty
                  ? null
                  : row['expiryDate']!.text.trim(),
              'quantity': int.tryParse(row['quantity']!.text.trim()) ?? 1,
              'importPrice': row['importPrice']!.text.trim().isEmpty
                  ? null
                  : double.tryParse(row['importPrice']!.text.trim()),
              'note': row['note']!.text.trim().isEmpty
                  ? null
                  : row['note']!.text.trim(),
            },
          )
          .toList(),
    };

    await _run(() => controller.createSlip(payload));
  }

  Map<String, TextEditingController> _newSlipItemControllers() {
    return {
      'medicineId': TextEditingController(),
      'batchNumber': TextEditingController(),
      'expiryDate': TextEditingController(),
      'quantity': TextEditingController(text: '1'),
      'importPrice': TextEditingController(),
      'note': TextEditingController(),
    };
  }

  String? _validateSlipRows(List<Map<String, TextEditingController>> rows) {
    if (rows.isEmpty) return 'Phiếu nhập kho phải có ít nhất 1 dòng thuốc.';
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final medicineId = int.tryParse(row['medicineId']!.text.trim());
      final quantity = int.tryParse(row['quantity']!.text.trim());
      final importPrice = row['importPrice']!.text.trim().isEmpty
          ? 0
          : double.tryParse(row['importPrice']!.text.trim());
      final expiry = row['expiryDate']!.text.trim();
      if (medicineId == null || medicineId <= 0) {
        return 'Dòng ${i + 1}: Mã thuốc không hợp lệ.';
      }
      if (row['batchNumber']!.text.trim().isEmpty) {
        return 'Dòng ${i + 1}: Số lô không được để trống.';
      }
      if (expiry.isNotEmpty && DateTime.tryParse(expiry) == null) {
        return 'Dòng ${i + 1}: Hạn dùng phải có dạng YYYY-MM-DD.';
      }
      if (quantity == null || quantity <= 0) {
        return 'Dòng ${i + 1}: Số lượng phải lớn hơn 0.';
      }
      if (importPrice == null || importPrice < 0) {
        return 'Dòng ${i + 1}: Giá nhập không hợp lệ.';
      }
    }
    return null;
  }

  // ignore: unused_element
  Future<void> _showSlipForm(NurseDashboardController controller) async {
    final supplier = TextEditingController();
    final note = TextEditingController();
    final medicineId = TextEditingController();
    final batch = TextEditingController();
    final expiry = TextEditingController();
    final quantity = TextEditingController(text: '1');
    final price = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tạo phiếu nhập kho',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              _input(supplier, 'Nhà cung cấp', Icons.business_outlined),
              _input(
                medicineId,
                'Mã thuốc',
                Icons.medication_liquid_rounded,
                number: true,
              ),
              _input(batch, 'Số lô', Icons.confirmation_number_outlined),
              _input(expiry, 'Hạn dùng YYYY-MM-DD', Icons.event_outlined),
              _input(
                quantity,
                'Số lượng',
                Icons.add_box_outlined,
                number: true,
              ),
              _input(price, 'Giá nhập', Icons.payments_outlined, number: true),
              _input(note, 'Ghi chú', Icons.notes_rounded, maxLines: 3),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _primary),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Gửi yêu cầu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved == true) {
      if (medicineId.text.trim().isEmpty ||
          batch.text.trim().isEmpty ||
          expiry.text.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập mã thuốc, số lô và hạn dùng.'),
          ),
        );
        return;
      }
      final payload = {
        'supplierName': supplier.text.trim(),
        'note': note.text.trim(),
        'items': [
          {
            'medicineId': int.tryParse(medicineId.text.trim()) ?? 0,
            'batchNumber': batch.text.trim(),
            'expiryDate': expiry.text.trim(),
            'quantity': int.tryParse(quantity.text.trim()) ?? 1,
            'importPrice': double.tryParse(price.text.trim()),
            'note': note.text.trim(),
          },
        ],
      };
      await _run(() => controller.createSlip(payload));
    }
  }

  Widget _input(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool number = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  void _showDetails(String title, List<Widget> rows) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _text,
                ),
              ),
              const SizedBox(height: 12),
              ...rows,
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _popupSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 16, color: _primary),
                const SizedBox(width: 6),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _popupRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: value is Widget
                ? Align(alignment: Alignment.centerRight, child: value)
                : Text(
                    value.toString(),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _popupRowVertical(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _popupBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _showPrescriptionDetails({
    required int id,
    required String patientName,
    required String patientCode,
    required String patientPhone,
    required String patientGender,
    required String patientDob,
    required String patientAddress,
    required String doctorName,
    required String doctorCode,
    required String doctorSpecialty,
    required int appointmentId,
    required int recordId,
    required String created,
    required String diagnosis,
    required String meds,
    required String stockStatus,
    required String invoiceStatus,
    required String status,
  }) {
    final medList = meds.split(RegExp(r',\s*')).where((m) => m.trim().isNotEmpty).toList();

    final stockColor = stockStatus.toLowerCase().contains('avail')
        ? _success
        : stockStatus.toLowerCase().contains('short')
            ? _danger
            : _pending;
    final stockText = stockStatus.toLowerCase().contains('avail')
        ? 'Sẵn sàng'
        : stockStatus.toLowerCase().contains('short')
            ? 'Thiếu hàng'
            : stockStatus;

    final invoiceColor = invoiceStatus.toLowerCase().contains('paid')
        ? _success
        : invoiceStatus.toLowerCase().contains('unpaid')
            ? _danger
            : _pending;
    final invoiceText = invoiceStatus.toLowerCase().contains('paid')
        ? 'Đã thanh toán'
        : invoiceStatus.toLowerCase().contains('unpaid')
            ? 'Chưa thanh toán'
            : invoiceStatus;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chi tiết đơn thuốc',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      'DT-$id',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _popupSection(
                      title: 'Thông tin bệnh nhân',
                      icon: Icons.person_rounded,
                      children: [
                        _popupRow('Họ tên bệnh nhân', patientName),
                        if (patientCode.isNotEmpty) _popupRow('Mã bệnh nhân', patientCode),
                        if (patientPhone.isNotEmpty) _popupRow('Số điện thoại', patientPhone),
                        if (patientGender.isNotEmpty || patientDob.isNotEmpty)
                          _popupRow(
                            'Giới tính / Ngày sinh',
                            '${patientGender.isNotEmpty ? patientGender : '--'} / ${patientDob.isNotEmpty ? patientDob : '--'}',
                          ),
                        if (patientAddress.isNotEmpty)
                          _popupRowVertical('Địa chỉ', patientAddress),
                      ],
                    ),
                    _popupSection(
                      title: 'Thông tin chỉ định',
                      icon: Icons.medical_services_rounded,
                      children: [
                        _popupRow('Bác sĩ kê đơn', 'BS. $doctorName'),
                        if (doctorCode.isNotEmpty) _popupRow('Mã bác sĩ', doctorCode),
                        if (doctorSpecialty.isNotEmpty) _popupRow('Chuyên khoa', doctorSpecialty),
                        if (appointmentId > 0) _popupRow('Mã lịch hẹn', 'LH-$appointmentId'),
                        if (recordId > 0) _popupRow('Mã hồ sơ khám', 'HS-$recordId'),
                        _popupRowVertical('Chẩn đoán', diagnosis),
                      ],
                    ),
                    _popupSection(
                      title: 'Thuốc kê đơn',
                      icon: Icons.local_pharmacy_rounded,
                      children: medList.isEmpty
                          ? [
                              const Text(
                                'Chưa có danh sách thuốc',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            ]
                          : medList.map((med) => Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.circle, size: 6, color: _primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      med,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                    ),
                    _popupSection(
                      title: 'Trạng thái & Thanh toán',
                      icon: Icons.payments_rounded,
                      children: [
                        _popupRow('Ngày lập', created.isNotEmpty ? created : '--/--/----'),
                        _popupRow('Trạng thái đơn', _popupBadge(_statusLabel(status), _statusColor(status))),
                        _popupRow('Tồn kho dược phẩm', _popupBadge(stockText, stockColor)),
                        _popupRow('Trạng thái hóa đơn', _popupBadge(invoiceText, invoiceColor)),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Đóng',
                      style: TextStyle(
                        fontSize: 14,
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
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: _text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String? _validateMedicineForm(
    String name,
    String activeIngredient,
    String medicineType,
    String unit,
    String price,
    String stock,
    String minStock,
    String expiry,
  ) {
    if (name.trim().isEmpty) return 'Tên thuốc không được để trống.';
    if (activeIngredient.trim().isEmpty) {
      return 'Hoạt chất không được để trống.';
    }
    if (medicineType.trim().isEmpty) return 'Loại thuốc không được để trống.';
    if (unit.trim().isEmpty) return 'Đơn vị tính không được để trống.';
    final parsedPrice = double.tryParse(price.trim());
    final parsedStock = int.tryParse(stock.trim());
    final parsedMinStock = int.tryParse(minStock.trim());
    if (parsedPrice == null || parsedPrice < 0) {
      return 'Giá bán phải lớn hơn hoặc bằng 0.';
    }
    if (parsedStock == null || parsedStock < 0) {
      return 'Tồn kho phải lớn hơn hoặc bằng 0.';
    }
    if (parsedMinStock == null || parsedMinStock < 0) {
      return 'Ngưỡng cảnh báo phải lớn hơn hoặc bằng 0.';
    }
    if (expiry.trim().isNotEmpty && DateTime.tryParse(expiry.trim()) == null) {
      return 'Hạn dùng phải có dạng YYYY-MM-DD.';
    }
    return null;
  }

  String? _validateVitals(
    String temperature,
    String bloodPressure,
    String heartRate,
    String respiratoryRate,
    String spo2,
    String height,
    String weight,
    String note,
  ) {
    final temp = double.tryParse(temperature);
    final hr = double.tryParse(heartRate);
    final rr = double.tryParse(respiratoryRate);
    final sp = double.tryParse(spo2);
    final h = double.tryParse(height);
    final w = double.tryParse(weight);
    if (temp == null || temp < 30 || temp > 45) {
      return 'Nhiệt độ phải nằm trong khoảng 30-45°C.';
    }
    if (!RegExp(r'^\d{2,3}\s*/\s*\d{2,3}$').hasMatch(bloodPressure.trim())) {
      return 'Huyết áp phải có dạng 120/80.';
    }
    if (hr == null || hr < 1 || hr > 250) {
      return 'Mạch phải nằm trong khoảng 1-250.';
    }
    if (rr == null || rr < 1 || rr > 100) {
      return 'Nhịp thở phải nằm trong khoảng 1-100.';
    }
    if (sp == null || sp < 1 || sp > 100) {
      return 'SpO2 phải nằm trong khoảng 1-100%.';
    }
    if (h == null || h < 1 || h > 300) {
      return 'Chiều cao phải nằm trong khoảng 1-300 cm.';
    }
    if (w == null || w < 1 || w > 500) {
      return 'Cân nặng phải nằm trong khoảng 1-500 kg.';
    }
    if (bloodPressure.length > 30) {
      return 'Huyết áp tối đa 30 ký tự.';
    }
    if (note.length > 500) {
      return 'Ghi chú tối đa 500 ký tự.';
    }
    return null;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  dynamic _value(dynamic source, List<String> keys) {
    final map = _asMap(source);
    for (final key in keys) {
      if (map.containsKey(key) && map[key] != null) return map[key];
    }
    return null;
  }

  List<dynamic> _list(dynamic value) {
    if (value is List) return value;
    return const [];
  }

  int _id(dynamic item, List<String> keys) {
    final value = _value(item, keys);
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _idText(dynamic item, List<String> keys) => _id(item, keys).toString();

  String _str(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  int _num(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double? _nullableNum(String value) {
    if (value.trim().isEmpty) return null;
    return double.tryParse(value.trim());
  }

  String _safeDate(dynamic date) {
    if (date == null) return '';
    final text = date.toString();
    return text.length >= 10 ? text.substring(0, 10) : text;
  }

  String _todayIso() => DateTime.now().toIso8601String().substring(0, 10);

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value.isEmpty ? '--' : value;
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  String _money(dynamic value) {
    final amount = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    final text = amount.toInt().toString();
    final buffer = StringBuffer();
    var count = 0;
    for (var i = text.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(text[i]);
      count++;
    }
    return '${buffer.toString().split('').reversed.join()} đ';
  }

  String _normalize(String value) {
    return value.toLowerCase().trim();
  }

  String _bucket(dynamic raw) {
    final value = _normalize(raw?.toString() ?? '');
    if (value.contains('cancel') ||
        value.contains('reject') ||
        value.contains('void')) {
      return 'cancelled';
    }
    if (value.contains('complete') || value.contains('done')) {
      return 'completed';
    }
    if (value.contains('exam') || value.contains('progress')) {
      return 'inprogress';
    }
    if (value.contains('checked')) {
      return 'checkedin';
    }
    if (value.contains('confirm') || value.contains('scheduled')) {
      return 'confirmed';
    }
    if (value.contains('paid')) {
      return 'paid';
    }
    if (value.contains('unpaid')) {
      return 'unpaid';
    }
    if (value.contains('pending') || value.contains('waiting')) {
      return 'pending';
    }
    return value.isEmpty ? 'pending' : value;
  }

  String _prescriptionBucket(dynamic item) {
    final status = _normalize(
      _value(item, ['status', 'prescriptionStatus'])?.toString() ?? '',
    );
    if (status.contains('dispensed') ||
        status.contains('đã phát') ||
        status.contains('da phat')) {
      return 'dispensed';
    }
    if (status.contains('cancel')) {
      return 'cancelled';
    }
    if (status.contains('ready') ||
        status.contains('approved') ||
        status.contains('sent')) {
      return 'ready';
    }
    return 'pending';
  }

  String _stockBucket(dynamic item) {
    final stock = _num(_value(item, ['stockQuantity', 'stock', 'quantity']));
    final minStock = _num(
      _value(item, ['minStockLevel', 'minStock']),
      fallback: 10,
    );
    if (stock <= 0) return 'out';
    if (stock <= minStock) return 'low';
    return 'normal';
  }

  bool _medicineMatchesFilter(dynamic item, String filter) {
    final normalized = filter.toLowerCase();
    if (['low', 'normal', 'out'].contains(normalized)) {
      return _stockBucket(item) == normalized;
    }
    final expiryText = _safeDate(_value(item, ['expiryDate']));
    final expiry = DateTime.tryParse(expiryText);
    if (expiry == null) return false;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final expiryDate = DateTime(expiry.year, expiry.month, expiry.day);
    if (normalized == 'expired') {
      return expiryDate.isBefore(todayDate);
    }
    if (normalized == 'expiring') {
      final days = expiryDate.difference(todayDate).inDays;
      return days >= 0 && days <= 30;
    }
    return true;
  }

  bool _isLowStockMedicine(dynamic item) =>
      ['low', 'out'].contains(_stockBucket(item));

  bool _isPaid(dynamic item) {
    final status = _normalize(
      _value(item, ['status', 'invoiceStatus'])?.toString() ?? '',
    );
    return status.contains('paid') && !status.contains('unpaid');
  }

  String _medicineSummary(dynamic item) {
    final direct = _value(item, ['medicineName', 'medicine', 'summary']);
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString();
    }
    final meds = _list(
      _value(item, ['medicines', 'items', 'details', 'prescriptionItems']),
    );
    return meds
        .take(3)
        .map((m) {
          final name = _str(_value(m, ['medicineName', 'name']), 'Thuốc');
          final qty = _str(_value(m, ['quantity', 'amount']), '1');
          return '$name x$qty';
        })
        .join(', ');
  }

  String _prescriptionPatientName(
    dynamic prescription,
    NurseDashboardController controller,
  ) {
    final direct = _firstNonEmpty(prescription, [
      'patientName',
      'PatientName',
      'patientFullName',
      'PatientFullName',
      'patientNameSnapshot',
      'PatientNameSnapshot',
    ]);
    if (direct.isNotEmpty) return direct;

    final nestedPatient = _value(prescription, ['patient', 'Patient']);
    final nestedName = _firstNonEmpty(nestedPatient, [
      'fullName',
      'FullName',
      'name',
      'Name',
      'patientName',
      'PatientName',
    ]);
    if (nestedName.isNotEmpty) return nestedName;

    final appointment = _findPrescriptionAppointment(prescription, controller);
    final appointmentName = _firstNonEmpty(appointment, [
      'patientName',
      'PatientName',
      'patientNameSnapshot',
      'PatientNameSnapshot',
      'fullName',
      'FullName',
    ]);
    if (appointmentName.isNotEmpty) return appointmentName;

    final patientId = _id(prescription, ['patientId', 'PatientId']);
    if (patientId > 0) {
      for (final patient in controller.patients) {
        if (_id(patient, ['patientId', 'id', 'PatientId', 'Id']) == patientId) {
          final patientName = _firstNonEmpty(patient, [
            'fullName',
            'FullName',
            'name',
            'Name',
            'patientName',
            'PatientName',
          ]);
          if (patientName.isNotEmpty) return patientName;
        }
      }
      return 'Bệnh nhân BN-$patientId';
    }

    return 'Chưa rõ bệnh nhân';
  }

  String _prescriptionDoctorName(
    dynamic prescription,
    NurseDashboardController controller,
  ) {
    final direct = _firstNonEmpty(prescription, [
      'doctorName',
      'DoctorName',
      'doctorFullName',
      'DoctorFullName',
      'doctorNameSnapshot',
      'DoctorNameSnapshot',
    ]);
    if (direct.isNotEmpty) return _stripDoctorPrefix(direct);

    final nestedDoctor = _value(prescription, ['doctor', 'Doctor']);
    final nestedName = _firstNonEmpty(nestedDoctor, [
      'fullName',
      'FullName',
      'name',
      'Name',
      'doctorName',
      'DoctorName',
    ]);
    if (nestedName.isNotEmpty) return _stripDoctorPrefix(nestedName);

    final appointment = _findPrescriptionAppointment(prescription, controller);
    final appointmentDoctor = _firstNonEmpty(appointment, [
      'doctorName',
      'DoctorName',
      'doctorNameSnapshot',
      'DoctorNameSnapshot',
      'fullName',
      'FullName',
    ]);
    if (appointmentDoctor.isNotEmpty) {
      return _stripDoctorPrefix(appointmentDoctor);
    }

    final doctorId = _id(prescription, ['doctorId', 'DoctorId']);
    if (doctorId > 0) {
      for (final appointment in controller.appointments) {
        if (_id(appointment, ['doctorId', 'DoctorId']) == doctorId) {
          final name = _firstNonEmpty(appointment, [
            'doctorName',
            'DoctorName',
            'doctorNameSnapshot',
            'DoctorNameSnapshot',
          ]);
          if (name.isNotEmpty) return _stripDoctorPrefix(name);
        }
      }
      return 'Bác sĩ BS-$doctorId';
    }

    return 'Chưa rõ bác sĩ';
  }

  dynamic _findPrescriptionAppointment(
    dynamic prescription,
    NurseDashboardController controller,
  ) {
    final appointmentId = _id(prescription, ['appointmentId', 'AppointmentId']);
    final patientId = _id(prescription, ['patientId', 'PatientId']);
    final doctorId = _id(prescription, ['doctorId', 'DoctorId']);
    if (appointmentId > 0) {
      for (final appointment in controller.appointments) {
        if (_id(appointment, ['appointmentId', 'id', 'AppointmentId', 'Id']) ==
            appointmentId) {
          return appointment;
        }
      }
    }
    if (patientId > 0 && doctorId > 0) {
      for (final appointment in controller.appointments) {
        if (_id(appointment, ['patientId', 'PatientId']) == patientId &&
            _id(appointment, ['doctorId', 'DoctorId']) == doctorId) {
          return appointment;
        }
      }
    }
    return null;
  }

  String _firstNonEmpty(dynamic source, List<String> keys) {
    for (final key in keys) {
      final value = _value(source, [key]);
      final text = _str(value);
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  String _stripDoctorPrefix(String value) {
    return value
        .replaceFirst(
          RegExp(r'^\s*(BS\.?|Bác sĩ|Bac si)\s*', caseSensitive: false),
          '',
        )
        .trim();
  }

  Map<String, dynamic> _parseVitals(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }

  Color _statusColor(String status) {
    final bucket = _bucket(status);
    if (bucket == 'completed' ||
        bucket == 'paid' ||
        bucket == 'dispensed' ||
        bucket == 'normal') {
      return _success;
    }
    if (bucket == 'confirmed' ||
        bucket == 'checkedin' ||
        bucket == 'inprogress' ||
        bucket == 'ready') {
      return _info;
    }
    if (bucket == 'cancelled' || bucket == 'out' || bucket == 'unpaid') {
      return _danger;
    }
    return _pending;
  }

  String _statusLabel(String status) {
    final bucket = _bucket(status);
    switch (bucket) {
      case 'pending':
        return 'Chờ xử lý';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'checkedin':
        return 'Đã check-in';
      case 'inprogress':
        return 'Đang khám';
      case 'completed':
        return 'Hoàn tất';
      case 'cancelled':
        return 'Đã hủy';
      case 'paid':
        return 'Đã thanh toán';
      case 'unpaid':
        return 'Chưa thanh toán';
      case 'ready':
        return 'Sẵn sàng';
      case 'dispensed':
        return 'Đã phát thuốc';
      default:
        return status.isEmpty ? 'Chờ xử lý' : status;
    }
  }

  String _stockLabel(String bucket) {
    switch (bucket) {
      case 'out':
        return 'Hết hàng';
      case 'low':
        return 'Sắp hết';
      default:
        return 'Còn hàng';
    }
  }

  String _gender(dynamic value) {
    final text = _normalize(value?.toString() ?? '');
    if (text.contains('female') || text.contains('nữ')) return 'Nữ';
    if (text.contains('male') || text.contains('nam')) return 'Nam';
    return _str(value, 'Chưa có');
  }
}
