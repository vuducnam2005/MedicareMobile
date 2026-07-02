import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dashboard/controllers/patient_dashboard_controller.dart';
import '../models/invoice_model.dart';
import '../../../core/config/env_config.dart';

class PatientBillingView extends StatelessWidget {
  const PatientBillingView({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardController = context.watch<PatientDashboardController>();
    final primaryColor = const Color(0xFF0F52BA);

    final invoices = dashboardController.invoices;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => dashboardController.loadDashboardData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Viện phí & Thanh toán',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Xem danh sách hóa đơn và thực hiện thanh toán trực tuyến.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Thẻ tổng hợp tiền chưa thanh toán
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F52BA), Color(0xFF0B4296)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F52BA).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TỔNG TIỀN CHƯA THANH TOÁN',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${dashboardController.unpaidAmount.toStringAsFixed(0)}đ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Có ${dashboardController.unpaidInvoicesCount} hóa đơn chờ thanh toán',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Danh sách hóa đơn',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 16),

                if (invoices.isEmpty)
                  Container(
                    height: 200,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Text('Chưa có hóa đơn nào', style: TextStyle(color: Colors.grey)),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: invoices.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final invoice = invoices[index];
                      return _buildInvoiceCard(context, invoice, primaryColor);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, InvoiceModel invoice, Color primaryColor) {
    final isUnpaid = invoice.status.toLowerCase() == 'unpaid';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hóa đơn #HD-${invoice.id.toString().padLeft(3, '0')}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isUnpaid ? Colors.orange : Colors.green).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isUnpaid ? 'Chưa thanh toán' : 'Đã thanh toán',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isUnpaid ? Colors.orange : Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Phí khám lâm sàng:', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              Text('${invoice.examinationFee.toStringAsFixed(0)}đ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tiền thuốc kê đơn:', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              Text('${invoice.medicineTotal.toStringAsFixed(0)}đ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng cộng:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text(
                '${invoice.totalAmount.toStringAsFixed(0)}đ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
              ),
            ],
          ),
          if (isUnpaid) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showPaymentQRCodeDialog(context, invoice);
                },
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text('Thanh toán quét mã QR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPaymentQRCodeDialog(BuildContext context, InvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Thanh toán chuyển khoản',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sử dụng App ngân hàng của bạn quét mã VietQR dưới đây để thanh toán tự động:',
                  style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Mã QR thanh toán VietQR giả lập (đổ ảnh mẫu)
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  alignment: Alignment.center,
                  child: Image.network(
                    'https://qr.sepay.vn/img?bank=${EnvConfig.bankTransferBank}&acc=${EnvConfig.bankTransferAccount}&template=compact&amount=${invoice.totalAmount.round()}&des=${EnvConfig.bankTransferPrefix}${invoice.id}',
                    width: 185,
                    height: 185,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.qr_code, size: 80, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Số tiền: ${invoice.totalAmount.toStringAsFixed(0)}đ',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nội dung: ${EnvConfig.bankTransferPrefix}${invoice.id}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                const SizedBox(height: 20),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.security, size: 16, color: Colors.green),
                    SizedBox(width: 6),
                    Text(
                      'Thanh toán an toàn bảo mật qua VietQR',
                      style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
