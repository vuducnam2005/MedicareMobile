import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/booking_controller.dart';
import '../../dashboard/controllers/patient_dashboard_controller.dart';
import '../models/specialty_model.dart';
import '../models/doctor_model.dart';

class PatientBookingView extends StatefulWidget {
  final VoidCallback? onBookingSuccess;

  const PatientBookingView({super.key, this.onBookingSuccess});

  @override
  State<PatientBookingView> createState() => _PatientBookingViewState();
}

class _PatientBookingViewState extends State<PatientBookingView> {
  int _currentStep = 1; // 1: Khoa & Ngày, 2: Bác sĩ, 3: Khung giờ, 4: Xác nhận

  SpecialtyModel? _selectedSpecialty;
  DoctorModel? _selectedDoctor;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  final TextEditingController _reasonController = TextEditingController();

  // Danh sách 14 ngày kể từ hôm nay để vẽ lịch tuần ngang
  List<DateTime> _weekDays = [];

  @override
  void initState() {
    super.initState();
    _generateWeekDays();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingController>().loadSpecialties();
    });
  }

  void _generateWeekDays() {
    final today = DateTime.now();
    _weekDays = List.generate(14, (index) => today.add(Duration(days: index)));
  }

  // Mở DatePicker khi nhấn biểu tượng lịch để chọn ngày xa hơn
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null; // Reset slot khi đổi ngày
        
        // Nếu ngày được chọn chưa có trong danh sách 14 ngày lịch tuần, thêm nó vào và sắp xếp
        final bool exists = _weekDays.any((d) => d.year == picked.year && d.month == picked.month && d.day == picked.day);
        if (!exists) {
          _weekDays.add(picked);
          _weekDays.sort((a, b) => a.compareTo(b));
        }
      });
      if (_selectedDoctor != null) {
        context.read<BookingController>().loadAvailableSlots(_selectedDoctor!.doctorId, _formatDateApi(_selectedDate));
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // Lấy Thứ bằng Tiếng Việt
  String _getWeekdayAbbr(DateTime date) {
    final today = DateTime.now();
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'H.nay';
    }
    switch (date.weekday) {
      case 1: return 'T2';
      case 2: return 'T3';
      case 3: return 'T4';
      case 4: return 'T5';
      case 5: return 'T6';
      case 6: return 'T7';
      case 7: return 'CN';
      default: return '';
    }
  }

  // Định dạng ngày hiển thị (DD/MM/YYYY)
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Định dạng ngày gửi API (YYYY-MM-DD)
  String _formatDateApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Định dạng tiền tệ
  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ';
  }

  // Ánh xạ icon cho chuyên khoa
  IconData _getSpecialtyIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('tim') || lower.contains('mạch')) return Icons.favorite_rounded;
    if (lower.contains('nhi') || lower.contains('trẻ')) return Icons.child_care_rounded;
    if (lower.contains('da') || lower.contains('liễu')) return Icons.face_rounded;
    if (lower.contains('răng') || lower.contains('hàm') || lower.contains('mặt')) return Icons.medical_services_rounded;
    if (lower.contains('mắt') || lower.contains('nhãn')) return Icons.visibility_rounded;
    if (lower.contains('nội')) return Icons.healing_rounded;
    if (lower.contains('ngoại')) return Icons.accessibility_new_rounded;
    if (lower.contains('tai') || lower.contains('mũi') || lower.contains('họng')) return Icons.hearing_rounded;
    return Icons.vaccines_rounded;
  }

  // Ánh xạ màu sắc nhẹ nhàng (Pastel) cho icon chuyên khoa
  Color _getSpecialtyColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('tim')) return const Color(0xFFFFEBF0);
    if (lower.contains('nhi')) return const Color(0xFFE0F7FA);
    if (lower.contains('da')) return const Color(0xFFFFF3E0);
    if (lower.contains('mắt')) return const Color(0xFFE8F5E9);
    if (lower.contains('tai')) return const Color(0xFFEDE7F6);
    return const Color(0xFFE8EAF6);
  }

  Color _getSpecialtyIconColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('tim')) return const Color(0xFFEC4899);
    if (lower.contains('nhi')) return const Color(0xFF06B6D4);
    if (lower.contains('da')) return const Color(0xFFF59E0B);
    if (lower.contains('mắt')) return const Color(0xFF10B981);
    if (lower.contains('tai')) return const Color(0xFF8B5CF6);
    return const Color(0xFF6366F1);
  }

  @override
  Widget build(BuildContext context) {
    final bookingController = context.watch<BookingController>();
    final dashboardController = context.watch<PatientDashboardController>();
    final primaryColor = const Color(0xFF0F52BA);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP HEADER & MODERN STEP PROGRESS (Thiết kế tinh gọn cho Mobile)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Đặt lịch khám',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bước $_currentStep / 4: ${_getStepTitle()}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                          ),
                        ],
                      ),
                      // Hiển thị vòng tròn tiến trình
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${(_currentStep / 4 * 100).toInt()}%',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Thanh tiến trình ngang mượt mà
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _currentStep / 4,
                      backgroundColor: Colors.grey.shade100,
                      color: primaryColor,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

            // 2. NỘI DUNG TỪNG BƯỚC
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: SingleChildScrollView(
                  key: ValueKey<int>(_currentStep),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
                  child: Column(
                    children: [
                      if (_currentStep == 1) _buildStep1(bookingController, primaryColor),
                      if (_currentStep == 2) _buildStep2(bookingController, primaryColor),
                      if (_currentStep == 3) _buildStep3(bookingController, primaryColor),
                      if (_currentStep == 4) _buildStep4(dashboardController, bookingController, primaryColor),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1: return 'Chọn khoa & Ngày khám';
      case 2: return 'Chọn bác sĩ';
      case 3: return 'Chọn giờ khám';
      case 4: return 'Xác nhận thông tin';
      default: return '';
    }
  }

  // --- BƯỚC 1: CHỌN CHUYÊN KHOA & LỊCH TUẦN NGANG (NATIVE MOBILE) ---
  Widget _buildStep1(BookingController controller, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề chọn ngày dạng Lịch tuần ngang kết hợp nút Lịch mở rộng
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Chọn ngày khám', Icons.calendar_month_outlined, primaryColor),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: primaryColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Lịch',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lịch tuần ngang (Weekly Strip)
        SizedBox(
          height: 76,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _weekDays.length,
            itemBuilder: (context, index) {
              final date = _weekDays[index];
              final isSelected = date.year == _selectedDate.year &&
                                 date.month == _selectedDate.month &&
                                 date.day == _selectedDate.day;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                    _selectedTimeSlot = null; // Reset slot
                  });
                },
                child: Container(
                  width: 56,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey.shade200,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getWeekdayAbbr(date),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white70 : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // Tiêu đề chọn chuyên khoa dạng Grid Card thiết kế lại nằm ngang gọn gàng
        _buildSectionHeader('Chọn chuyên khoa', Icons.grid_view_rounded, primaryColor),
        const SizedBox(height: 12),

        if (controller.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.3, // childAspectRatio rộng hơn để icon và chữ nằm ngang gọn gàng
            ),
            itemCount: controller.specialties.length,
            itemBuilder: (context, index) {
              final spec = controller.specialties[index];
              final isSelected = _selectedSpecialty?.specialtyId == spec.specialtyId;

              final icon = _getSpecialtyIcon(spec.specialtyName);
              final bgColor = _getSpecialtyColor(spec.specialtyName);
              final iconColor = _getSpecialtyIconColor(spec.specialtyName);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSpecialty = spec;
                    _selectedDoctor = null;
                    _selectedTimeSlot = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: primaryColor.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 3))]
                        : [BoxShadow(color: Colors.black.withOpacity(0.005), blurRadius: 2, offset: const Offset(0, 1))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withOpacity(0.2) : bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? Colors.white : iconColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          spec.specialtyName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF1E293B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 32),

        // Nút tiếp tục nổi bật
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _selectedSpecialty == null
                ? null
                : () {
                    setState(() {
                      _currentStep = 2;
                    });
                    controller.loadDoctorsBySpecialty(_selectedSpecialty!.specialtyId);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade200,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Tiếp tục chọn bác sĩ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16, color: _selectedSpecialty == null ? Colors.grey : Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- BƯỚC 2: CHỌN BÁC SĨ (MÀN HÌNH NATIVE CỰC ĐẸP) ---
  Widget _buildStep2(BookingController controller, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Bác sĩ có lịch khám', Icons.people_outline, primaryColor),
        const SizedBox(height: 16),

        if (controller.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (controller.doctors.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
            ),
            width: double.infinity,
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.person_off_outlined, color: Colors.grey.shade300, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Không tìm thấy bác sĩ nào có lịch cho chuyên khoa này.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.doctors.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = controller.doctors[index];
              final isSelected = _selectedDoctor?.doctorId == doc.doctorId;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDoctor = doc;
                    _selectedTimeSlot = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey.shade200,
                      width: isSelected ? 1.8 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: primaryColor.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]
                        : [BoxShadow(color: Colors.black.withOpacity(0.005), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Avatar bác sĩ tròn trịa hoặc ảnh đại diện từ Web
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: bgColorForDoctor(doc.doctorName),
                              shape: BoxShape.circle,
                              image: doc.avatarUrl != null && doc.avatarUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(doc.avatarUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: doc.avatarUrl != null && doc.avatarUrl!.isNotEmpty
                                ? null
                                : Text(
                                    _getDocInitials(doc.doctorName),
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: iconColorForDoctor(doc.doctorName)),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc.doctorName.startsWith('BS') ? doc.doctorName : 'BS. ${doc.doctorName}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doc.degree ?? 'Bác sĩ chuyên khoa',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 14),
                                    const SizedBox(width: 4),
                                    const Text('4.9 (140 lượt khám)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                                    const Spacer(),
                                    Text(
                                      _formatCurrency(doc.examFee),
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: primaryColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, thickness: 0.5),
                      // Footer của thẻ bác sĩ: Nút xem thông tin chi tiết và Trạng thái chọn
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => _showDoctorDetailBottomSheet(context, doc, primaryColor),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 14, color: primaryColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Xem hồ sơ bác sĩ',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Row(
                              children: [
                                Text('Đã chọn', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                                SizedBox(width: 4),
                                Icon(Icons.check_circle, color: Colors.green, size: 15),
                              ],
                            )
                          else
                            Text(
                              'Chạm để chọn',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 1),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Text('Quay lại', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedDoctor == null
                    ? null
                    : () {
                        setState(() {
                          _currentStep = 3;
                        });
                        controller.loadAvailableSlots(_selectedDoctor!.doctorId, _formatDateApi(_selectedDate));
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Chọn giờ khám', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Bottom Sheet hiển thị hồ sơ chi tiết bác sĩ
  void _showDoctorDetailBottomSheet(BuildContext context, DoctorModel doc, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh ngang xám nhỏ trên cùng để kéo đóng
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Phần đầu thông tin bác sĩ
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: bgColorForDoctor(doc.doctorName),
                      shape: BoxShape.circle,
                      image: doc.avatarUrl != null && doc.avatarUrl!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(doc.avatarUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: doc.avatarUrl != null && doc.avatarUrl!.isNotEmpty
                        ? null
                        : Text(
                            _getDocInitials(doc.doctorName),
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: iconColorForDoctor(doc.doctorName)),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.doctorName.startsWith('BS') ? doc.doctorName : 'BS. ${doc.doctorName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doc.degree ?? 'Bác sĩ chuyên khoa',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doc.specialtyName,
                          style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, thickness: 1),
              
              // Chi tiết thông số
              const Text(
                'THÔNG TIN HỒ SƠ',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
              const SizedBox(height: 14),
              _buildDetailInfoRow(Icons.history_edu_rounded, 'Kinh nghiệm khám', '${doc.experienceYears ?? 8} năm kinh nghiệm'),
              const SizedBox(height: 12),
              _buildDetailInfoRow(Icons.meeting_room_rounded, 'Phòng khám làm việc', doc.roomNumber ?? 'Phòng khám Medicare'),
              const SizedBox(height: 12),
              _buildDetailInfoRow(Icons.payments_outlined, 'Phí khám lâm sàng', _formatCurrency(doc.examFee)),
              
              if (doc.email != null && doc.email!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDetailInfoRow(Icons.email_outlined, 'Email liên hệ', doc.email!),
              ],
              
              const Divider(height: 32, thickness: 1),
              
              // Giới thiệu bác sĩ
              const Text(
                'GIỚI THIỆU TÓM TẮT',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                doc.description ?? 'Bác sĩ chuyên môn cao, có nhiều năm kinh nghiệm nghiên cứu và điều trị thực tiễn. Luôn lắng nghe, chu đáo và đặt sức khỏe của bệnh nhân lên hàng đầu.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5),
              ),
              const SizedBox(height: 32),
              
              // Nút hành động chọn bác sĩ
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedDoctor = doc;
                      _selectedTimeSlot = null; // Reset slot
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Chọn bác sĩ này', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade400, size: 18),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  // --- BƯỚC 3: CHỌN KHUNG GIỜ ---
  Widget _buildStep3(BookingController controller, Color primaryColor) {
    // Phân chia Sáng/Chiều
    final morningSlots = controller.availableSlots.where((slot) {
      final hour = int.tryParse(slot.split(':')[0]) ?? 0;
      return hour < 12;
    }).toList();

    final afternoonSlots = controller.availableSlots.where((slot) {
      final hour = int.tryParse(slot.split(':')[0]) ?? 0;
      return hour >= 12;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Chọn thời gian khám', Icons.watch_later_outlined, primaryColor),
        const SizedBox(height: 16),

        if (controller.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (controller.availableSlots.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
            ),
            width: double.infinity,
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.event_busy_rounded, color: Colors.grey.shade300, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Bác sĩ không có ca trống trong ngày này.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else ...[
          // Khung giờ Sáng
          if (morningSlots.isNotEmpty) ...[
            _buildTimePeriodHeader('Buổi sáng', Icons.wb_sunny_rounded, Colors.orange),
            const SizedBox(height: 10),
            _buildTimeGrid(morningSlots, primaryColor),
            const SizedBox(height: 24),
          ],

          // Khung giờ Chiều
          if (afternoonSlots.isNotEmpty) ...[
            _buildTimePeriodHeader('Buổi chiều', Icons.wb_cloudy_rounded, Colors.blue),
            const SizedBox(height: 10),
            _buildTimeGrid(afternoonSlots, primaryColor),
          ],
        ],

        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 2),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Text('Quay lại', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedTimeSlot == null
                    ? null
                    : () {
                        setState(() {
                          _currentStep = 4;
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Tiếp tục', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimePeriodHeader(String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
        ),
      ],
    );
  }

  Widget _buildTimeGrid(List<String> slots, Color primaryColor) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 cột giúp hiển thị nhiều giờ trên một hàng, dễ đọc và so sánh
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.1, // Thiết kế nhỏ gọn, vuông vắn vừa vặn màn hình
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isSelected = _selectedTimeSlot == slot;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTimeSlot = slot;
            });
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade200),
              boxShadow: isSelected
                  ? [BoxShadow(color: primaryColor.withOpacity(0.12), blurRadius: 4, offset: const Offset(0, 2))]
                  : null,
            ),
            child: Text(
              slot,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- BƯỚC 4: XÁC NHẬN & TÓM TẮT ---
  Widget _buildStep4(PatientDashboardController dashboardController, BookingController controller, Color primaryColor) {
    final patient = dashboardController.patient;
    if (patient == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Text('Không tìm thấy thông tin hồ sơ của bạn. Vui lòng cập nhật hồ sơ trước.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Xác nhận thông tin đặt khám', Icons.fact_check_outlined, primaryColor),
        const SizedBox(height: 16),

        // TẤM VÉ ĐẶT LỊCH (TICKET CARD) - THIẾT KẾ ĐỘC QUYỀN CHO MOBILE
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. PHẦN TRÊN: THÔNG TIN LỊCH HẸN KHÁM
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.local_hospital_rounded, color: primaryColor, size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'THÔNG TIN HẸN KHÁM',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: primaryColor.withOpacity(0.08),
                          child: Icon(Icons.person, color: primaryColor, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedDoctor?.doctorName ?? 'Bác sĩ chưa cập nhật',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedSpecialty?.specialtyName ?? 'Chuyên khoa ngoại',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Badge ngày giờ nổi bật
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF3FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_filled_rounded, color: Color(0xFF0F52BA), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$_selectedTimeSlot  -  ${_formatDate(_selectedDate)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F52BA),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. ĐƯỜNG RÃNH VÉ (TICKET CUTOUT & DASHED LINE)
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC), // Khớp màu nền trang
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Flex(
                          direction: Axis.horizontal,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            (constraints.constrainWidth() / 8).floor(),
                            (index) => SizedBox(
                              width: 4,
                              height: 1,
                              child: DecoratedBox(
                                decoration: BoxDecoration(color: Colors.grey.shade200),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC), // Khớp màu nền trang
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),

              // 3. PHẦN DƯỚI: THÔNG TIN HÀNH CHÍNH BỆNH NHÂN
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_pin_rounded, color: Colors.teal, size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'THÔNG TIN BỆNH NHÂN',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTicketRow(Icons.badge_outlined, 'Họ và tên', patient.fullName),
                    const SizedBox(height: 12),
                    _buildTicketRow(Icons.cake_outlined, 'Ngày sinh', _formatDate(DateTime.parse(patient.dateOfBirth ?? DateTime.now().toString()))),
                    const SizedBox(height: 12),
                    _buildTicketRow(Icons.wc_outlined, 'Giới tính', patient.gender ?? 'Chưa cập nhật'),
                    const SizedBox(height: 12),
                    _buildTicketRow(Icons.phone_android_outlined, 'Số điện thoại', patient.phoneNumber ?? 'Chưa cập nhật'),
                    const SizedBox(height: 12),
                    _buildTicketRow(Icons.co_present_outlined, 'Số CCCD', patient.citizenId ?? 'Chưa cập nhật'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Nhập lý do khám
        const Text('Lý do khám bệnh *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        TextField(
          controller: _reasonController,
          maxLines: 2,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Mô tả ngắn gọn lý do khám hoặc triệu chứng...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.normal),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
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
        const SizedBox(height: 20),

        // Thống kê tổng tiền nằm ngay trước nút
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng chi phí dự kiến', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
              Text(
                _formatCurrency(_selectedDoctor?.examFee ?? 0),
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (controller.errorMessage != null) ...[
          Text(
            controller.errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
          const SizedBox(height: 12),
        ],

        // Bộ đôi nút xác nhận
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 3),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Text('Quay lại', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: controller.isLoading
                    ? null
                    : () => _confirmBooking(context, controller, patient.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: controller.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Đặt lịch ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTicketRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade400, size: 16),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color primaryColor) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }

  // Tiện ích lấy ký tự viết tắt tên bác sĩ
  String _getDocInitials(String name) {
    final cleanName = name.replaceAll(RegExp(r'^(BS\.|BS|Bác sĩ)\s*'), '').trim();
    final words = cleanName.split(' ');
    if (words.isEmpty) return 'BS';
    if (words.length == 1) return words[0].substring(0, 1).toUpperCase();
    return (words[words.length - 2].substring(0, 1) + words[words.length - 1].substring(0, 1)).toUpperCase();
  }

  // Tự sinh màu pastel cho avatar dựa trên tên bác sĩ
  Color bgColorForDoctor(String name) {
    final hash = name.hashCode;
    final colors = [
      const Color(0xFFFFEBEE),
      const Color(0xFFE3F2FD),
      const Color(0xFFE8F5E9),
      const Color(0xFFFFF3E0),
      const Color(0xFFF3E5F5),
      const Color(0xFFE0F7FA),
    ];
    return colors[hash.abs() % colors.length];
  }

  Color iconColorForDoctor(String name) {
    final hash = name.hashCode;
    final colors = [
      const Color(0xFFC62828),
      const Color(0xFF1565C0),
      const Color(0xFF2E7D32),
      const Color(0xFFEF6C00),
      const Color(0xFF6A1B9A),
      const Color(0xFF00838F),
    ];
    return colors[hash.abs() % colors.length];
  }

  Future<void> _confirmBooking(BuildContext context, BookingController controller, int patientId) async {
    final String reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập lý do khám bệnh!'), backgroundColor: Colors.red),
      );
      return;
    }

    final patient = context.read<PatientDashboardController>().patient!;

    final appointment = await controller.submitBooking(
      patientId: patientId,
      patientName: patient.fullName,
      patientPhone: patient.phoneNumber ?? '',
      patientEmail: patient.email ?? '',
      patientDob: patient.dateOfBirth ?? '',
      patientGender: patient.gender ?? '',
      patientCitizenId: patient.citizenId ?? '',
      doctorId: _selectedDoctor!.doctorId,
      appointmentDate: _formatDateApi(_selectedDate),
      slotTime: _selectedTimeSlot!,
      reason: reason,
      examFee: _selectedDoctor!.examFee,
    );

    if (appointment != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đặt lịch khám thành công! Mã cuộc hẹn: ${appointment.id}'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reset form
      setState(() {
        _currentStep = 1;
        _selectedSpecialty = null;
        _selectedDoctor = null;
        _selectedTimeSlot = null;
        _reasonController.clear();
      });

      // Gọi callback thành công để chuyển tab
      if (widget.onBookingSuccess != null) {
        widget.onBookingSuccess!();
      }
    }
  }
}
