class PatientModel {
  final int id;
  final String? patientCode;
  final String fullName;
  final String? dateOfBirth;
  final String? gender;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final String? citizenId;
  final String? bloodType;
  final String? allergyNote;
  final String? medicalHistory;
  final String status;

  PatientModel({
    required this.id,
    this.patientCode,
    required this.fullName,
    this.dateOfBirth,
    this.gender,
    this.phoneNumber,
    this.email,
    this.address,
    this.citizenId,
    this.bloodType,
    this.allergyNote,
    this.medicalHistory,
    required this.status,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] ?? json['patientId'] ?? 0,
      patientCode: json['patientCode'],
      fullName: json['fullName'] ?? '',
      dateOfBirth: json['dateOfBirth'],
      gender: json['gender'],
      phoneNumber: json['phoneNumber'] ?? json['phone'],
      email: json['email'],
      address: json['address'],
      citizenId: json['citizenId'],
      bloodType: json['bloodType'],
      allergyNote: json['allergyNote'],
      medicalHistory: json['medicalHistory'],
      status: json['status'] ?? 'Active',
    );
  }
}
