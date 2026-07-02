import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dashboard/controllers/doctor_dashboard_controller.dart';

class DoctorExamineView extends StatefulWidget {
  final Map<String, dynamic> visit;
  final int doctorId;

  const DoctorExamineView({
    super.key,
    required this.visit,
    required this.doctorId,
  });

  @override
  State<DoctorExamineView> createState() => _DoctorExamineViewState();
}

class _DoctorExamineViewState extends State<DoctorExamineView> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Controllers cho Step 1 (Sinh hiệu & Bệnh án)
  final _bpController = TextEditingController(); // Huyết áp
  final _hrController = TextEditingController(); // Nhịp tim
  final _tempController = TextEditingController(); // Nhiệt độ
  final _spo2Controller = TextEditingController(); // SPO2
  final _symptomsController = TextEditingController(); // Triệu chứng
  final _diagnosisController = TextEditingController(); // Chẩn đoán
  final _noteController = TextEditingController(); // Lời dặn
  final _planController = TextEditingController(); // Kế hoạch điều trị
  DateTime? _followUpDate;

  // Đơn thuốc (Step 2)
  final List<Map<String, dynamic>> _prescribedMedicines = [];

  @override
  void initState() {
    super.initState();
    // Prefill triệu chứng từ lý do khám của bệnh nhân
    _symptomsController.text = widget.visit['chiefComplaint'] ?? '';
    // Khởi chạy chế độ bắt đầu khám trên backend
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorDashboardController>().startVisit(
            widget.visit['visitId'] ?? widget.visit['id'] ?? 0,
            widget.doctorId,
            widget.visit['chiefComplaint'] ?? 'Khám lâm sàng',
          );
    });
  }

  @override
  void dispose() {
    _bpController.dispose();
    _hrController.dispose();
    _tempController.dispose();
    _spo2Controller.dispose();
    _symptomsController.dispose();
    _diagnosisController.dispose();
    _noteController.dispose();
    _planController.dispose();
    super.dispose();
  }

  Future<void> _selectFollowUpDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F52BA), // Header
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _followUpDate) {
      setState(() {
        _followUpDate = picked;
      });
    }
  }

  // Thực hiện lưu bệnh án và kê đơn thuốc (Gọi liên thông cả 3 microservice)
  Future<void> _handleSubmitExamine() async {
    if (_diagnosisController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập chẩn đoán bệnh!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final controller = context.read<DoctorDashboardController>();
    final int visitId = widget.visit['visitId'] ?? widget.visit['id'] ?? 0;

    try {
      // 1. Cập nhật chỉ số sinh tồn (nếu có nhập)
      if (_bpController.text.isNotEmpty || _tempController.text.isNotEmpty || _hrController.text.isNotEmpty) {
        await controller.updateVitals(visitId, {
          'bloodPressure': _bpController.text.trim(),
          'temperature': double.tryParse(_tempController.text.trim()),
          'heartRate': int.tryParse(_hrController.text.trim()),
          'spo2': int.tryParse(_spo2Controller.text.trim()),
        });
      }

      // 2. Tạo hồ sơ bệnh án (N2)
      final record = await controller.createMedicalRecord(
        visitId: visitId,
        diagnosisText: _diagnosisController.text.trim(),
        doctorNote: _noteController.text.trim(),
        treatmentPlan: _planController.text.trim(),
        followUpDate: _followUpDate != null ? _followUpDate!.toIso8601String().substring(0, 10) : null,
      );

      if (record == null) {
        throw Exception('Không thể tạo hồ sơ bệnh án trên hệ thống.');
      }

      final int medicalRecordId = record['medicalRecordId'] ?? record['id'] ?? 0;

      // 3. Nếu có thuốc, thực hiện kê đơn thuốc (N3)
      if (_prescribedMedicines.isNotEmpty && medicalRecordId > 0) {
        final prescription = await controller.createPrescription(medicalRecordId, _noteController.text.trim());
        if (prescription != null) {
          final int prescriptionId = prescription['prescriptionId'] ?? prescription['id'] ?? 0;
          
          // Chuyển đổi định dạng danh sách thuốc kê để gửi lên API
          final List<Map<String, dynamic>> itemsPayload = _prescribedMedicines.map((item) {
            return {
              'medicineId': item['medicineId'],
              'medicineNameSnapshot': item['name'],
              'unitSnapshot': item['unit'] ?? 'Viên',
              'dosage': item['dosage'],
              'frequency': item['frequency'],
              'durationDays': item['durationDays'],
              'quantity': item['quantity'],
              'usageInstruction': item['note'] ?? '',
            };
          }).toList();

          await controller.submitPrescription(
            prescriptionId,
            medicalRecordId,
            itemsPayload,
            _noteController.text.trim(),
          );
        }
      }

      // 4. Hoàn tất ca khám
      final success = await controller.completeVisit(visitId);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã hoàn tất ca khám và kê đơn thành công!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Quay lại trang chủ bác sĩ
        }
      } else {
        throw Exception('Không thể chuyển trạng thái hoàn tất ca khám.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi trong quá trình khám bệnh: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0F52BA);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Khám bệnh: ${widget.visit['patientName']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
            ),
            Text(
              'Mã số lượt khám: ${widget.visit['visitCode'] ?? "N/A"}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0F52BA)),
                  SizedBox(height: 16),
                  Text('Đang đồng bộ bệnh án và đơn thuốc lên hệ thống...', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                // Thanh chỉ số bước khám
                _buildStepProgress(primaryColor),
                
                // Nội dung các bước khám
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildCurrentStepContent(primaryColor),
                  ),
                ),
                
                // Thanh nút điều hướng chân trang
                _buildNavigationButtons(primaryColor),
              ],
            ),
    );
  }

  // Progress Bar
  Widget _buildStepProgress(Color primaryColor) {
    final steps = ['Bệnh án & Sinh hiệu', 'Kê đơn thuốc', 'Xác nhận'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isCurrent = _currentStep == index;
          final isDone = _currentStep > index;
          return Expanded(
            child: Row(
              children: [
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isCurrent
                      ? primaryColor
                      : isDone
                          ? const Color(0xFF10B981)
                          : Colors.grey.shade200,
                  child: isDone
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : Text(
                          (index + 1).toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? Colors.white : Colors.grey.shade500,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? primaryColor : Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (index < steps.length - 1)
                  Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade300),
              ],
            ),
          );
        }),
      ),
    );
  }

  // Phân luồng giao diện từng bước
  Widget _buildCurrentStepContent(Color primaryColor) {
    switch (_currentStep) {
      case 0:
        return _buildStep1(primaryColor);
      case 1:
        return _buildStep2(primaryColor);
      case 2:
        return _buildStep3(primaryColor);
      default:
        return Container();
    }
  }

  // --- BƯỚC 1: SINH HIỆU & CHẨN ĐOÁN ---
  Widget _buildStep1(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('1. Chỉ số sinh tồn (Vitals)'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      controller: _bpController,
                      label: 'Huyết áp (mmHg)',
                      hint: '120/80',
                      icon: Icons.speed_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(
                      controller: _tempController,
                      label: 'Nhiệt độ (°C)',
                      hint: '36.5',
                      icon: Icons.thermostat_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      controller: _hrController,
                      label: 'Nhịp tim (lần/phút)',
                      hint: '80',
                      icon: Icons.favorite_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(
                      controller: _spo2Controller,
                      label: 'Chỉ số SpO2 (%)',
                      hint: '98',
                      icon: Icons.bloodtype_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _buildSectionTitle('2. Chẩn đoán lâm sàng'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              _buildInputField(
                controller: _symptomsController,
                label: 'Triệu chứng lâm sàng *',
                hint: 'Mô tả chi tiết các triệu chứng của bệnh nhân...',
                icon: Icons.sick_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              _buildInputField(
                controller: _diagnosisController,
                label: 'Chẩn đoán bệnh chính *',
                hint: 'Ví dụ: Tăng huyết áp vô căn, Cảm cúm...',
                icon: Icons.assignment_turned_in_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              _buildInputField(
                controller: _planController,
                label: 'Phác đồ / Kế hoạch điều trị',
                hint: 'Nghỉ ngơi tĩnh dưỡng, uống thuốc theo đơn...',
                icon: Icons.analytics_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              _buildInputField(
                controller: _noteController,
                label: 'Lời dặn bác sĩ',
                hint: 'Hạn chế ăn mặn, uống nhiều nước...',
                icon: Icons.comment_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              // Ngày tái khám
              InkWell(
                onTap: () => _selectFollowUpDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: primaryColor, size: 16),
                      const SizedBox(width: 10),
                      Text(
                        _followUpDate == null
                            ? 'Chọn ngày hẹn tái khám'
                            : 'Tái khám: ${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _followUpDate == null ? FontWeight.normal : FontWeight.bold,
                          color: _followUpDate == null ? Colors.grey.shade600 : const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- BƯỚC 2: KÊ ĐƠN THUỐC ---
  Widget _buildStep2(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Danh sách thuốc đã kê'),
            ElevatedButton.icon(
              onPressed: () => _showAddMedicineDialog(primaryColor),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Thêm thuốc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_prescribedMedicines.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                Icon(Icons.medication_liquid_rounded, color: Colors.grey.shade300, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Chưa kê đơn thuốc.\nNhấn "Thêm thuốc" để chọn từ kho bệnh viện.',
                  style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _prescribedMedicines.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _prescribedMedicines[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Số lượng: ${item['quantity']} ${item['unit'] ?? "viên"} (Dùng trong ${item['durationDays']} ngày)',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Liều dùng: ${item['dosage']} | Tần suất: ${item['frequency']}',
                            style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold),
                          ),
                          if (item['note'] != null && item['note'].toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Ghi chú: ${item['note']}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          _prescribedMedicines.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // --- BƯỚC 3: XÁC NHẬN ---
  Widget _buildStep3(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Tóm tắt thông tin khám bệnh'),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông tin bệnh nhân
              _buildSummaryHeaderRow(Icons.person_outline_rounded, 'BỆNH NHÂN', widget.visit['patientName'] ?? 'N/A', primaryColor),
              const Divider(height: 24),

              // Vitals
              if (_bpController.text.isNotEmpty || _tempController.text.isNotEmpty || _hrController.text.isNotEmpty) ...[
                const Text('CHỈ SỐ SINH HIỆU', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_bpController.text.isNotEmpty) _buildSummaryMiniCard('Huyết áp', _bpController.text, 'mmHg'),
                    if (_tempController.text.isNotEmpty) _buildSummaryMiniCard('Nhiệt độ', _tempController.text, '°C'),
                    if (_hrController.text.isNotEmpty) _buildSummaryMiniCard('Nhịp tim', _hrController.text, 'l/p'),
                  ],
                ),
                const Divider(height: 24),
              ],

              // Bệnh án
              _buildSummaryField('Triệu chứng', _symptomsController.text),
              const SizedBox(height: 12),
              _buildSummaryField('Chẩn đoán chính', _diagnosisController.text),
              if (_planController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildSummaryField('Phác đồ điều trị', _planController.text),
              ],
              if (_noteController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildSummaryField('Lời dặn', _noteController.text),
              ],
              if (_followUpDate != null) ...[
                const SizedBox(height: 12),
                _buildSummaryField('Hẹn tái khám', '${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year}'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_prescribedMedicines.isNotEmpty) ...[
          _buildSectionTitle('Đơn thuốc kèm theo'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('THUỐC ĐÃ KÊ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const Divider(height: 20),
                ...List.generate(_prescribedMedicines.length, (index) {
                  final item = _prescribedMedicines[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: primaryColor.withOpacity(0.08),
                          child: Text((index + 1).toString(), style: TextStyle(fontSize: 9, color: primaryColor, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                              const SizedBox(height: 2),
                              Text(
                                '${item['quantity']} ${item['unit']} - ${item['dosage']} (${item['frequency']})',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- HỘP THOẠI THÊM THUỐC ---
  void _showAddMedicineDialog(Color primaryColor) {
    final doctorController = context.read<DoctorDashboardController>();
    
    // Tạo danh sách lọc thuốc cục bộ
    List<dynamic> filteredMedicines = List.from(doctorController.medicines);
    String searchKeyword = '';
    
    // Các trường lưu thông tin kê thuốc
    Map<String, dynamic>? selectedMed;
    final qtyController = TextEditingController(text: '10');
    final durationController = TextEditingController(text: '5');
    final dosageController = TextEditingController(text: 'Sáng 1 viên, Tối 1 viên');
    final freqController = TextEditingController(text: '2 lần/ngày');
    final instructionController = TextEditingController(text: 'Uống sau khi ăn no');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thanh ngang kéo đóng
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Kê thêm thuốc từ kho', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),

                  // 1. Ô tìm kiếm thuốc
                  TextField(
                    onChanged: (value) {
                      setModalState(() {
                        searchKeyword = value.trim().toLowerCase();
                        filteredMedicines = doctorController.medicines.where((med) {
                          final name = (med['name'] ?? med['medicineName'] ?? '').toString().toLowerCase();
                          final ingredient = (med['activeIngredient'] ?? '').toString().toLowerCase();
                          return name.contains(searchKeyword) || ingredient.contains(searchKeyword);
                        }).toList();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Nhập tên thuốc hoặc hoạt chất cần tìm...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Nội dung chính: Chọn thuốc hoặc Điền thông tin kê
                  Expanded(
                    child: selectedMed == null
                        ? (doctorController.isMedicinesLoading
                            ? const Center(child: CircularProgressIndicator())
                            : filteredMedicines.isEmpty
                                ? const Center(child: Text('Không tìm thấy thuốc nào trong kho.', style: TextStyle(color: Colors.grey)))
                                : ListView.separated(
                                    itemCount: filteredMedicines.length,
                                    separatorBuilder: (context, index) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final med = filteredMedicines[index];
                                      final name = med['name'] ?? med['medicineName'] ?? 'Không tên';
                                      final unit = med['unit'] ?? 'Viên';
                                      final stock = med['quantity'] ?? med['stock'] ?? 0;
                                      final active = med['activeIngredient'] ?? '';

                                      return ListTile(
                                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        subtitle: Text('$active · Kho: $stock $unit', style: const TextStyle(fontSize: 12)),
                                        trailing: Icon(Icons.add_circle_outline, color: primaryColor),
                                        onTap: () {
                                          setModalState(() {
                                            selectedMed = med;
                                          });
                                        },
                                      );
                                    },
                                  ))
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thuốc đã chọn
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.medication_rounded, color: primaryColor),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              selectedMed!['name'] ?? selectedMed!['medicineName'] ?? '',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            Text(
                                              'Kho hiện tại: ${selectedMed!['quantity'] ?? selectedMed!['stock'] ?? 0} ${selectedMed!['unit'] ?? "Viên"}',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setModalState(() {
                                            selectedMed = null;
                                          });
                                        },
                                        child: const Text('Chọn lại', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Nhập số lượng và số ngày
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInputField(
                                        controller: qtyController,
                                        label: 'Tổng số lượng',
                                        hint: '10',
                                        icon: Icons.shopping_basket_outlined,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildInputField(
                                        controller: durationController,
                                        label: 'Số ngày dùng',
                                        hint: '5',
                                        icon: Icons.today_rounded,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Liều dùng & tần suất
                                _buildInputField(
                                  controller: dosageController,
                                  label: 'Liều lượng mỗi lần',
                                  hint: 'Sáng 1 viên, Tối 1 viên',
                                  icon: Icons.medical_information_outlined,
                                ),
                                const SizedBox(height: 12),
                                _buildInputField(
                                  controller: freqController,
                                  label: 'Tần suất dùng',
                                  hint: '2 lần/ngày',
                                  icon: Icons.repeat_rounded,
                                ),
                                const SizedBox(height: 12),
                                _buildInputField(
                                  controller: instructionController,
                                  label: 'Cách dùng / Ghi chú bổ sung',
                                  hint: 'Uống sau khi ăn no',
                                  icon: Icons.description_outlined,
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Nút chốt thêm thuốc
                  if (selectedMed != null)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final name = selectedMed!['name'] ?? selectedMed!['medicineName'] ?? '';
                          final id = selectedMed!['medicineId'] ?? selectedMed!['id'] ?? 0;
                          final unit = selectedMed!['unit'] ?? 'Viên';
                          
                          setState(() {
                            _prescribedMedicines.add({
                              'medicineId': id,
                              'name': name,
                              'unit': unit,
                              'quantity': int.tryParse(qtyController.text) ?? 10,
                              'durationDays': int.tryParse(durationController.text) ?? 5,
                              'dosage': dosageController.text,
                              'frequency': freqController.text,
                              'note': instructionController.text,
                            });
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Thêm vào đơn thuốc', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- TRỢ GIÚP BUILD UI ---
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.normal),
            prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade400),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.all(12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0F52BA), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeaderRow(IconData icon, String label, String value, Color primaryColor) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 18),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildSummaryField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          value.isNotEmpty ? value : 'Không ghi chú',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }

  Widget _buildSummaryMiniCard(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 2),
          Text('$value $unit', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  // Nút điều hướng chân trang
  Widget _buildNavigationButtons(Color primaryColor) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Text('Quay lại', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _currentStep < 2
                  ? () {
                      if (_currentStep == 0 && _diagnosisController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng nhập chẩn đoán trước khi tiếp tục!'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      setState(() {
                        _currentStep++;
                      });
                    }
                  : _handleSubmitExamine,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                _currentStep < 2 ? 'Tiếp tục' : 'Hoàn tất & Lưu bệnh án',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
