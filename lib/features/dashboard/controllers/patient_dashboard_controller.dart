import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../patient/models/patient_model.dart';
import '../../appointment/models/appointment_model.dart';
import '../../billing/models/invoice_model.dart';

class PatientDashboardController extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  PatientModel? _patient;
  List<AppointmentModel> _appointments = [];
  List<InvoiceModel> _invoices = [];
  int _totalMedicalRecords = 0;
  List<dynamic> _medicalRecords = [];
  List<dynamic> _prescriptions = [];
  
  bool _isLoading = false;
  String? _errorMessage;

  PatientModel? get patient => _patient;
  List<AppointmentModel> get appointments => _appointments;
  List<InvoiceModel> get invoices => _invoices;
  int get totalMedicalRecords => _totalMedicalRecords;
  List<dynamic> get medicalRecords => _medicalRecords;
  List<dynamic> get prescriptions => _prescriptions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Lịch khám gần nhất sắp tới
  AppointmentModel? get nextAppointment {
    if (_appointments.isEmpty) return null;
    
    final now = DateTime.now();
    List<AppointmentModel> upcoming = _appointments.where((a) {
      final statusLower = a.status.toLowerCase();
      if (statusLower.contains('cancel') || statusLower.contains('completed')) {
        return false;
      }
      try {
        final apptDate = DateTime.parse(a.appointmentDate);
        return apptDate.isAfter(now) || 
               (apptDate.year == now.year && apptDate.month == now.month && apptDate.day == now.day);
      } catch (_) {
        return false;
      }
    }).toList();

    if (upcoming.isEmpty) return null;

    // Sắp xếp lịch hẹn sớm nhất lên đầu
    upcoming.sort((a, b) {
      try {
        final dateA = DateTime.parse(a.appointmentDate);
        final dateB = DateTime.parse(b.appointmentDate);
        return dateA.compareTo(dateB);
      } catch (_) {
        return 0;
      }
    });

    return upcoming.first;
  }

  // Thống kê tài chính: hóa đơn chưa thanh toán
  double get unpaidAmount {
    return _invoices
        .where((i) => i.status.toLowerCase() == 'unpaid')
        .fold(0.0, (sum, i) => sum + i.totalAmount);
  }

  int get unpaidInvoicesCount {
    return _invoices.where((i) => i.status.toLowerCase() == 'unpaid').length;
  }

  // Tải toàn bộ dữ liệu cho Dashboard
  Future<void> loadDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('DEBUG: Bat dau tai du lieu dashboard...');
      // 1. Lấy thông tin bệnh nhân hiện tại
      final patientResponse = await _apiClient.dio.get('/medical/api/v1/medical/patients/me');
      print('DEBUG: Get patient status: ${patientResponse.statusCode}');
      print('DEBUG: Get patient data: ${patientResponse.data}');
      
      final patientData = ApiClient.readApiResponse(patientResponse.data);
      if (patientResponse.statusCode == 200 && patientData != null) {
        _patient = PatientModel.fromJson(patientData);
        print('DEBUG: Parsed Patient: id=${_patient!.id}, fullName=${_patient!.fullName}, email=${_patient!.email}');
        final patientId = _patient!.id;

        // 2. Tải song song các dữ liệu liên quan
        print('DEBUG: Bat dau tai song song data khac cho patientId=$patientId...');
        final responses = await Future.wait([
          _apiClient.dio.get('/appointment/api/appointments/patient/$patientId'),
          _apiClient.dio.get('/pharmacy/api/invoices/patient/$patientId'),
          _apiClient.dio.get('/medical/api/v1/medical/patients/me/clinical-timeline'),
        ]);

        print('DEBUG: Responses status: [${responses[0].statusCode}, ${responses[1].statusCode}, ${responses[2].statusCode}]');

        // Xử lý danh sách lịch hẹn
        final appointmentsData = ApiClient.readApiResponse(responses[0].data);
        if (responses[0].statusCode == 200 && appointmentsData != null) {
          final List list = appointmentsData is List ? appointmentsData : [];
          _appointments = list.map((item) => AppointmentModel.fromJson(item)).toList();
          print('DEBUG: Loaded ${_appointments.length} appointments');
        }

        // Xử lý danh sách hóa đơn
        final invoicesData = ApiClient.readApiResponse(responses[1].data);
        if (responses[1].statusCode == 200 && invoicesData != null) {
          final List list = invoicesData is List ? invoicesData : [];
          _invoices = list.map((item) => InvoiceModel.fromJson(item)).toList();
          print('DEBUG: Loaded ${_invoices.length} invoices');
        }

        // Xử lý Timeline bệnh án để đếm số lượng bệnh án & đơn thuốc
        final timelineData = ApiClient.readApiResponse(responses[2].data);
        if (responses[2].statusCode == 200 && timelineData != null) {
          _medicalRecords = timelineData['medicalRecords'] ?? [];
          _totalMedicalRecords = _medicalRecords.length;
          _prescriptions = timelineData['prescriptions'] ?? [];
          print('DEBUG: Loaded $_totalMedicalRecords medical records and ${_prescriptions.length} prescriptions');
        }
      } else {
        _errorMessage = 'Không thể lấy thông tin bệnh nhân.';
        print('DEBUG: patientResponse status is not 200 or data is null');
      }
    } on DioException catch (e) {
      print('DEBUG: DioException in loadDashboardData: ${e.message}');
      print('DEBUG: DioException response: ${e.response?.statusCode} - ${e.response?.data}');
      if (e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        _errorMessage = data is Map ? (data['message'] ?? data['Message'] ?? 'Lỗi tải dữ liệu') : 'Lỗi tải dữ liệu';
      } else {
        _errorMessage = 'Lỗi kết nối mạng. Vui lòng kiểm tra lại.';
      }
    } catch (e) {
      print('DEBUG: General exception in loadDashboardData: $e');
      _errorMessage = 'Đã xảy ra lỗi hệ thống: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cập nhật thông tin hồ sơ bệnh nhân lên cơ sở dữ liệu chung
  Future<bool> updatePatientProfile({
    required String fullName,
    required String? dob, // YYYY-MM-DD
    required String? gender,
    required String? phoneNumber,
    required String? email,
    required String? address,
    required String? citizenId,
    required String? bloodType,
    required String? allergyNote,
    required String? medicalHistory,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Cập nhật thông tin tài khoản ở PharmacyBillingService để đồng bộ họ tên cho thông báo/hóa đơn
      if (email != null && email.trim().isNotEmpty) {
        await _apiClient.dio.put(
          '/pharmacy/api/auth/profile',
          data: {
            'fullName': fullName,
            'email': email,
            'phoneNumber': phoneNumber,
          },
        );
      }

      // 2. Cập nhật thông tin y tế ở MedicalAPI
      final response = await _apiClient.dio.put(
        '/medical/api/v1/medical/patients/me',
        data: {
          'fullName': fullName,
          'dateOfBirth': dob,
          'gender': gender,
          'phoneNumber': phoneNumber,
          'email': email,
          'address': address,
          'citizenId': citizenId,
          'bloodType': bloodType,
          'allergyNote': allergyNote,
          'medicalHistory': medicalHistory,
          'status': _patient?.status ?? 'Active',
        },
      );

      final data = ApiClient.readApiResponse(response.data);
      if (response.statusCode == 200 && data != null) {
        _patient = PatientModel.fromJson(data);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _isLoading = false;
      if (e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        _errorMessage = data is Map ? (data['message'] ?? data['Message'] ?? 'Lỗi cập nhật hồ sơ') : 'Lỗi cập nhật hồ sơ';
      } else {
        _errorMessage = 'Lỗi kết nối mạng.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi hệ thống: $e';
      notifyListeners();
      return false;
    }
  }

  // Hủy lịch hẹn khám
  Future<bool> cancelAppointment(int appointmentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.put(
        '/appointment/api/appointments/$appointmentId/cancel',
      );
      if (response.statusCode == 200) {
        await loadDashboardData(); // Tải lại danh sách sau khi hủy thành công
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _isLoading = false;
      if (e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        _errorMessage = data is Map ? (data['message'] ?? data['Message'] ?? 'Hủy lịch thất bại') : 'Hủy lịch thất bại';
      } else {
        _errorMessage = 'Lỗi kết nối mạng khi hủy lịch.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi hệ thống: $e';
      notifyListeners();
      return false;
    }
  }
}
