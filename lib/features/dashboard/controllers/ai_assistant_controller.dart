import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/config/env_config.dart';
import '../models/ai_chat_message.dart';

class BookingState {
  String step; // 'specialty' | 'doctor' | 'date' | 'time' | 'confirm' | 'completed'
  int? specialtyId;
  String? specialtyName;
  int? doctorId;
  String? doctorName;
  int? examFee;
  String? appointmentDate;
  String? slotTime;
  String? reason;

  BookingState({
    required this.step,
    this.specialtyId,
    this.specialtyName,
    this.doctorId,
    this.doctorName,
    this.examFee,
    this.appointmentDate,
    this.slotTime,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
        'step': step,
        'specialtyId': specialtyId,
        'specialtyName': specialtyName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'examFee': examFee,
        'appointmentDate': appointmentDate,
        'slotTime': slotTime,
        'reason': reason,
      };

  factory BookingState.fromJson(Map<String, dynamic> json) {
    return BookingState(
      step: json['step'] as String? ?? 'specialty',
      specialtyId: json['specialtyId'] as int?,
      specialtyName: json['specialtyName'] as String?,
      doctorId: json['doctorId'] as int?,
      doctorName: json['doctorName'] as String?,
      examFee: json['examFee'] as int?,
      appointmentDate: json['appointmentDate'] as String?,
      slotTime: json['slotTime'] as String?,
      reason: json['reason'] as String?,
    );
  }
}

class AiAssistantController extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final _secureStorage = const FlutterSecureStorage();

  static const String _geminiApiKey = EnvConfig.geminiApiKey;
  static const String _geminiModel = EnvConfig.geminiModel;
  static const String _historyStorageKey = 'dogky_chat_messages';
  static const String _bookingStorageKey = 'dogky_active_booking';

  List<AiChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isOpen = false;
  BookingState? _activeBooking;

  // Cache dữ liệu bác sĩ và chuyên khoa
  List<Map<String, dynamic>> _allSpecialties = [];
  List<Map<String, dynamic>> _allDoctors = [];

  // Lời nhắc chủ động (Proactive suggestions)
  List<String> _proactiveReminders = [];
  int _proactiveIndex = 0;
  String _activeSpeechBubbleText = 'Tôi có thể giúp gì cho bạn?';
  bool _isSpeechBubbleVisible = true;
  Timer? _proactiveTimer;

  // Lịch sử hội thoại gửi lên Gemini API (tối đa 20 lượt)
  final List<Map<String, dynamic>> _conversationHistory = [];

  // Getters
  List<AiChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isOpen => _isOpen;
  BookingState? get activeBooking => _activeBooking;
  String get activeSpeechBubbleText => _activeSpeechBubbleText;
  bool get isSpeechBubbleVisible => _isSpeechBubbleVisible;
  List<Map<String, dynamic>> get allSpecialties => _allSpecialties;

  AiAssistantController() {
    _init();
  }

  Future<void> _init() async {
    await loadInitialData();
    await loadChatHistory();
    _startProactiveReminderLoop();
  }

  @override
  void dispose() {
    _proactiveTimer?.cancel();
    super.dispose();
  }

  void toggleChat(bool open) {
    _isOpen = open;
    if (_isOpen) {
      _isSpeechBubbleVisible = false;
      _proactiveTimer?.cancel();
    } else {
      _startProactiveReminderLoop();
    }
    notifyListeners();
  }

  // Tải danh sách chuyên khoa & bác sĩ từ server
  Future<void> loadInitialData() async {
    try {
      final specsResponse = await _apiClient.dio.get('/appointment/api/specialties');
      final specsData = ApiClient.readApiResponse(specsResponse.data);
      if (specsResponse.statusCode == 200 && specsData != null) {
        _allSpecialties = (specsData as List).map((s) => {
              'id': s['specialtyId'] as int,
              'name': s['specialtyName'] as String? ?? '',
            }).toList();
      }

      final docsResponse = await _apiClient.dio.get('/appointment/api/doctors');
      final docsData = ApiClient.readApiResponse(docsResponse.data);
      if (docsResponse.statusCode == 200 && docsData != null) {
        _allDoctors = (docsData as List).map((d) => {
              'id': d['doctorId'] as int,
              'name': d['doctorName'] ?? d['fullName'] ?? '',
              'specialtyId': d['specialtyId'] as int,
              'specialtyName': d['specialtyName'] ?? '',
              'examFee': d['examFee'] as int? ?? 150000,
            }).toList();
      }
    } catch (e) {
      print('Warning: Failed to load initial data in chatbot controller: $e');
    }
  }

  // Khôi phục lịch sử chat từ bộ nhớ cục bộ
  Future<void> loadChatHistory() async {
    try {
      final historyStr = await _secureStorage.read(key: _historyStorageKey);
      if (historyStr != null && historyStr.isNotEmpty) {
        final List decoded = jsonDecode(historyStr);
        _messages = decoded.map((e) => AiChatMessage.fromJson(e)).toList();
        
        // Cập nhật lại lịch sử hội thoại cho Gemini
        _conversationHistory.clear();
        for (var msg in _messages) {
          final role = msg.sender == 'bot' ? 'model' : 'user';
          _conversationHistory.add({
            'role': role,
            'parts': [
              {'text': msg.text}
            ]
          });
        }
        if (_conversationHistory.length > 20) {
          _conversationHistory.removeRange(0, _conversationHistory.length - 20);
        }
      } else {
        _messages = [
          AiChatMessage(
            id: 1,
            sender: 'bot',
            text: 'Gâu! Dogky đang trực đây. Có chuyện gì cần hỗ trợ thì nói nhanh lên nhé, gâu!',
          )
        ];
      }

      final bookingStr = await _secureStorage.read(key: _bookingStorageKey);
      if (bookingStr != null && bookingStr.isNotEmpty) {
        _activeBooking = BookingState.fromJson(jsonDecode(bookingStr));
      }
    } catch (e) {
      print('Error loading chatbot history: $e');
    }
    notifyListeners();
  }

