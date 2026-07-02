import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dashboard/controllers/patient_dashboard_controller.dart';
import '../../../core/widgets/medicare_toast.dart';

class PatientEditProfileView extends StatefulWidget {
  const PatientEditProfileView({super.key});

  @override
  State<PatientEditProfileView> createState() => _PatientEditProfileViewState();
}

class _PatientEditProfileViewState extends State<PatientEditProfileView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _citizenIdController;
  late TextEditingController _allergyController;
  late TextEditingController _historyController;

  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedBloodType;

  final List<String> _genders = ['Nam', 'Nữ', 'Khác'];
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void initState() {
    super.initState();
    final patient = context.read<PatientDashboardController>().patient;

    _fullNameController = TextEditingController(text: patient?.fullName ?? '');
    _phoneController = TextEditingController(text: patient?.phoneNumber ?? '');
    _emailController = TextEditingController(text: patient?.email ?? '');
    _addressController = TextEditingController(text: patient?.address ?? '');
    _citizenIdController = TextEditingController(text: patient?.citizenId ?? '');
    _allergyController = TextEditingController(text: patient?.allergyNote ?? '');
    _historyController = TextEditingController(text: patient?.medicalHistory ?? '');

    if (patient?.dateOfBirth != null) {
      try {
        _selectedDate = DateTime.parse(patient!.dateOfBirth!);
      } catch (_) {}
    }
    _selectedGender = patient?.gender;
    _selectedBloodType = patient?.bloodType;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _citizenIdController.dispose();
    _allergyController.dispose();
    _historyController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardController = context.watch<PatientDashboardController>();
    final primaryColor = const Color(0xFF0F52BA);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(color: Color(0xFF08264C), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF08264C)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade100, height: 1),
        ),
      ),
      body: SafeArea(
        child: dashboardController.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề phụ
                      Text(
                        'Cập nhật thông tin y tế và hành chính của bạn. Dữ liệu sẽ được đồng bộ trực tiếp lên hệ thống trung tâm.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.4),
                      ),
                      const SizedBox(height: 24),

                      // 1. THÔNG TIN HÀNH CHÍNH
                      _buildSectionTitle('Thông tin hành chính'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _fullNameController,
                        label: 'Họ và tên *',
                        hint: 'Nhập đầy đủ họ tên',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập họ và tên';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Số điện thoại',
                        hint: 'Nhập số điện thoại',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Nhập địa chỉ email',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _citizenIdController,
                        label: 'Số CCCD',
                        hint: 'Nhập số căn cước công dân',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _addressController,
                        label: 'Địa chỉ thường trú',
                        hint: 'Nhập địa chỉ của bạn',
                      ),
                      const SizedBox(height: 24),

                      // 2. THÔNG TIN SỨC KHỎE
                      _buildSectionTitle('Thông tin y tế'),
                      const SizedBox(height: 12),
                      // Chọn ngày sinh
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ngày sinh',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedDate == null
                                        ? 'Chọn ngày sinh'
                                        : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
                                    style: TextStyle(
                                      color: _selectedDate == null ? Colors.grey.shade400 : const Color(0xFF334155),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade400),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Chọn Giới tính & Nhóm máu (Song song)
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'Giới tính',
                              value: _selectedGender,
                              items: _genders,
                              onChanged: (val) => setState(() => _selectedGender = val),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Nhóm máu',
                              value: _selectedBloodType,
                              items: _bloodTypes,
                              onChanged: (val) => setState(() => _selectedBloodType = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _allergyController,
                        label: 'Ghi chú dị ứng',
                        hint: 'Nhập ghi chú dị ứng nếu có (ví dụ: dị ứng penicillin)',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _historyController,
                        label: 'Tiền sử bệnh án',
                        hint: 'Nhập tiền sử bệnh lý của bản thân/gia đình',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 32),

                      // Nút lưu thay đổi
                      if (dashboardController.errorMessage != null) ...[
                        Text(
                          dashboardController.errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => _saveProfile(context, dashboardController),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Lưu thay đổi',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.normal),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF0F52BA), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF0F52BA), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveProfile(BuildContext context, PatientDashboardController controller) async {
    if (!_formKey.currentState!.validate()) return;

    String? dobStr;
    if (_selectedDate != null) {
      dobStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    }

    final success = await controller.updatePatientProfile(
      fullName: _fullNameController.text.trim(),
      dob: dobStr,
      gender: _selectedGender,
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      citizenId: _citizenIdController.text.trim(),
      bloodType: _selectedBloodType,
      allergyNote: _allergyController.text.trim(),
      medicalHistory: _historyController.text.trim(),
    );

    if (success && mounted) {
      MedicareToast.show(
        context,
        message: 'Cập nhật hồ sơ bệnh nhân thành công!',
        type: MedicareToastType.success,
      );
      Navigator.pop(context);
    }
  }
}
