import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/notification_controller.dart';

class AdminSendNotificationView extends StatefulWidget {
  const AdminSendNotificationView({super.key, required this.primaryColor});

  final Color primaryColor;

  @override
  State<AdminSendNotificationView> createState() => _AdminSendNotificationViewState();
}

class _AdminSendNotificationViewState extends State<AdminSendNotificationView> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _navUrlController = TextEditingController();
  final _refIdController = TextEditingController();
  final _searchUserController = TextEditingController();

  String _selectedType = 'System';
  String _targetMode = 'All'; // 'All', 'Roles', 'User'

  // Roles selection (for targetMode == 'Roles')
  final Map<String, bool> _selectedRoles = {
    'Patient': false,
    'Nurse': false,
    'Doctor': false,
    'Admin': false,
  };

  // User selection (for targetMode == 'User')
  Map<String, dynamic>? _selectedUser;
  bool _hasSearched = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _navUrlController.dispose();
    _refIdController.dispose();
    _searchUserController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _titleController.clear();
    _contentController.clear();
    _navUrlController.clear();
    _refIdController.clear();
    _searchUserController.clear();
    setState(() {
      _selectedType = 'System';
      _targetMode = 'All';
      _selectedUser = null;
      _hasSearched = false;
      _selectedRoles.updateAll((key, value) => false);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<NotificationController>();

    // Validate roles selection
    List<String>? targetRoles;
    if (_targetMode == 'Roles') {
      targetRoles = _selectedRoles.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();
      if (targetRoles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn ít nhất một vai trò.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // Validate user selection
    int? targetUserId;
    if (_targetMode == 'User') {
      if (_selectedUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn người nhận.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      targetUserId = _selectedUser!['userId'] ?? _selectedUser!['id'];
    }

    final success = await controller.sendManualNotification(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      type: _selectedType,
      navigateUrl: _navUrlController.text.trim(),
      referenceId: _refIdController.text.trim(),
      targetMode: _targetMode,
      roles: targetRoles,
      userId: targetUserId,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gửi thông báo thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage ?? 'Gửi thông báo thất bại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner giới thiệu
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.primaryColor.withOpacity(0.18)),
              ),
              child: Row(
                children: [
                  Icon(Icons.campaign_rounded, color: widget.primaryColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Soạn và Gửi Thông báo',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Soạn nội dung, chọn đối tượng nhận và gửi thông báo tức thì đến người dùng.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Form Content
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nội dung thông báo',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),

                    // Tiêu đề
                    TextFormField(
                      controller: _titleController,
                      maxLength: 150,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề thông báo *',
                        prefixIcon: Icon(Icons.title_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tiêu đề.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Loại thông báo Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Loại thông báo',
                        prefixIcon: Icon(Icons.category_rounded),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'System', child: Text('Hệ thống')),
                        DropdownMenuItem(value: 'Appointment', child: Text('Lịch khám')),
                        DropdownMenuItem(value: 'Billing', child: Text('Viện phí')),
                        DropdownMenuItem(value: 'Prescription', child: Text('Đơn thuốc')),
                        DropdownMenuItem(value: 'MedicalRecord', child: Text('Bệnh án')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Nội dung chi tiết
                    TextFormField(
                      controller: _contentController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Nội dung thông báo *',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 50),
                          child: Icon(Icons.description_rounded),
                        ),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập nội dung.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Đường dẫn & Mã tham chiếu
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _navUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Đường dẫn (URL)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _refIdController,
                            decoration: const InputDecoration(
                              labelText: 'Mã tham chiếu',
                              hintText: 'Ví dụ: HD102',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Target Selection Card
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đối tượng nhận',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    // Chọn Mode
                    Row(
                      children: [
                        _buildTargetModeRadio('All', 'Tất cả'),
                        _buildTargetModeRadio('Roles', 'Vai trò'),
                        _buildTargetModeRadio('User', 'Đích danh'),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Mode Roles checkboxes
                    if (_targetMode == 'Roles') ...[
                      const Divider(),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        children: _selectedRoles.keys.map((role) {
                          return FilterChip(
                            label: Text(_translateRole(role)),
                            selected: _selectedRoles[role]!,
                            selectedColor: widget.primaryColor.withOpacity(0.18),
                            checkmarkColor: widget.primaryColor,
                            onSelected: (selected) {
                              setState(() {
                                _selectedRoles[role] = selected;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],

                    // Mode User search and selection
                    if (_targetMode == 'User') ...[
                      const Divider(),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _searchUserController,
                              decoration: const InputDecoration(
                                labelText: 'Tìm người nhận',
                                hintText: 'Tên, email, tài khoản...',
                                border: OutlineInputBorder(),
                              ),
                              onFieldSubmitted: (_) => _searchRecipients(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.search_rounded),
                            label: const Text('Tìm'),
                            onPressed: _searchRecipients,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (controller.isLoadingRecipients)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ))
                      else if (_hasSearched && controller.recipients.isEmpty)
                        const Text('Không tìm thấy người nhận nào phù hợp.', style: TextStyle(color: Colors.orange, fontSize: 12))
                      else if (controller.recipients.isNotEmpty) ...[
                        const Text('Kết quả tìm kiếm:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 6),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: controller.recipients.length,
                            itemBuilder: (context, index) {
                              final user = controller.recipients[index];
                              final fullName = user['fullName'] ?? user['FullName'] ?? '';
                              final email = user['email'] ?? user['Email'] ?? '';
                              final role = user['role'] ?? user['Role'] ?? '';
                              final isSelected = _selectedUser != null && (_selectedUser!['userId'] ?? _selectedUser!['id']) == (user['userId'] ?? user['id']);

                              return ListTile(
                                dense: true,
                                title: Text('$fullName (${_translateRole(role)})'),
                                subtitle: Text(email),
                                selected: isSelected,
                                selectedTileColor: widget.primaryColor.withOpacity(0.08),
                                onTap: () {
                                  setState(() {
                                    _selectedUser = user;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],

                      if (_selectedUser != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Đã chọn: ${_selectedUser!['fullName'] ?? _selectedUser!['FullName'] ?? ''}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Nút điều khiển
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _resetForm,
                  child: const Text('Làm mới'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: controller.isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                  label: const Text('Gửi thông báo', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: controller.isLoading ? null : _submitForm,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetModeRadio(String value, String label) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: _targetMode,
          activeColor: widget.primaryColor,
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _targetMode = val;
              });
            }
          },
        ),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(width: 14),
      ],
    );
  }

  void _searchRecipients() {
    final keyword = _searchUserController.text.trim();
    if (keyword.isEmpty) return;
    context.read<NotificationController>().fetchAdminRecipients(search: keyword);
    setState(() {
      _hasSearched = true;
      _selectedUser = null;
    });
  }

  String _translateRole(String role) {
    final r = role.toLowerCase();
    if (r == 'patient') return 'Bệnh nhân';
    if (r == 'nurse') return 'Y tá';
    if (r == 'doctor') return 'Bác sĩ';
    if (r == 'admin') return 'Quản trị viên';
    return role;
  }
}
