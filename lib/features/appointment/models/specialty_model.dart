class SpecialtyModel {
  final int specialtyId;
  final String specialtyName;

  SpecialtyModel({
    required this.specialtyId,
    required this.specialtyName,
  });

  factory SpecialtyModel.fromJson(Map<String, dynamic> json) {
    return SpecialtyModel(
      specialtyId: json['specialtyId'] ?? json['id'] ?? 0,
      specialtyName: json['specialtyName'] ?? json['name'] ?? '',
    );
  }
}
