class InvoiceModel {
  final int id;
  final int patientId;
  final int? appointmentId;
  final int? prescriptionId;
  final double examinationFee;
  final double medicineTotal;
  final double totalAmount;
  final String status;
  final String createdAt;
  final String? paidAt;

  InvoiceModel({
    required this.id,
    required this.patientId,
    this.appointmentId,
    this.prescriptionId,
    required this.examinationFee,
    required this.medicineTotal,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.paidAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['invoiceId'] ?? json['id'] ?? 0,
      patientId: json['patientId'] ?? 0,
      appointmentId: json['appointmentId'],
      prescriptionId: json['prescriptionId'],
      examinationFee: (json['examinationFee'] as num?)?.toDouble() ?? 0.0,
      medicineTotal: (json['medicineTotal'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Unpaid',
      createdAt: json['createdAt'] ?? '',
      paidAt: json['paidAt'],
    );
  }
}
