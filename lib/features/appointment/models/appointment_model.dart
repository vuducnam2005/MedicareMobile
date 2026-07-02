class AppointmentModel {
  final int id;
  final int patientId;
  final String patientNameSnapshot;
  final String patientPhoneSnapshot;
  final int doctorId;
  final String? doctorName;
  final String? specialtyName;
  final String appointmentDate;
  final String slotTime;
  final String reason;
  final String status;
  final int? queueNumber;
  final String? cancelReason;
  final String createdAt;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.patientNameSnapshot,
    required this.patientPhoneSnapshot,
    required this.doctorId,
    this.doctorName,
    this.specialtyName,
    required this.appointmentDate,
    required this.slotTime,
    required this.reason,
    required this.status,
    this.queueNumber,
    this.cancelReason,
    required this.createdAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] ?? json['appointmentId'] ?? 0,
      patientId: json['patientId'] ?? 0,
      patientNameSnapshot: json['patientNameSnapshot'] ?? '',
      patientPhoneSnapshot: json['patientPhoneSnapshot'] ?? '',
      doctorId: json['doctorId'] ?? 0,
      doctorName: json['doctorName'],
      specialtyName: json['specialtyName'],
      appointmentDate: json['appointmentDate'] ?? '',
      slotTime: json['slotTime'] ?? '',
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'Pending',
      queueNumber: json['queueNumber'],
      cancelReason: json['cancelReason'],
      createdAt: json['createdAt'] ?? '',
    );
  }
}
