import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dashboard/controllers/patient_dashboard_controller.dart';

class PatientPrescriptionsView extends StatelessWidget {
  const PatientPrescriptionsView({super.key});

  // Định dạng ngày giờ từ YYYY-MM-DD HH:mm:ss sang DD/MM/YYYY HH:mm
  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '---';
    try {
      // Cắt bỏ phần giây nếu có
      final parts = dateStr.split('T');
      final datePart = parts[0];
      final timePart = parts.length > 1 ? parts[1].split('.')[0] : '';
      
      final date = DateTime.parse(datePart);
      final formattedDate = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      
      if (timePart.isNotEmpty) {
        final timeParts = timePart.split(':');
        return '$formattedDate ${timeParts[0]}:${timeParts[1]}';
      }
      return formattedDate;
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardController = context.watch<PatientDashboardController>();
    final primaryColor = const Color(0xFF0F52BA);

    final List<dynamic> prescriptions = dashboardController.prescriptions;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Nền xám nhạt cao cấp
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => dashboardController.loadDashboardData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TIÊU ĐỀ TRANG
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đơn thuốc của tôi',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Theo dõi thuốc đã kê, ngày kê đơn và trạng thái xử lý.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. TIÊU ĐỀ DANH SÁCH
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 14,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'DANH SÁCH ĐƠN THUỐC',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 3. DANH SÁCH ĐƠN THUỐC THẬT
                if (prescriptions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.medical_services_outlined, color: Colors.grey.shade300, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có đơn thuốc nào được kê.',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: prescriptions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final prescription = prescriptions[index];
                      return _ExpandablePrescriptionCard(
                        prescription: prescription,
                        primaryColor: primaryColor,
                        formatDateTime: _formatDateTime,
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget Thẻ đơn thuốc có thể mở rộng (Expandable) cực kỳ đẹp mắt
class _ExpandablePrescriptionCard extends StatelessWidget {
  final dynamic prescription;
  final Color primaryColor;
  final String Function(String?) formatDateTime;

  const _ExpandablePrescriptionCard({
    required this.prescription,
    required this.primaryColor,
    required this.formatDateTime,
  });

  @override
  Widget build(BuildContext context) {
    final String code = prescription['prescriptionCode'] ?? prescription['code'] ?? 'DT---';
    final String date = formatDateTime(prescription['createdAt'] ?? prescription['date']);
    final String doctor = prescription['doctorName'] ?? 'Bác sĩ chưa cập nhật';
    final String diagnosis = prescription['diagnosis'] ?? 'Không có chẩn đoán';
    final String status = prescription['status'] ?? 'Ready';
    final List<dynamic> items = prescription['items'] ?? [];

    // Trạng thái đơn thuốc giống bản Web
    Color statusColor = Colors.grey;
    String statusLabel = status;
    if (status.toLowerCase().contains('dispensed') || status.toLowerCase().contains('phát')) {
      statusColor = Colors.green;
      statusLabel = 'Đã phát thuốc';
    } else if (status.toLowerCase().contains('ready') || status.toLowerCase().contains('sẵn')) {
      statusColor = Colors.blue;
      statusLabel = 'Sẵn sàng phát thuốc';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.healing_outlined, color: primaryColor, size: 22),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                code,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chẩn đoán: $diagnosis',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bác sĩ kê đơn: $doctor',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 8),
                
                // Vẽ các Chip thuốc màu xanh dương nằm ngang giống hệt Web!
                if (items.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: items.map((item) {
                      final String medName = item['medicineName'] ?? 'Thuốc';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF3FF), // Màu nền xanh da trời nhạt giống Web
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFC7D2FE).withOpacity(0.5)),
                        ),
                        child: Text(
                          medName,
                          style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      'Ngày kê: $date',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(height: 1),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HƯỚNG DẪN SỬ DỤNG CHI TIẾT:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.0),
                      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final String medName = item['medicineName'] ?? 'Thuốc';
                      final int qty = item['quantity'] ?? 0;
                      final String dosage = item['dosage'] ?? 'Uống theo hướng dẫn';

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      medName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                    ),
                                    Text(
                                      'SL: $qty viên/gói',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Cách dùng: $dosage',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
