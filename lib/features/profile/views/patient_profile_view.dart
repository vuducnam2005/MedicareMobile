import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../dashboard/controllers/patient_dashboard_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import 'patient_edit_profile_view.dart';
import '../../../core/widgets/medicare_toast.dart';

class PatientProfileView extends StatelessWidget {
  const PatientProfileView({super.key});

  // Hàm tính tuổi
  int _calculateAge(String? dobStr) {
    if (dobStr == null || dobStr.isEmpty) return 0;
    try {
      final dob = DateTime.parse(dobStr);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }

  // Định dạng ngày
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Chưa cập nhật';
    try {
      if (dateStr.contains('/')) return dateStr;
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardController = context.watch<PatientDashboardController>();
    final authController = context.watch<AuthController>();

    final patient = dashboardController.patient;
    final user = authController.currentUser;

    final String fullName = patient?.fullName ?? user?.fullName ?? 'Chưa cập nhật';
    final String email = patient?.email ?? user?.email ?? 'Chưa cập nhật';
    final String phone = patient?.phoneNumber ?? user?.phoneNumber ?? 'Chưa cập nhật';
    final String username = user?.username ?? 'Chưa cập nhật';
    final String patientCode = patient?.patientCode ?? 'BN---';
    
    final String address = patient?.address ?? 'Chưa cập nhật';
    final String dob = patient?.dateOfBirth ?? 'Chưa cập nhật';
    final String gender = patient?.gender ?? 'Chưa cập nhật';
    final String bloodType = patient?.bloodType ?? 'Chưa cập nhật';
    final String citizenId = patient?.citizenId ?? 'Chưa cập nhật';
    final String allergy = (patient?.allergyNote == null || patient!.allergyNote!.isEmpty) ? 'Không có' : patient.allergyNote!;
    final String history = (patient?.medicalHistory == null || patient!.medicalHistory!.isEmpty) ? 'Không có' : patient.medicalHistory!;
    final String status = patient?.status ?? 'Active';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Màu nền xám nhạt cao cấp
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP HEADER CARD (Thay thế SliverAppBar bằng Container Gradient bo góc tròn trịa)
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 32, bottom: 48),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF08264C), Color(0xFF1E3A8A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Avatar hình tròn có viền trắng đổ bóng cực đẹp
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(
                              fullName.isNotEmpty ? fullName[0].toUpperCase() : 'P',
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Tên & Mã bệnh nhân
                        Text(
                          fullName,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.25)),
                          ),
                          child: Text(
                            patientCode,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Nút chỉnh sửa hồ sơ ở góc trên bên phải của Thẻ
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton(
                      icon: const Icon(Icons.edit_note, color: Colors.white, size: 28),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PatientEditProfileView()),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // 2. PHẦN CHỈ SỐ SỨC KHỎE NHANH (Trôi trên Header)
              Transform.translate(
                offset: const Offset(0, -25),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickMetric('Tuổi', '${_calculateAge(dob)} tuổi', Icons.calendar_today, Colors.blue),
                        _buildVerticalDivider(),
                        _buildQuickMetric('Nhóm máu', bloodType, Icons.bloodtype, Colors.red),
                        _buildVerticalDivider(),
                        _buildQuickMetric('Giới tính', gender, Icons.transgender, Colors.purple),
                        _buildVerticalDivider(),
                        _buildQuickMetric('Trạng thái', status == 'Active' ? 'Đang hoạt động' : status, Icons.check_circle, Colors.green),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. DANH SÁCH THÔNG TIN CHI TIẾT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nhóm 1: Thông tin liên hệ
                    _buildSectionHeader('THÔNG TIN TÀI KHOẢN'),
                    const SizedBox(height: 8),
                    _buildInfoCard([
                      _buildInfoTile(context, Icons.person_outline, 'Họ và tên', fullName, Colors.blue),
                      _buildInfoTile(context, Icons.alternate_email, 'Tên đăng nhập', '@$username', Colors.orange, showCopy: true, copyValue: username),
                      _buildInfoTile(context, Icons.phone_outlined, 'Số điện thoại', phone, Colors.green, showCopy: true, copyValue: phone),
                      _buildInfoTile(context, Icons.email_outlined, 'Email liên hệ', email, Colors.red),
                      _buildInfoTile(context, Icons.badge_outlined, 'Số CCCD / Định danh', citizenId, Colors.indigo, showCopy: true, copyValue: citizenId),
                      _buildInfoTile(context, Icons.location_on_outlined, 'Địa chỉ thường trú', address, Colors.amber),
                    ]),
                    const SizedBox(height: 24),

                    // Nhóm 2: Thông tin y tế chuyên sâu
                    _buildSectionHeader('THÔNG TIN Y TẾ'),
                    const SizedBox(height: 8),
                    _buildInfoCard([
                      _buildInfoTile(context, Icons.cake_outlined, 'Ngày sinh', _formatDate(dob), Colors.pink),
                      _buildInfoTile(context, Icons.warning_amber_rounded, 'Ghi chú dị ứng', allergy, Colors.deepOrange, 
                          isWarning: allergy != 'Không có' && allergy != 'Không có thông tin'),
                      _buildInfoTile(context, Icons.history_edu_outlined, 'Tiền sử bệnh án', history, Colors.teal),
                    ]),
                    const SizedBox(height: 24),

                    // Nhóm 3: Bảo mật & Tùy chọn khác
                    _buildSectionHeader('BẢO MẬT & CÀI ĐẶT'),
                    const SizedBox(height: 8),
                    _buildInfoCard([
                      _buildActionTile(
                        icon: Icons.lock_open_outlined,
                        title: 'Đổi mật khẩu tài khoản',
                        color: Colors.blueGrey,
                        onTap: () async {
                          final success = await showDialog<bool>(
                            context: context,
                            builder: (context) => const ChangePasswordDialog(),
                          );
                          if (success == true && context.mounted) {
                            MedicareToast.show(
                              context,
                              message: 'Đổi mật khẩu thành công!',
                              type: MedicareToastType.success,
                            );
                          }
                        },
                      ),
                      _buildActionTile(
                        icon: Icons.logout,
                        title: 'Đăng xuất tài khoản',
                        color: Colors.redAccent,
                        onTap: () {
                          context.read<AuthController>().logout();
                        },
                      ),
                    ]),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF0F52BA),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Color(0xFF64748B),
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildQuickMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 36,
      width: 1,
      color: Colors.grey.shade100,
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color iconColor, {
    bool showCopy = false,
    String? copyValue,
    bool isWarning = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          title: Text(
            label,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              value,
              style: TextStyle(
                color: isWarning ? Colors.red : const Color(0xFF1E293B),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          trailing: showCopy
              ? IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: copyValue ?? value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép vào bộ nhớ tạm'), duration: Duration(seconds: 1)),
                    );
                  },
                )
              : null,
        ),
        // Đường kẻ phân cách (trừ phần tử cuối)
        Padding(
          padding: const EdgeInsets.only(left: 64.0),
          child: Divider(height: 1, color: Colors.grey.shade100),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          title: Text(
            title,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          trailing: Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
          onTap: onTap,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 64.0),
          child: Divider(height: 1, color: Colors.grey.shade100),
        ),
      ],
    );
  }
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Mật khẩu xác nhận không trùng khớp.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final authController = context.read<AuthController>();
    final success = await authController.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      if (success) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = authController.errorMessage ?? 'Mật khẩu hiện tại không chính xác.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0F52BA);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Đổi Mật Khẩu',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cập nhật mật khẩu tài khoản để đảm bảo an toàn thông tin của bạn.',
                  style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Mật khẩu hiện tại
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: !_isCurrentPasswordVisible,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu hiện tại',
                    prefixIcon: const Icon(Icons.lock_outline, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isCurrentPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _isCurrentPasswordVisible = !_isCurrentPasswordVisible),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập mật khẩu hiện tại' : null,
                ),
                const SizedBox(height: 16),
                // Mật khẩu mới
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: !_isNewPasswordVisible,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới',
                    prefixIcon: const Icon(Icons.lock_reset_outlined, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isNewPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập mật khẩu mới';
                    if (value.trim().length < 6) return 'Mật khẩu mới phải từ 6 ký tự trở lên';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Xác nhận mật khẩu mới
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Nhập lại mật khẩu mới',
                    prefixIcon: const Icon(Icons.lock_clock_outlined, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng xác nhận mật khẩu mới' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Cập nhật mật khẩu',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
