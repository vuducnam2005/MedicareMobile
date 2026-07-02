class UserModel {
  final int userId;
  final String fullName;
  final String email;
  final String username;
  final String? phoneNumber;
  final int? patientId;
  final int? doctorId;
  final String? specialtyName;
  final String? avatarUrl;
  final String role;
  final String status;
  final String createdAt;
  final String? updatedAt;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.username,
    this.phoneNumber,
    this.patientId,
    this.doctorId,
    this.specialtyName,
    this.avatarUrl,
    required this.role,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Phân tích cú pháp doctorId một cách mạnh mẽ từ nhiều nguồn (phẳng hoặc lồng nhau)
    int? parsedDoctorId;
    if (json['doctorId'] != null) {
      parsedDoctorId = json['doctorId'] is int ? json['doctorId'] : int.tryParse(json['doctorId'].toString());
    } else if (json['DoctorId'] != null) {
      parsedDoctorId = json['DoctorId'] is int ? json['DoctorId'] : int.tryParse(json['DoctorId'].toString());
    } else if (json['doctor'] != null && json['doctor'] is Map) {
      final docMap = json['doctor'] as Map<String, dynamic>;
      parsedDoctorId = docMap['doctorId'] ?? docMap['id'];
    } else if (json['Doctor'] != null && json['Doctor'] is Map) {
      final docMap = json['Doctor'] as Map<String, dynamic>;
      parsedDoctorId = docMap['DoctorId'] ?? docMap['Id'];
    }

    // Phân tích cú pháp specialtyName
    String? parsedSpecialtyName;
    if (json['specialtyName'] != null) {
      parsedSpecialtyName = json['specialtyName'].toString();
    } else if (json['doctor'] != null && json['doctor'] is Map) {
      final docMap = json['doctor'] as Map<String, dynamic>;
      parsedSpecialtyName = docMap['specialtyName'] ?? (docMap['specialty'] is Map ? docMap['specialty']['specialtyName'] : null);
    } else if (json['Doctor'] != null && json['Doctor'] is Map) {
      final docMap = json['Doctor'] as Map<String, dynamic>;
      parsedSpecialtyName = docMap['SpecialtyName'] ?? (docMap['Specialty'] is Map ? docMap['Specialty']['SpecialtyName'] : null);
    }

    // Phân tích cú pháp avatarUrl
    String? parsedAvatarUrl = json['avatarUrl'] ?? json['AvatarUrl'];
    if (parsedAvatarUrl == null && json['doctor'] != null && json['doctor'] is Map) {
      final docMap = json['doctor'] as Map<String, dynamic>;
      parsedAvatarUrl = docMap['avatarUrl'] ?? docMap['AvatarUrl'];
    } else if (parsedAvatarUrl == null && json['Doctor'] != null && json['Doctor'] is Map) {
      final docMap = json['Doctor'] as Map<String, dynamic>;
      parsedAvatarUrl = docMap['avatarUrl'] ?? docMap['AvatarUrl'];
    }

    return UserModel(
      userId: json['userId'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      phoneNumber: json['phoneNumber'],
      patientId: json['patientId'],
      doctorId: parsedDoctorId,
      specialtyName: parsedSpecialtyName,
      avatarUrl: parsedAvatarUrl,
      role: json['role'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'username': username,
      'phoneNumber': phoneNumber,
      'patientId': patientId,
      'doctorId': doctorId,
      'specialtyName': specialtyName,
      'avatarUrl': avatarUrl,
      'role': role,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
