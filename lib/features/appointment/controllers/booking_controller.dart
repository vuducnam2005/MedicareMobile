import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/specialty_model.dart';
import '../models/doctor_model.dart';
import '../models/appointment_model.dart';

class BookingController extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<SpecialtyModel> _specialties = [];
  List<DoctorModel> _doctors = [];
  List<String> _availableSlots = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<SpecialtyModel> get specialties => _specialties;
  List<DoctorModel> get doctors => _doctors;
  List<String> get availableSlots => _availableSlots;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 1. Tải danh sách chuyên khoa
  Future<void> loadSpecialties() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/appointment/api/specialties');
      final data = ApiClient.readApiResponse(response.data);
      if (data is List) {
        _specialties = data.map((item) => SpecialtyModel.fromJson(item)).toList();
      } else {
        _specialties = [];
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final resData = e.response?.data;
        _errorMessage = resData is Map ? (resData['message'] ?? resData['Message'] ?? 'Lỗi tải chuyên khoa') : 'Lỗi tải chuyên khoa';
      } else {
        _errorMessage = 'Lỗi kết nối mạng khi tải chuyên khoa.';
      }
    } catch (e) {
      _errorMessage = 'Lỗi hệ thống: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Tải danh sách bác sĩ theo chuyên khoa
  Future<void> loadDoctorsBySpecialty(int specialtyId) async {
    _isLoading = true;
    _errorMessage = null;
    _doctors = [];
    _availableSlots = [];
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/appointment/api/doctors/by-specialty/$specialtyId');
      final data = ApiClient.readApiResponse(response.data);
      if (data is List) {
        _doctors = data.map((item) => DoctorModel.fromJson(item)).toList();
      } else {
        _doctors = [];
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final resData = e.response?.data;
        _errorMessage = resData is Map ? (resData['message'] ?? resData['Message'] ?? 'Lỗi tải bác sĩ') : 'Lỗi tải bác sĩ';
      } else {
        _errorMessage = 'Lỗi kết nối mạng khi tải bác sĩ.';
      }
    } catch (e) {
      _errorMessage = 'Lỗi hệ thống: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. Tải danh sách khung giờ khám còn trống
  Future<void> loadAvailableSlots(int doctorId, String date) async {
    _isLoading = true;
    _errorMessage = null;
    _availableSlots = [];
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        '/appointment/api/doctors/$doctorId/available-slots',
        queryParameters: {'date': date},
      );
      final data = ApiClient.readApiResponse(response.data);
      if (data is List) {
        _availableSlots = data.map((item) {
          // Chuẩn hóa slotTime dạng HH:mm
          final String str = item.toString();
          if (str.length >= 5) {
            return str.substring(0, 5);
          }
          return str;
        }).toList();
      } else {
        _availableSlots = [];
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final resData = e.response?.data;
        _errorMessage = resData is Map ? (resData['message'] ?? resData['Message'] ?? 'Lỗi tải khung giờ') : 'Lỗi tải khung giờ';
      } else {
        _errorMessage = 'Lỗi kết nối mạng khi tải khung giờ.';
      }
    } catch (e) {
      _errorMessage = 'Lỗi hệ thống: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 4. Gửi yêu cầu đặt lịch khám
  Future<AppointmentModel?> submitBooking({
    required int patientId,
    required String patientName,
    required String patientPhone,
    required String patientEmail,
    required String patientDob,
    required String patientGender,
    required String patientCitizenId,
    required int doctorId,
    required String appointmentDate, // YYYY-MM-DD
    required String slotTime, // HH:mm:00
    required String reason,
    required double examFee,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = {
        'patientId': patientId,
        'patientNameSnapshot': patientName,
        'patientPhoneSnapshot': patientPhone,
        'doctorId': doctorId,
        'appointmentDate': appointmentDate,
        'slotTime': slotTime.contains(':00') ? slotTime : '$slotTime:00',
        'reason': reason,
        'totalEstimatedFee': examFee,
        'patients': [
          {
            'patientId': patientId,
            'fullName': patientName,
            'phoneNumber': patientPhone,
            'dateOfBirth': patientDob,
            'gender': patientGender,
            'citizenId': patientCitizenId,
            'email': patientEmail,
            'isPrimary': true,
            'reason': reason,
          }
        ]
      };

      final response = await _apiClient.dio.post('/appointment/api/appointments', data: payload);
      final data = ApiClient.readApiResponse(response.data);
      if (response.statusCode == 200 || response.statusCode == 210 || response.statusCode == 201) {
        if (data != null) {
          final appointment = AppointmentModel.fromJson(data);
          _isLoading = false;
          notifyListeners();
          return appointment;
        }
      }
      _isLoading = false;
      _errorMessage = 'Đặt lịch thất bại. Vui lòng thử lại.';
      notifyListeners();
      return null;
    } on DioException catch (e) {
      _isLoading = false;
      if (e.response != null && e.response?.data != null) {
        final resData = e.response?.data;
        _errorMessage = resData is Map ? (resData['message'] ?? resData['Message'] ?? 'Đặt lịch thất bại') : 'Đặt lịch thất bại';
      } else {
        _errorMessage = 'Lỗi kết nối mạng khi gửi đặt lịch.';
      }
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi hệ thống: $e';
      notifyListeners();
      return null;
    }
  }
}
