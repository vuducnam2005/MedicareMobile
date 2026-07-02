class NotificationModel {
  final int id;
  final int userId;
  final String role;
  final String title;
  final String content;
  final String type; // 'Appointment', 'Billing', 'Prescription', 'MedicalRecord', 'System'
  final String? referenceId;
  final String navigateUrl;
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.role,
    required this.title,
    required this.content,
    required this.type,
    this.referenceId,
    required this.navigateUrl,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? json['Id'] ?? 0,
      userId: json['userId'] ?? json['UserId'] ?? 0,
      role: json['role'] ?? json['Role'] ?? '',
      title: json['title'] ?? json['Title'] ?? '',
      content: json['content'] ?? json['Content'] ?? '',
      type: json['type'] ?? json['Type'] ?? 'System',
      referenceId: json['referenceId'] ?? json['ReferenceId'],
      navigateUrl: json['navigateUrl'] ?? json['NavigateUrl'] ?? '',
      isRead: json['isRead'] ?? json['IsRead'] ?? false,
      createdAt: json['createdAt'] ?? json['CreatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'role': role,
      'title': title,
      'content': content,
      'type': type,
      'referenceId': referenceId,
      'navigateUrl': navigateUrl,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }
}
