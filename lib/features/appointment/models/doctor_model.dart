class DoctorModel {
  final int doctorId;
  final String doctorName;
  final int specialtyId;
  final String specialtyName;
  final double examFee;
  final String? degree;
  final int? experienceYears;
  final String? phone;
  final String? email;
  final String? gender;
  final String? description;
  final String? roomNumber;
  final String? avatarUrl;

  DoctorModel({
    required this.doctorId,
    required this.doctorName,
    required this.specialtyId,
    required this.specialtyName,
    required this.examFee,
    this.degree,
    this.experienceYears,
    this.phone,
    this.email,
    this.gender,
    this.description,
    this.roomNumber,
    this.avatarUrl,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      doctorId: json['doctorId'] ?? json['id'] ?? 0,
      doctorName: json['doctorName'] ?? json['fullName'] ?? '',
      specialtyId: json['specialtyId'] ?? 0,
      specialtyName: json['specialtyName'] ?? '',
      examFee: (json['examFee'] ?? 0).toDouble(),
      degree: json['degree'],
      experienceYears: json['experienceYears'],
      phone: json['phone'],
      email: json['email'],
      gender: json['gender'],
      description: json['description'],
      roomNumber: json['roomNumber'],
      avatarUrl: json['avatarUrl'],
    );
  }
}