  // Lưu lịch sử chat xuống bộ nhớ cục bộ
  Future<void> saveChatHistory() async {
    try {
      final historyJsonStr = jsonEncode(_messages.map((e) => e.toJson()).toList());
      await _secureStorage.write(key: _historyStorageKey, value: historyJsonStr);

      if (_activeBooking != null) {
        await _secureStorage.write(key: _bookingStorageKey, value: jsonEncode(_activeBooking!.toJson()));
      } else {
        await _secureStorage.delete(key: _bookingStorageKey);
      }
    } catch (e) {
      print('Error saving chatbot history: $e');
    }
  }

  // Xóa lịch sử chat
  Future<void> clearChatHistory() async {
    _messages = [
      AiChatMessage(
        id: 1,
        sender: 'bot',
        text: 'Gâu! Đã xóa sạch lịch sử trò chuyện. Bắt đầu lại nhé, gâu!',
      )
    ];
    _conversationHistory.clear();
    _activeBooking = null;
    await saveChatHistory();
    notifyListeners();
  }

  int _nextMessageId() {
    if (_messages.isEmpty) return 1;
    return _messages.map((m) => m.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  // Gửi tin nhắn của người dùng đi
  Future<void> sendUserMessage(String userText) async {
    final text = userText.trim();
    if (text.isEmpty) return;

    // 1. Thêm tin nhắn của bệnh nhân
    _messages.add(AiChatMessage(
      id: _nextMessageId(),
      sender: 'user',
      text: text,
    ));
    _conversationHistory.add({
      'role': 'user',
      'parts': [
        {'text': text}
      ]
    });
    if (_conversationHistory.length > 20) {
      _conversationHistory.removeAt(0);
    }
    notifyListeners();

    // Tự động kiểm tra lệnh hủy tiến trình đặt lịch
    final lowercaseText = text.toLowerCase();
    if (lowercaseText.contains('hủy') ||
        lowercaseText.contains('thoát') ||
        lowercaseText.contains('dừng') ||
        lowercaseText.contains('cancel')) {
      _activeBooking = null;
      await saveChatHistory();
      _messages.add(AiChatMessage(
        id: _nextMessageId(),
        sender: 'bot',
        text: 'Gâu! Đã hủy bỏ tiến trình đặt lịch hiện tại.',
      ));
      notifyListeners();
      return;
    }

    // Kiểm tra thông tin hồ sơ cá nhân
    if (lowercaseText.contains('thông tin cá nhân') ||
        lowercaseText.contains('thông tin của tôi') ||
        lowercaseText.contains('hồ sơ của tôi') ||
        lowercaseText.contains('tôi là ai') ||
        lowercaseText.contains('thông tin bệnh nhân')) {
      await _replyWithPatientProfile();
      return;
    }

    // Kiểm tra phím tắt xem đơn thuốc/hóa đơn/bệnh án
    if (lowercaseText.contains('đơn thuốc')) {
      await _replyWithLatestPrescription();
      return;
    }
    if (lowercaseText.contains('hóa đơn') || lowercaseText.contains('viện phí')) {
      await _replyWithLatestInvoice();
      return;
    }
    if (lowercaseText.contains('bệnh án') || lowercaseText.contains('hồ sơ khám')) {
      await _replyWithLatestMedicalRecord();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Tải thông tin bệnh nhân để chèn vào prompt
      final patientInfoStr = await _buildPatientContextString();

      // Gọi Gemini API
      final response = await Dio().post(
        'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$_geminiApiKey',
        data: {
          'system_instruction': {
            'parts': [
              {
                'text': '${_buildSystemInstruction()}\n\n$patientInfoStr'
              }
            ]
          },
          'contents': _conversationHistory,
          'generationConfig': {
            'responseMimeType': 'application/json',
            'maxOutputTokens': 2048,
            'temperature': 0.1,
          }
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final result = response.data;
        final replyText = result['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        final parsed = jsonDecode(replyText);

        final botReplyText = parsed['reply'] as String? ?? 'Gâu! Tôi chưa hiểu bạn nói gì.';
        
        // Thêm tin nhắn của Bot vào lịch sử Gemini (lưu tin nhắn Text thay vì JSON thô)
        _conversationHistory.add({
          'role': 'model',
          'parts': [
            {'text': botReplyText}
          ]
        });
        if (_conversationHistory.length > 20) {
          _conversationHistory.removeAt(0);
        }

        // Giả lập hiệu ứng chạy chữ
        await _typewriterEffect(botReplyText, parsed);
      } else {
        throw Exception('Gemini API returned error: ${response.statusCode}');
      }
    } catch (e) {
      print('Gemini chatbot error: $e');
      _messages.add(AiChatMessage(
        id: _nextMessageId(),
        sender: 'bot',
        text: 'Gâu... Dogky chưa gọi được AI Gemini lúc này. Bạn thử lại sau nhé.',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Giả lập hiệu ứng typewriter
  Future<void> _typewriterEffect(String fullText, Map<String, dynamic> parsed) async {
    final botMsgId = _nextMessageId();
    final chatMsg = AiChatMessage(
      id: botMsgId,
      sender: 'bot',
      text: '',
    );
    _messages.add(chatMsg);
    notifyListeners();

    int length = 0;
    final int totalLength = fullText.length;

    // Cập nhật text từ từ
    while (length < totalLength) {
      await Future.delayed(const Duration(milliseconds: 10));
      length += 2;
      if (length > totalLength) length = totalLength;

      // Cập nhật tin nhắn trong danh sách
      final idx = _messages.indexWhere((m) => m.id == botMsgId);
      if (idx != -1) {
        _messages[idx] = AiChatMessage(
          id: botMsgId,
          sender: 'bot',
          text: fullText.substring(0, length),
        );
        notifyListeners();
      }
    }

    // Xử lý logic Đặt lịch sau khi gõ chữ xong
    if (parsed['isBookingIntent'] == true) {
      if (_activeBooking == null) {
        _activeBooking = BookingState(step: 'specialty');
      }

      if (parsed['recommendedSpecialtyId'] != null) {
        final specId = parsed['recommendedSpecialtyId'] as int;
        final spec = _allSpecialties.firstWhere((s) => s['id'] == specId, orElse: () => {});
        if (spec.isNotEmpty) {
          _activeBooking!.specialtyId = specId;
          _activeBooking!.specialtyName = spec['name'];
        }
      }

      if (parsed['requestedDoctorId'] != null) {
        final docId = parsed['requestedDoctorId'] as int;
        final doc = _allDoctors.firstWhere((d) => d['id'] == docId, orElse: () => {});
        if (doc.isNotEmpty) {
          _activeBooking!.doctorId = docId;
          _activeBooking!.doctorName = doc['name'];
          _activeBooking!.examFee = doc['examFee'];
          if (_activeBooking!.specialtyId == null) {
            _activeBooking!.specialtyId = doc['specialtyId'];
            _activeBooking!.specialtyName = doc['specialtyName'];
          }
        }
      }

      if (parsed['requestedDate'] != null) {
        _activeBooking!.appointmentDate = parsed['requestedDate'] as String;
      }
      if (parsed['requestedTime'] != null) {
        _activeBooking!.slotTime = parsed['requestedTime'] as String;
      }
      if (parsed['reason'] != null) {
        _activeBooking!.reason = parsed['reason'] as String;
      }

      await processNextBookingStep('');
    }

    await saveChatHistory();
    notifyListeners();
  }

  // Điều phối quy trình Wizard đặt lịch
  Future<void> processNextBookingStep(String customReply) async {
    if (_activeBooking == null) return;

    // 1. Thiếu chuyên khoa
    if (_activeBooking!.specialtyId == null) {
      _activeBooking!.step = 'specialty';
      _messages.add(AiChatMessage(
        id: _nextMessageId(),
        sender: 'bot',
        text: customReply.isNotEmpty ? customReply : 'Gâu! Hãy chọn chuyên khoa bạn muốn khám bên dưới:',
        specialtySelector: _allSpecialties.map((s) => SpecialtySelectOption(
              specialtyId: s['id'] as int,
              specialtyName: s['name'] as String,
            )).toList(),
      ));
      notifyListeners();
      return;
    }

    // 2. Thiếu bác sĩ
    if (_activeBooking!.doctorId == null) {
      _activeBooking!.step = 'doctor';
      _isLoading = true;
      notifyListeners();

      try {
        final response = await _apiClient.dio.get('/appointment/api/doctors/by-specialty/${_activeBooking!.specialtyId}');
        final data = ApiClient.readApiResponse(response.data);
        if (response.statusCode == 200 && data != null) {
          final List list = data is List ? data : [];
          final docs = list.map((d) => DoctorSelectOption(
                doctorId: d['doctorId'] as int,
                doctorName: d['doctorName'] ?? d['fullName'] ?? 'Bác sĩ',
                examFee: d['examFee'] as int? ?? 150000,
                specialtyName: d['specialtyName'] ?? _activeBooking!.specialtyName ?? '',
              )).toList();

          _messages.add(AiChatMessage(
            id: _nextMessageId(),
            sender: 'bot',
            text: customReply.isNotEmpty ? customReply : 'Gâu! Hãy chọn bác sĩ khám của khoa ${_activeBooking!.specialtyName}:',
            doctorSelector: docs,
          ));
        } else {
          _messages.add(AiChatMessage(
            id: _nextMessageId(),
            sender: 'bot',
            text: 'Gâu! Không tìm thấy bác sĩ nào cho chuyên khoa này.',
          ));
        }
      } catch (e) {
        _messages.add(AiChatMessage(
          id: _nextMessageId(),
          sender: 'bot',
          text: 'Gâu! Không thể tải danh sách bác sĩ của chuyên khoa này lúc này.',
        ));
      } finally {
        _isLoading = false;
        notifyListeners();
      }
      return;
    }

    // 3. Thiếu ngày khám
    if (_activeBooking!.appointmentDate == null) {
      _activeBooking!.step = 'date';
      _messages.add(AiChatMessage(
        id: _nextMessageId(),
        sender: 'bot',
        text: customReply.isNotEmpty ? customReply : 'Gâu! Bạn muốn khám với bác sĩ ${_activeBooking!.doctorName} vào ngày nào? Hãy nhập vào ô chat nhé (ví dụ: "ngày mai", "ngày 10/7"...).',
      ));
      notifyListeners();
      return;
    }

    // 4. Thiếu giờ khám
    if (_activeBooking!.slotTime == null) {
      _activeBooking!.step = 'time';
      _isLoading = true;
      notifyListeners();

      final docId = _activeBooking!.doctorId;
      final dateVal = _activeBooking!.appointmentDate!;
      final dateText = _formatDateText(dateVal);

      try {
        final response = await _apiClient.dio.get('/appointment/api/doctors/$docId/available-slots?date=$dateVal');
        final data = ApiClient.readApiResponse(response.data);
        if (response.statusCode == 200 && data != null) {
          final List list = data is List ? data : [];
          final slots = list.map((e) => e.toString().substring(0, 5)).toList();

          if (slots.isNotEmpty) {
            _messages.add(AiChatMessage(
              id: _nextMessageId(),
              sender: 'bot',
              text: customReply.isNotEmpty ? customReply : 'Gâu! Hãy chọn một khung giờ khám còn trống ngày $dateText cho bác sĩ ${_activeBooking!.doctorName}:',
              timeSlotSelector: slots,
            ));
          } else {
            _messages.add(AiChatMessage(
              id: _nextMessageId(),
              sender: 'bot',
              text: 'Gâu! Rất tiếc, ngày $dateText đã hết sạch giờ khám trống cho bác sĩ ${_activeBooking!.doctorName}. Bạn vui lòng gõ ngày khác nhé.',
            ));
            _activeBooking!.appointmentDate = null;
          }
        }
      } catch (e) {
        _messages.add(AiChatMessage(
          id: _nextMessageId(),
          sender: 'bot',
          text: 'Gâu! Không thể tải giờ làm việc trống của bác sĩ lúc này.',
        ));
      } finally {
        _isLoading = false;
        notifyListeners();
      }
      return;
    }

    // 5. Đầy đủ thông tin -> Kiểm tra khả dụng & Hiển thị Card xác nhận
    _isLoading = true;
    notifyListeners();

    final docId = _activeBooking!.doctorId;
    final dateVal = _activeBooking!.appointmentDate!;
    final dateText = _formatDateText(dateVal);
    final reqTime = _activeBooking!.slotTime!.substring(0, 5);

    try {
      final response = await _apiClient.dio.get('/appointment/api/doctors/$docId/available-slots?date=$dateVal');
      final data = ApiClient.readApiResponse(response.data);
      final List list = (data is List) ? data : [];
      final slots = list.map((e) => e.toString().substring(0, 5)).toList();
      final isAvailable = slots.contains(reqTime);

      if (isAvailable) {
        _activeBooking!.step = 'confirm';
        _messages.add(AiChatMessage(
          id: _nextMessageId(),
          sender: 'bot',
          text: 'Gâu! Dogky đã lập sẵn phiếu đặt lịch khám. Bạn vui lòng kiểm tra lại thông tin và bấm Xác nhận nhé:',
          bookingConfirm: BookingConfirmData(
            specialtyName: _activeBooking!.specialtyName!,
            doctorName: _activeBooking!.doctorName!,
            dateText: dateText,
            slotTime: reqTime,
            fee: _activeBooking!.examFee!,
          ),
        ));
      } else {
        _activeBooking!.slotTime = null;
        _activeBooking!.step = 'time';
        _messages.add(AiChatMessage(
          id: _nextMessageId(),
          sender: 'bot',
          text: 'Gâu! Rất tiếc, khung giờ $reqTime ngày $dateText của bác sĩ ${_activeBooking!.doctorName} vừa mới bị đặt mất. Hãy chọn khung giờ khác bên dưới nhé:',
          timeSlotSelector: slots,
        ));
      }
    } catch (e) {
      _messages.add(AiChatMessage(
        id: _nextMessageId(),
        sender: 'bot',
        text: 'Gâu! Gặp sự cố kết nối khi kiểm tra lịch trống của bác sĩ.',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Chọn Chuyên khoa từ list tương tác
  Future<void> selectSpecialty(int id, String name) async {
    if (_activeBooking == null) return;
    _activeBooking!.specialtyId = id;
    _activeBooking!.specialtyName = name;
    
    _messages.add(AiChatMessage(
      id: _nextMessageId(),
      sender: 'user',
      text: 'Chọn chuyên khoa: $name',
    ));
    notifyListeners();

    await processNextBookingStep('');
    await saveChatHistory();
  }

  // Chọn Bác sĩ từ list tương tác
  Future<void> selectDoctor(int id, String name, int examFee, int specialtyId, String specialtyName) async {
    if (_activeBooking == null) return;
    _activeBooking!.doctorId = id;
    _activeBooking!.doctorName = name;
    _activeBooking!.examFee = examFee;
    if (_activeBooking!.specialtyId == null) {
      _activeBooking!.specialtyId = specialtyId;
      _activeBooking!.specialtyName = specialtyName;
    }

    _messages.add(AiChatMessage(
      id: _nextMessageId(),
      sender: 'user',
      text: 'Chọn bác sĩ: $name',
    ));
    notifyListeners();

    await processNextBookingStep('');
    await saveChatHistory();
  }

  // Chọn Khung giờ từ list tương tác
  Future<void> selectTimeSlot(String slot) async {
    if (_activeBooking == null) return;
    _activeBooking!.slotTime = slot;

    _messages.add(AiChatMessage(
      id: _nextMessageId(),
      sender: 'user',
      text: 'Chọn khung giờ: $slot',
    ));
    notifyListeners();

    await processNextBookingStep('');
    await saveChatHistory();
  }

  // Hủy tiến trình đặt lịch
  void cancelBooking() {
    _activeBooking = null;
    _messages.add(AiChatMessage(
      id: _nextMessageId(),
      sender: 'bot',
      text: 'Gâu! Đã hủy bỏ quy trình đặt lịch khám.',
    ));
    saveChatHistory();
    notifyListeners();
  }

  // Hoàn tất đặt lịch khám và gọi API đặt lịch
  Future<void> confirmBooking(String reason) async {
    if (_activeBooking == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final profileResponse = await _apiClient.dio.get('/medical/api/v1/medical/patients/me');
      final profileData = ApiClient.readApiResponse(profileResponse.data);
      if (profileResponse.statusCode != 200 || profileData == null) {
        throw Exception('Failed to retrieve patient profile');
      }

      final int patientId = profileData['id'] as int;
      final String patientName = profileData['fullName'] as String? ?? 'Bệnh nhân';
      final String patientPhone = profileData['phoneNumber'] ?? profileData['phone'] ?? '0000000000';

      final payload = {
        'patientId': patientId,
        'patientNameSnapshot': patientName,
        'patientPhoneSnapshot': patientPhone,
        'doctorId': _activeBooking!.doctorId!,
        'appointmentDate': _activeBooking!.appointmentDate!,
        'slotTime': _activeBooking!.slotTime!,
        'reason': reason.trim().isEmpty ? 'Khám sức khỏe' : reason.trim(),
      };

      final response = await _apiClient.dio.post('/appointment/api/appointments', data: payload);
      final data = ApiClient.readApiResponse(response.data);

      if (response.statusCode == 200 && data != null) {
        final int fee = _activeBooking!.examFee!;
        _activeBooking = null;

        _messages.add(AiChatMessage(
          id: _nextMessageId(),
          sender: 'bot',
          text: 'Gâu! Chúc mừng bạn đã đăng ký lịch khám thành công!',
          bookingSuccess: BookingSuccessData(
            appointmentId: data['appointmentId'] as int? ?? 0,
            appointmentCode: data['appointmentCode'] as String? ?? '',
            fee: fee,
          ),
        ));
      } else {
        throw Exception('Failed to create appointment');
      }
    } catch (e) {
      _messages.add(AiChatMessage(
        id: _nextMessageId(),
        sender: 'bot',
        text: 'Gâu! Lỗi kết nối khi gửi yêu cầu đặt khám. Bạn thử lại nhé.',
      ));
    } finally {
      _isLoading = false;
      await saveChatHistory();
      notifyListeners();
    }
  }

  // --- HÀM TRA CỨU DỮ LIỆU ĐỘNG (SHORTCUTS IN CHAT) ---

  // Tra cứu Đơn thuốc gần nhất
  Future<void> _replyWithLatestPrescription() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.dio.get('/medical/api/v1/medical/patients/me/clinical-timeline');
      final data = ApiClient.readApiResponse(response.data);
      if (response.statusCode == 200 && data != null) {
        final List list = data['prescriptions'] ?? [];
        if (list.isEmpty) {
          _messages.add(AiChatMessage(
            id: _nextMessageId(),
            sender: 'bot',
            text: 'Gâu, Dogky chưa thấy đơn thuốc nào trong hồ sơ của bạn.',
          ));
        } else {
          // Lấy đơn thuốc mới nhất theo ngày
          list.sort((a, b) => DateTime.parse(b['createdAt'] ?? b['submittedAt'] ?? '2000-01-01')
              .compareTo(DateTime.parse(a['createdAt'] ?? a['submittedAt'] ?? '2000-01-01')));
          final latest = list.first;

          final code = latest['prescriptionCode'] ?? latest['prescriptionIdCode'] ?? 'Không rõ';
          final date = _formatDateText(latest['submittedAt'] ?? latest['createdAt'] ?? '');
          final status = latest['status'] ?? latest['stockStatus'] ?? 'Chưa rõ';

          // Thuốc kê chi tiết
          final List items = latest['items'] ?? latest['prescriptionItems'] ?? [];
          final medicineSummary = items.isNotEmpty
              ? items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  final name = item['medicineName'] ?? item['name'] ?? 'Thuốc';
                  final dosage = item['dosage'] ?? 'Chưa có liều';
                  final freq = item['frequency'] != null ? ', ${item['frequency']}' : '';
                  return '$idx. $name - $dosage$freq';
                }).join('\n')
              : 'Chưa có chi tiết thuốc';

          _messages.add(AiChatMessage(
            id: _nextMessageId(),
            sender: 'bot',
            text: 'Gâu, đơn thuốc gần nhất đây:',
            tableRows: [
              ChatTableRow(label: 'Mã đơn', value: code),
              ChatTableRow(label: 'Ngày kê', value: date),
              ChatTableRow(label: 'Trạng thái', value: status),
              ChatTableRow(label: 'Thuốc', value: medicineSummary),
            ],
          ));
        }
      }
    } catch (e) {
      _messages.add(AiChatMessage(
        id: _nextMessageId(),
        sender: 'bot',
        text: 'Gâu, Dogky chưa lấy được đơn thuốc của bạn lúc này.',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tra cứu Viện phí gần nhất
  Future<void> _replyWithLatestInvoice() async {
    _isLoading = true;
    notifyListeners();
    try {
      final profileResponse = await _apiClient.dio.get('/medical/api/v1/medical/patients/me');
      final profileData = ApiClient.readApiResponse(profileResponse.data);
      final int patientId = profileData['id'] as int;

      final response = await _apiClient.dio.get('/pharmacy/api/invoices/patient/$patientId');
      final data = ApiClient.readApiResponse(response.data);
      if (response.statusCode == 200 && data != null) {
        final List list = data is List ? data : [];
        if (list.isEmpty) {
          _messages.add(AiChatMessage(
            id: _nextMessageId(),
            sender: 'bot',
            text: 'Gâu, Dogky chưa thấy hóa đơn viện phí nào của bạn.',
          ));
        } else {
          list.sort((a, b) => DateTime.parse(b['createdAt'] ?? '2000-01-01').compareTo(DateTime.parse(a['createdAt'] ?? '2000-01-01')));
          final latest = list.first;

          final code = latest['invoiceCode'] ?? latest['invoiceIdCode'] ?? 'Không rõ';
          final examFee = latest['examinationFee'] ?? latest['examFee'] ?? latest['amount'] ?? 0;
          final medicineTotal = latest['medicineTotal'] ?? 0;
          final status = latest['status'] ?? 'Chưa rõ';

          _messages.add(AiChatMessage(
            id: _nextMessageId(),
            sender: 'bot',
            text: 'Gâu, hóa đơn mới nhất:',
            tableRows: [
              ChatTableRow(label: 'Mã hóa đơn', value: code),
              ChatTableRow(label: 'Tiền khám', value: _formatCurrency(examFee as int)),
              ChatTableRow(label: 'Tiền thuốc', value: _formatCurrency(medicineTotal as int)),
              ChatTableRow(label: 'Trạng thái', value: _translateInvoiceStatus(status as String)),
            ],
          ));
        }
      }
    } catch (e) {
      _messages.add(AiChatMessage(
        id: _nextMessageId(),
        sender: 'bot',
        text: 'Gâu, Dogky chưa tra cứu được hóa đơn viện phí lúc này.',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tra cứu Bệnh án gần nhất
  Future<void> _replyWithLatestMedicalRecord() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.dio.get('/medical/api/v1/medical/patients/me/clinical-timeline');
      final data = ApiClient.readApiResponse(response.data);
      if (response.statusCode == 200 && data != null) {
        final List list = data['medicalRecords'] ?? [];
        if (list.isEmpty) {
          _messages.add(AiChatMessage(
            id: _nextMessageId(),
            sender: 'bot',
            text: 'Gâu, Dogky chưa thấy hồ sơ bệnh án nào của bạn.',
          ));
        } else {
          list.sort((a, b) => DateTime.parse(b['createdAt'] ?? b['completedAt'] ?? '2000-01-01')
              .compareTo(DateTime.parse(a['createdAt'] ?? a['completedAt'] ?? '2000-01-01')));
          final latest = list.first;

          final diagnosis = latest['diagnosisText'] ?? latest['diagnosis'] ?? 'Chưa có chẩn đoán';
          final doctorNote = latest['doctorNote'] ?? latest['doctorNotes'] ?? 'Chưa có lời dặn';
          final date = _formatDateText(latest['completedAt'] ?? latest['createdAt'] ?? '');
          final docName = latest['doctorName'] ?? 'Không rõ';

          _messages.add(AiChatMessage(
            id: _nextMessageId(),
            sender: 'bot',
            text: 'Gâu, bệnh án khám gần nhất:',
            tableRows: [
              ChatTableRow(label: 'Ngày khám', value: date),
              ChatTableRow(label: 'Chẩn đoán', value: diagnosis),
              ChatTableRow(label: 'Bác sĩ', value: docName),
              ChatTableRow(label: 'Lời dặn', value: doctorNote),
            ],
          ));
        }
      }
    } catch (e) {
      _messages.add(AiChatMessage(
        id: _nextMessageId(),
        sender: 'bot',
        text: 'Gâu, Dogky chưa tra cứu được bệnh án gần đây của bạn.',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Trình bày thông tin cá nhân
  Future<void> _replyWithPatientProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.dio.get('/medical/api/v1/medical/patients/me');
      final data = ApiClient.readApiResponse(response.data);
      if (response.statusCode == 200 && data != null) {
        final name = data['fullName'] ?? 'Chưa rõ';
        final dob = _formatDateText(data['dateOfBirth'] ?? '');
        final gender = data['gender'] == 'Male' ? 'Nam' : data['gender'] == 'Female' ? 'Nữ' : 'Chưa rõ';
        final phone = data['phoneNumber'] ?? data['phone'] ?? 'Chưa rõ';
        final allergies = data['allergyNote'] ?? data['allergies'] ?? 'Chưa ghi nhận';

        _messages.add(AiChatMessage(
          id: _nextMessageId(),
          sender: 'bot',
          text: 'Gâu! Đây là thông tin bệnh nhân của bạn:',
          tableRows: [
            ChatTableRow(label: 'Họ tên', value: name),
            ChatTableRow(label: 'Ngày sinh', value: dob),
            ChatTableRow(label: 'Giới tính', value: gender),
            ChatTableRow(label: 'Số điện thoại', value: phone),
            ChatTableRow(label: 'Dị ứng', value: allergies),
          ],
        ));
      }
    } catch (e) {
      _messages.add(AiChatMessage(
        id: _nextMessageId(),
        sender: 'bot',
        text: 'Gâu! Không tìm thấy hồ sơ cá nhân bệnh nhân.',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- HÀM HỖ TRỢ XÂY DỰNG PROMPT GEMINI ---

  String _buildSystemInstruction() {
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    String bookingStateStr = 'Chưa có thông tin đặt lịch.';
    if (_activeBooking != null) {
      bookingStateStr = '''
Trạng thái đặt lịch hiện tại của bệnh nhân:
- Chuyên khoa đã chọn: ${_activeBooking!.specialtyName ?? 'Chưa chọn'} (ID: ${_activeBooking!.specialtyId ?? 'chưa có'})
- Bác sĩ đã chọn: ${_activeBooking!.doctorName ?? 'Chưa chọn'} (ID: ${_activeBooking!.doctorId ?? 'chưa có'})
- Ngày khám đã chọn: ${_activeBooking!.appointmentDate ?? 'Chưa chọn'}
- Giờ khám đã chọn: ${_activeBooking!.slotTime ?? 'Chưa chọn'}
- Lý do khám: ${_activeBooking!.reason ?? 'Chưa có'}
'''.trim();
    }

    return '''
Bạn là chú cún bác sĩ Dogky đáng yêu của Medicare, vô cùng lịch sự, lễ phép, thân thiện và nhiệt tình tư vấn cho khách hàng. Hãy luôn chào hỏi lễ phép, thỉnh thoảng có thể sủa nhẹ "Gâu!" một cách đáng yêu để giữ nét đặc trưng của một chú cún.
Hãy luôn trả lời ngắn gọn, súc tích (tối đa 5 câu).

Hôm nay là thứ: ${now.weekday}, ngày: $dateStr, lúc: $timeStr.

Dưới đây là danh sách Chuyên khoa hiện có tại phòng khám Medicare:
${jsonEncode(_allSpecialties)}

Dưới đây là danh sách Bác sĩ hiện có tại phòng khám Medicare:
${jsonEncode(_allDoctors)}

$bookingStateStr

Nhiệm vụ của bạn:
1. Phân tích tin nhắn của người dùng để xác định xem họ có ý định đặt lịch khám bệnh (booking) hoặc mô tả triệu chứng bệnh hoặc hỏi cách điều trị hay không.
2. Nếu họ có ý định đặt lịch, mô tả triệu chứng hoặc hỏi cách điều trị:
   - Đặt "isBookingIntent" là true.
   - Gợi ý chuyên khoa từ danh sách chuyên khoa ở trên dựa vào triệu chứng. Đặt "recommendedSpecialtyId" tương ứng. Nếu chưa rõ hoặc không tìm thấy, để null.
   - Tìm bác sĩ khớp nhất trong danh sách trên (nếu họ nhắc đến bác sĩ) và đặt "requestedDoctorId" tương ứng.
   - Phân tích ngày khám họ muốn (ví dụ "ngày mai", "ngày kia", "ngày 10/7"...) và quy đổi sang định dạng "YYYY-MM-DD" dựa trên ngày hôm nay là $dateStr. Nếu không nhắc đến ngày, để null.
   - Phân tích giờ khám họ muốn (ví dụ "13h30", "14:00") và chuyển sang định dạng "HH:mm". Nếu không nhắc đến giờ, để null.
   - Tóm tắt lý do khám vào trường "reason".
   - Trả lời người dùng trong trường "reply": Tư vấn nhẹ nhàng 1-2 lời khuyên sơ cứu/chữa trị an toàn tại nhà, sau đó lịch sự gợi ý chuyên khoa phù hợp và hỏi xem họ có muốn đặt khám không.
3. Nếu họ không có ý định đặt lịch/hỏi triệu chứng:
   - Đặt "isBookingIntent" là false.
   - Trả lời người dùng trong trường "reply" một cách đáng yêu, tự nhiên.

BẮT BUỘC phải trả về kết quả dưới dạng JSON tuân thủ cấu trúc sau:
{
  "isBookingIntent": boolean,
  "symptoms": string | null,
  "recommendedSpecialtyId": number | null,
  "requestedDoctorId": number | null,
  "requestedDate": string | null,
  "requestedTime": string | null,
  "reason": string | null,
  "reply": string
}
''';
  }

  Future<String> _buildPatientContextString() async {
    try {
      final response = await _apiClient.dio.get('/medical/api/v1/medical/patients/me');
      final data = ApiClient.readApiResponse(response.data);
      if (response.statusCode == 200 && data != null) {
        return '''
Bệnh nhân đang đăng nhập:
- Họ tên: ${data['fullName'] ?? 'Chưa rõ'}
- Ngày sinh: ${data['dateOfBirth'] ?? 'Chưa rõ'}
- Giới tính: ${data['gender'] == 'Male' ? 'Nam' : 'Nữ'}
- Số điện thoại: ${data['phoneNumber'] ?? 'Chưa rõ'}
- Tiền sử dị ứng: ${data['allergyNote'] ?? 'Chưa ghi nhận'}
- Tiền sử bệnh lý: ${data['medicalHistory'] ?? 'Chưa ghi nhận'}
'''.trim();
      }
    } catch (_) {}
    return 'Chưa có thông tin bệnh nhân.';
  }

  // --- PHẦN GỢI Ý CHỦ ĐỘNG (PROACTIVE SUGGESTIONS LOOP) ---

  Future<void> _startProactiveReminderLoop() async {
    _proactiveTimer?.cancel();
    if (_isOpen) return;

    // Quét dữ liệu định kỳ mỗi 60 giây để cập nhật các nhắc nhở
    await _refreshProactiveReminders();

    // Vòng lặp timer hiển thị bong bóng
    _proactiveTimer = Timer.periodic(const Duration(seconds: 13), (timer) {
      if (_isOpen) {
        timer.cancel();
        return;
      }
      _showNextProactiveReminder();
    });
  }

  Future<void> _refreshProactiveReminders() async {
    try {
      final profileResponse = await _apiClient.dio.get('/medical/api/v1/medical/patients/me');
      final profileData = ApiClient.readApiResponse(profileResponse.data);
      final int patientId = profileData['id'] as int;

      // Tải lịch hẹn, hóa đơn, bệnh án song song
      final responses = await Future.wait([
        _apiClient.dio.get('/appointment/api/appointments/patient/$patientId').catchError((_) => Response(requestOptions: RequestOptions())),
        _apiClient.dio.get('/pharmacy/api/invoices/patient/$patientId').catchError((_) => Response(requestOptions: RequestOptions())),
        _apiClient.dio.get('/medical/api/v1/medical/patients/me/clinical-timeline').catchError((_) => Response(requestOptions: RequestOptions())),
      ]);

      final List<String> reminders = [];

      // 1. Quét lịch hẹn tương lai sắp diễn ra
      final apptsData = ApiClient.readApiResponse(responses[0].data);
      if (responses[0].statusCode == 200 && apptsData != null) {
        final List list = apptsData is List ? apptsData : [];
        final activeAppts = list.where((item) {
          final status = item['status']?.toString().toLowerCase() ?? '';
          if (status.contains('cancel') || status.contains('completed') || status.contains('done') || status.contains('hủy')) {
            return false;
          }
          final dateStr = item['appointmentDate']?.toString() ?? '';
          final timeStr = item['slotTime']?.toString() ?? '00:00';
          if (dateStr.isEmpty) return false;
          try {
            final apptTime = DateTime.parse('${dateStr.substring(0, 10)}T${timeStr.substring(0, 5)}:00');
            return apptTime.isAfter(DateTime.now().subtract(const Duration(minutes: 15)));
          } catch (_) {
            return false;
          }
        }).toList();

        if (activeAppts.isNotEmpty) {
          activeAppts.sort((a, b) => a['appointmentDate'].compareTo(b['appointmentDate']));
          final next = activeAppts.first;
          final date = _formatDateText(next['appointmentDate']);
          final time = next['slotTime']?.toString().substring(0, 5) ?? '';
          final doc = next['doctorName'] ?? '';
          reminders.add('Lịch khám $date lúc $time${doc.isNotEmpty ? ' với BS $doc' : ''}.');
        }
      }

      // 2. Quét hóa đơn chưa thanh toán
      final invoicesData = ApiClient.readApiResponse(responses[1].data);
      if (responses[1].statusCode == 200 && invoicesData != null) {
        final List list = invoicesData is List ? invoicesData : [];
        final unpaid = list.where((item) {
          final status = item['status']?.toString().toLowerCase() ?? '';
          final balance = item['balanceDue'] as int? ?? 0;
          return balance > 0 || status.contains('unpaid') || status.contains('pending') || status.contains('chưa');
        }).toList();

        if (unpaid.isNotEmpty) {
          unpaid.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
          final latest = unpaid.first;
          final code = latest['invoiceCode'] ?? '';
          final total = latest['balanceDue'] ?? latest['totalAmount'] ?? 0;
          reminders.add('Hóa đơn $code chưa thanh toán: ${_formatCurrency(total as int)}.');
        }
      }

      // 3. Quét đơn thuốc mới
      final timelineData = ApiClient.readApiResponse(responses[2].data);
      if (responses[2].statusCode == 200 && timelineData != null) {
        final List prescriptions = timelineData['prescriptions'] ?? [];
        if (prescriptions.isNotEmpty) {
          prescriptions.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
          final latest = prescriptions.first;
          final code = latest['prescriptionCode'] ?? '';
          reminders.add('Đơn thuốc $code đã được cập nhật.');
        }
      }

      _proactiveReminders = reminders;
      _proactiveIndex = 0;
    } catch (e) {
      print('Warning: Proactive background check skipped: $e');
    }
  }

  void _showNextProactiveReminder() {
    if (_proactiveReminders.isEmpty) {
      _activeSpeechBubbleText = 'Tôi có thể giúp gì cho bạn?';
      _isSpeechBubbleVisible = false;
      notifyListeners();
      return;
    }

    // Hiển thị lời nhắc
    final reminder = _proactiveReminders[_proactiveIndex % _proactiveReminders.length];
    _proactiveIndex++;
    _activeSpeechBubbleText = reminder.length > 72 ? '${reminder.substring(0, 69)}...' : reminder;
    _isSpeechBubbleVisible = true;
    notifyListeners();

    // Ẩn bóng thoại sau 3 giây
    Timer(const Duration(seconds: 3), () {
      _isSpeechBubbleVisible = false;
      notifyListeners();
    });
  }

  // --- HÀM TIỆN ÍCH ĐỊNH DẠNG ---

  String _formatDateText(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatCurrency(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      buffer.write(str[i]);
      final reverseIdx = str.length - 1 - i;
      if (reverseIdx > 0 && reverseIdx % 3 == 0) {
        buffer.write('.');
      }
    }
    return '${buffer.toString()} ₫';
  }

  String _translateInvoiceStatus(String status) {
    final norm = status.toLowerCase();
    if (norm.contains('unpaid')) return 'Chưa thanh toán';
    if (norm.contains('paid')) return 'Đã thanh toán';
    if (norm.contains('cancel')) return 'Đã hủy';
    return status;
  }
}
