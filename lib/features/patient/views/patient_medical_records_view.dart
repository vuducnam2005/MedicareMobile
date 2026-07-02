import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dashboard/controllers/patient_dashboard_controller.dart';

class PatientMedicalRecordsView extends StatelessWidget {
  const PatientMedicalRecordsView({super.key});

  // Định dạng ngày từ YYYY-MM-DD sang DD/MM/YYYY
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '---';
    try {
      if (dateStr.contains('/')) return dateStr;
      // Cắt bỏ phần giờ nếu có
      final cleanDate = dateStr.split('T')[0];
      final date = DateTime.parse(cleanDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardController = context.watch<PatientDashboardController>();
    final primaryColor = const Color(0xFF0F52BA);

    final List<dynamic> records = dashboardController.medicalRecords;

    // Tính toán 4 chỉ số thống kê từ dữ liệu thật giống Web
    final int total = records.length;
    final int completed = records.where((r) {
      final s = r['status']?.toString().toLowerCase() ?? '';
      return s.contains('complete') || s.contains('hoàn tất');
    }).length;
    final int drafts = records.where((r) {
      final s = r['status']?.toString().toLowerCase() ?? '';
      return s.contains('draft') || s.contains('nháp');
    }).length;
    final int followUps = records.where((r) => r['followUpDate'] != null && r['followUpDate'].toString().isNotEmpty).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Màu nền xám nhạt cao cấp
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
                      'Hồ sơ bệnh án',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Theo dõi chẩn đoán, lịch tái khám và trạng thái lưu bệnh án.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. 4 THẺ THỐNG KÊ (Giống 100% bản Web nhưng xếp dạng Grid 2x2 trên Mobile)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _buildStatCard('Tổng số hồ sơ', '$total', Icons.assignment_outlined, Colors.blue),
                    _buildStatCard('Đã hoàn tất', '$completed', Icons.check_circle_outline, Colors.green),
                    _buildStatCard('Bản nháp', '$drafts', Icons.edit_document, Colors.orange),
                    _buildStatCard('Có lịch tái khám', '$followUps', Icons.calendar_month_outlined, Colors.purple),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. TIÊU ĐỀ DANH SÁCH BỆNH ÁN
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
                      'DANH SÁCH BỆNH ÁN CHI TIẾT',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 4. DANH SÁCH BỆNH ÁN DẠNG CARD MỞ RỘNG (EXPANDABLE)
                if (records.isEmpty)
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
                        Icon(Icons.folder_open, color: Colors.grey.shade300, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có dữ liệu bệnh án nào.',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: records.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return _ExpandableMedicalRecordCard(record: record, primaryColor: primaryColor, formatDate: _formatDate);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }
}

// Widget Thẻ Bệnh Án có thể nhấn mở rộng chi tiết cực kỳ mượt mà
class _ExpandableMedicalRecordCard extends StatefulWidget {
  final dynamic record;
  final Color primaryColor;
  final String Function(String?) formatDate;

  const _ExpandableMedicalRecordCard({
    required this.record,
    required this.primaryColor,
    required this.formatDate,
  });

  @override
  State<_ExpandableMedicalRecordCard> createState() => _ExpandableMedicalRecordCardState();
}

class _ExpandableMedicalRecordCardState extends State<_ExpandableMedicalRecordCard> {

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final primaryColor = widget.primaryColor;

    final String recordCode = record['medicalRecordCode'] ?? record['recordCode'] ?? 'BA---';
    final String diagnosis = record['diagnosisText'] ?? record['diagnosis'] ?? 'Không có chẩn đoán';
    final String icdCode = record['icdCode'] ?? '';
    final String icdName = record['icdName'] ?? '';
    final String date = widget.formatDate(record['createdAt'] ?? record['date']);
    final String followUp = widget.formatDate(record['followUpDate']);
    final String status = record['status'] ?? 'Draft';
    final String doctor = record['doctorName'] ?? 'Bác sĩ chưa cập nhật';
    final String note = record['doctorNote'] ?? 'Không có lời dặn';
    final String treatment = record['treatmentPlan'] ?? 'Không có hướng dẫn điều trị';

    final bool hasFollowUp = record['followUpDate'] != null && record['followUpDate'].toString().isNotEmpty;

    // Màu sắc trạng thái giống bản Web
    Color statusColor = Colors.grey;
    String statusLabel = status;
    if (status.toLowerCase().contains('complete') || status.toLowerCase().contains('hoàn')) {
      statusColor = Colors.green;
      statusLabel = 'Đã hoàn tất';
    } else if (status.toLowerCase().contains('draft') || status.toLowerCase().contains('nháp')) {
      statusColor = Colors.orange;
      statusLabel = 'Bản nháp';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            child: Icon(Icons.assignment_outlined, color: primaryColor, size: 22),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                recordCode,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
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
                  diagnosis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
                ),
                if (icdCode.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'ICD: $icdCode - $icdName',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      'Ngày tạo: $date',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    if (hasFollowUp) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.event_repeat, size: 12, color: Colors.purple.shade300),
                      const SizedBox(width: 4),
                      Text(
                        'Tái khám: $followUp',
                        style: TextStyle(fontSize: 11, color: Colors.purple.shade400, fontWeight: FontWeight.bold),
                      ),
                    ],
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
                  _buildDetailRow('Bác sĩ điều trị', doctor, Icons.person_outline, Colors.blue),
                  const SizedBox(height: 12),
                  _buildDetailRow('Kế hoạch điều trị', treatment, Icons.healing_outlined, Colors.teal),
                  const SizedBox(height: 12),
                  _buildDetailRow('Lời dặn bác sĩ', note, Icons.comment_outlined, Colors.orange),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155), height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
