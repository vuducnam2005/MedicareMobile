import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class DoctorDashboardController extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<dynamic> _visits = [];
  List<dynamic> _appointments = [];
  List<dynamic> _medicalRecords = [];
  List<dynamic> _schedules = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> _medicines = [];
  bool _isMedicinesLoading = false;

  List<dynamic> get visits => _visits;
  List<dynamic> get appointments => _appointments;
  List<dynamic> get medicalRecords => _medicalRecords;
  List<dynamic> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<dynamic> get medicines => _medicines;
  bool get isMedicinesLoading => _isMedicinesLoading;

  // Tải toàn bộ dữ liệu của bác sĩ
  Future<void> loadAllDoctorData(int doctorId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        _fetchVisits(doctorId),
        _fetchAppointments(doctorId),
        _fetchMedicalRecords(),
        _fetchDoctorSchedules(doctorId),
      ]);
    } catch (e) {
      _errorMessage = 'Lỗi tải dữ liệu bác sĩ: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 1. Tải danh sách ca khám hôm nay của bác sĩ
  Future<void> _fetchVisits(int doctorId) async {
    try {
      final response = await _apiClient.dio.get(
        '/medical/api/v1/medical/visits/today',
        queryParameters: {'doctorId': doctorId},
      );
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          _visits = response.data;
        } else if (response.data is Map && response.data['data'] is List) {
          _visits = response.data['data'];
        } else {
          _visits = [];
        }
      } else {
        _visits = [];
      }
    } on DioException catch (e) {
      _errorMessage = _getDioErrorMessage(e);
      _visits = [];
    } catch (e) {
      _visits = [];
      rethrow;
    }
  }

  // 2. Tải danh sách lịch hẹn hôm nay của bác sĩ
  Future<void> _fetchAppointments(int doctorId) async {
    try {
      final response = await _apiClient.dio.get(
        '/appointment/api/appointments/doctor/$doctorId',
      );
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          _appointments = response.data;
        } else if (response.data is Map && response.data['data'] is List) {
          _appointments = response.data['data'];
        } else {
          _appointments = [];
        }
      } else {
        _appointments = [];
      }
    } catch (e) {
      _appointments = [];
      rethrow;
    }
  }

  // 3. Tải toàn bộ hồ sơ bệnh án từ MedicalAPI (N2)
  Future<void> _fetchMedicalRecords() async {
    try {
      final response = await _apiClient.dio.get('/medical/api/v1/medical/records');
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          _medicalRecords = response.data;
        } else if (response.data is Map && response.data['data'] is List) {
          _medicalRecords = response.data['data'];
        } else {
          _medicalRecords = [];
        }
      } else {
        _medicalRecords = [];
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách bệnh án: $e');
      _medicalRecords = [];
    }
  }

  // 4. Tải lịch làm việc động từ AppointmentService (N1)
  Future<void> _fetchDoctorSchedules(int doctorId) async {
    try {
      final response = await _apiClient.dio.get('/appointment/api/doctor-schedules/doctor/$doctorId');
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          _schedules = response.data;
        } else if (response.data is Map && response.data['data'] is List) {
          _schedules = response.data['data'];
        } else {
          _schedules = [];
        }
      } else {
        _schedules = [];
      }
    } catch (e) {
      debugPrint('Lỗi tải lịch trực bác sĩ: $e');
      _schedules = [];
    }
  }

  // Phương thức công khai để tải lại danh sách ca khám
  Future<void> loadTodayVisits(int doctorId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _fetchVisits(doctorId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tải danh mục thuốc từ kho (N3)
  Future<void> loadMedicines() async {
    _isMedicinesLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        '/pharmacy/api/medicines',
        queryParameters: {'status': 'Active', 'pageSize': 100},
      );
      
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          _medicines = response.data;
        } else if (response.data is Map && response.data['data'] is List) {
          _medicines = response.data['data'];
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải danh mục thuốc: $e');
    } finally {
      _isMedicinesLoading = false;
      notifyListeners();
    }
  }

  // Bắt đầu ca khám (Chuyển trạng thái sang Examining)
  Future<bool> startVisit(int visitId, int doctorId, String chiefComplaint) async {
    try {
      final response = await _apiClient.dio.put(
        '/medical/api/v1/medical/visits/$visitId/start',
        data: {
          'doctorId': doctorId,
          'chiefComplaint': chiefComplaint.isNotEmpty ? chiefComplaint : 'Khám lâm sàng',
        },
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Lỗi bắt đầu ca khám: $e');
      return false;
    }
  }

  // Cập nhật chỉ số sinh tồn (Vitals)
  Future<bool> updateVitals(int visitId, Map<String, dynamic> vitals) async {
    try {
      final response = await _apiClient.dio.put(
        '/medical/api/v1/medical/visits/$visitId/vitals',
        data: vitals,
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Lỗi cập nhật chỉ số sinh tồn: $e');
      return false;
    }
  }

  // Lưu hồ sơ bệnh án (Medical Record)
  Future<Map<String, dynamic>?> createMedicalRecord({
    required int visitId,
    required String diagnosisText,
    String? diagnosisCode,
    String? doctorNote,
    String? treatmentPlan,
    String? followUpDate,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/medical/api/v1/medical/records',
        data: {
          'visitId': visitId,
          'diagnosisText': diagnosisText,
          'diagnosisCode': diagnosisCode ?? 'ICD-10',
          'doctorNote': doctorNote,
          'treatmentPlan': treatmentPlan,
          'followUpDate': followUpDate,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map) {
          return response.data['data'] ?? response.data;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi lưu bệnh án: $e');
      return null;
    }
  }

  // Tạo đơn thuốc trống liên kết với bệnh án
  Future<Map<String, dynamic>?> createPrescription(int medicalRecordId, String? note) async {
    try {
      final response = await _apiClient.dio.post(
        '/medical/api/v1/medical/prescriptions',
        data: {
          'medicalRecordId': medicalRecordId,
          'note': note ?? '',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map) {
          return response.data['data'] ?? response.data;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi khởi tạo đơn thuốc: $e');
      return null;
    }
  }

  // Chốt danh sách thuốc kê cho đơn thuốc
  Future<bool> submitPrescription(int prescriptionId, int medicalRecordId, List<Map<String, dynamic>> items, String? note) async {
    try {
      final response = await _apiClient.dio.put(
        '/medical/api/v1/medical/prescriptions/$prescriptionId/submit',
        data: {
          'medicalRecordId': medicalRecordId,
          'note': note ?? '',
          'items': items,
        },
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Lỗi gửi chốt đơn thuốc: $e');
      return false;
    }
  }

  // Hoàn tất ca khám (Chuyển trạng thái sang Completed)
  Future<bool> completeVisit(int visitId) async {
    try {
      final response = await _apiClient.dio.put(
        '/medical/api/v1/medical/visits/$visitId/complete',
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Lỗi hoàn tất lượt khám: $e');
      return false;
    }
  }

  // Lấy hồ sơ thông tin chi tiết bệnh nhân
  Future<Map<String, dynamic>?> getPatientDetail(int patientId) async {
    try {
      final response = await _apiClient.dio.get('/medical/api/v1/medical/patients/$patientId');
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map) {
          return response.data['data'] ?? response.data;
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải chi tiết bệnh nhân: $e');
    }
    return null;
  }

  // Lấy danh sách lịch sử bệnh án đã khám của bệnh nhân
  Future<List<dynamic>?> getPatientHistory(int patientId) async {
    try {
      final response = await _apiClient.dio.get('/medical/api/v1/medical/patients/$patientId/history');
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          return response.data;
        } else if (response.data is Map && response.data['data'] is List) {
          return response.data['data'];
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải lịch sử bệnh án: $e');
    }
    return null;
  }

  String _getDioErrorMessage(DioException e) {
    if (e.response != null && e.response!.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        return data['message'] ?? data['Message'] ?? 'Lỗi kết nối máy chủ';
      }
    }
    return e.message ?? 'Lỗi kết nối máy chủ';
  }
}
