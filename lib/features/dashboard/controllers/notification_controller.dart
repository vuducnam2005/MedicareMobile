import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationController extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> _recipients = []; // Dành cho Admin gửi thủ công
  bool _isLoadingRecipients = false;

  Timer? _pollingTimer;
  bool _isPollingActive = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<dynamic> get recipients => _recipients;
  bool get isLoadingRecipients => _isLoadingRecipients;

  // Lấy danh sách thông báo
  Future<void> fetchNotifications({bool? isRead}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'page': 1,
        'pageSize': 30,
      };
      if (isRead != null) {
        queryParams['isRead'] = isRead;
      }

      final response = await _apiClient.dio.get(
        '/pharmacy/api/notifications',
        queryParameters: queryParams,
      );

      final data = ApiClient.readApiResponse(response.data);
      if (response.statusCode == 200 && data != null) {
        final List list = (data is List) ? data : (data['items'] ?? data['Items'] ?? []);
        _notifications = list.map((item) => NotificationModel.fromJson(item)).toList();
      }
    } catch (e) {
      _errorMessage = 'Lỗi tải thông báo: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lấy số lượng thông báo chưa đọc
  Future<void> fetchUnreadCount() async {
    try {
      final response = await _apiClient.dio.get('/pharmacy/api/notifications/unread-count');
      final data = ApiClient.readApiResponse(response.data);
      if (response.statusCode == 200 && data != null) {
        final count = data['count'] ?? data['Count'] ?? 0;
        final int newCount = (count as num).toInt();
        if (_unreadCount != newCount) {
          _unreadCount = newCount;
          notifyListeners();
        }
      }
    } catch (_) {
      // Bỏ qua lỗi khi polling âm thầm
    }
  }

  // Đánh dấu đã đọc một thông báo
  Future<void> markAsRead(int notificationId) async {
    try {
      final response = await _apiClient.dio.post('/pharmacy/api/notifications/$notificationId/read');
      if (response.statusCode == 200) {
        // Cập nhật local state
        _notifications = _notifications.map((item) {
          if (item.id == notificationId) {
            return NotificationModel(
              id: item.id,
              userId: item.userId,
              role: item.role,
              title: item.title,
              content: item.content,
              type: item.type,
              referenceId: item.referenceId,
              navigateUrl: item.navigateUrl,
              isRead: true,
              createdAt: item.createdAt,
            );
          }
          return item;
        }).toList();
        
        if (_unreadCount > 0) {
          _unreadCount--;
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  // Đánh dấu đã đọc toàn bộ thông báo
  Future<void> markAllAsRead() async {
    try {
      final response = await _apiClient.dio.post('/pharmacy/api/notifications/read-all');
      if (response.statusCode == 200) {
        _notifications = _notifications.map((item) {
          return NotificationModel(
            id: item.id,
            userId: item.userId,
            role: item.role,
            title: item.title,
            content: item.content,
            type: item.type,
            referenceId: item.referenceId,
            navigateUrl: item.navigateUrl,
            isRead: true,
            createdAt: item.createdAt,
          );
        }).toList();
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (_) {}
  }

  // Lấy danh sách người nhận (chỉ dành cho Admin)
  Future<void> fetchAdminRecipients({String search = ''}) async {
    _isLoadingRecipients = true;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        '/pharmacy/api/notifications/admin/recipients',
        queryParameters: search.isNotEmpty ? {'search': search} : null,
      );
      final data = ApiClient.readApiResponse(response.data);
      if (response.statusCode == 200 && data != null) {
        _recipients = data is List ? data : (data['items'] ?? data['Items'] ?? []);
      }
    } catch (e) {
      _errorMessage = 'Lỗi tải danh sách người nhận: $e';
    } finally {
      _isLoadingRecipients = false;
      notifyListeners();
    }
  }

  // Gửi thông báo thủ công (chỉ dành cho Admin)
  Future<bool> sendManualNotification({
    required String title,
    required String content,
    required String type,
    String? navigateUrl,
    String? referenceId,
    required String targetMode, // 'All', 'Roles', 'User'
    List<String>? roles,
    int? userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = <String, dynamic>{
        'title': title,
        'content': content,
        'type': type,
        'targetMode': targetMode,
      };
      if (navigateUrl != null && navigateUrl.isNotEmpty) {
        payload['navigateUrl'] = navigateUrl;
      }
      if (referenceId != null && referenceId.isNotEmpty) {
        payload['referenceId'] = referenceId;
      }
      if (targetMode == 'Roles' && roles != null) {
        payload['roles'] = roles;
      }
      if (targetMode == 'User' && userId != null) {
        payload['userId'] = userId;
      }

      final response = await _apiClient.dio.post(
        '/pharmacy/api/notifications/admin/send',
        data: payload,
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Gửi thông báo thất bại: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Bắt đầu Polling định kỳ cập nhật số lượng unread
  void startPolling() {
    if (_isPollingActive) return;
    _isPollingActive = true;
    
    // Gọi ngay lập tức lần đầu
    fetchUnreadCount();

    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_isPollingActive) {
        fetchUnreadCount();
      } else {
        timer.cancel();
      }
    });
  }

  // Dừng Polling
  void stopPolling() {
    _isPollingActive = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
