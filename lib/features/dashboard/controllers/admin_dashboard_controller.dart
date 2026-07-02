import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class AdminDashboardController extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<dynamic> _doctors = [];
  List<dynamic> _specialties = [];
  List<dynamic> _schedules = [];
  List<dynamic> _patients = [];
  List<dynamic> _appointments = [];
  List<dynamic> _medicines = [];
  List<dynamic> _prescriptions = [];
  List<dynamic> _bills = [];
  List<dynamic> _accounts = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get doctors => _doctors;
  List<dynamic> get specialties => _specialties;
  List<dynamic> get schedules => _schedules;
  List<dynamic> get patients => _patients;
  List<dynamic> get appointments => _appointments;
  List<dynamic> get medicines => _medicines;
  List<dynamic> get prescriptions => _prescriptions;
  List<dynamic> get bills => _bills;
  List<dynamic> get accounts => _accounts;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 1. Tải toàn bộ dữ liệu quản trị viên
  Future<void> loadAllAdminData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        fetchDoctors(),
        fetchSpecialties(),
        fetchSchedules(),
        fetchPatients(),
        fetchAppointments(),
        fetchMedicines(),
        fetchPrescriptions(),
        fetchBills(),
        fetchAccounts(),
      ]);
    } catch (e) {
      _errorMessage = 'Lỗi tải dữ liệu quản trị viên: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper bóc tách dữ liệu từ API
  List<dynamic> _parseList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map) {
      if (data['data'] is List) return data['data'];
      if (data['value'] is List) return data['value'];
      if (data['items'] is List) return data['items'];
      if (data['Items'] is List) return data['Items'];
      
      final nestedData = data['data'];
      if (nestedData is Map) {
        if (nestedData['items'] is List) return nestedData['items'];
        if (nestedData['Items'] is List) return nestedData['Items'];
        if (nestedData['value'] is List) return nestedData['value'];
        if (nestedData['data'] is List) return nestedData['data'];
      }
    }
    return [];
  }

  // --- GET METHODS ---

  Future<void> fetchDoctors() async {
    try {
      final response = await _apiClient.dio.get('/appointment/api/doctors');
      _doctors = _parseList(response.data);
    } catch (e) {
      debugPrint('Error fetchDoctors: $e');
      _doctors = [];
    }
  }

  Future<void> fetchSpecialties() async {
    try {
      final response = await _apiClient.dio.get('/appointment/api/specialties');
      _specialties = _parseList(response.data);
    } catch (e) {
      debugPrint('Error fetchSpecialties: $e');
      _specialties = [];
    }
  }

  Future<void> fetchSchedules() async {
    try {
      final response = await _apiClient.dio.get('/appointment/api/doctor-schedules');
      _schedules = _parseList(response.data);
    } catch (e) {
      debugPrint('Error fetchSchedules: $e');
      _schedules = [];
    }
  }

  Future<void> fetchPatients() async {
    try {
      final response = await _apiClient.dio.get('/medical/api/v1/medical/patients', queryParameters: {'pageSize': 100});
      _patients = _parseList(response.data);
    } catch (e) {
      debugPrint('Error fetchPatients: $e');
      _patients = [];
    }
  }

  Future<void> fetchAppointments() async {
    try {
      final response = await _apiClient.dio.get('/appointment/api/appointments');
      _appointments = _parseList(response.data);
    } catch (e) {
      debugPrint('Error fetchAppointments: $e');
      _appointments = [];
    }
  }

  Future<void> fetchMedicines() async {
    try {
      final response = await _apiClient.dio.get('/pharmacy/api/medicines');
      _medicines = _parseList(response.data);
    } catch (e) {
      debugPrint('Error fetchMedicines: $e');
      _medicines = [];
    }
  }

  Future<void> fetchPrescriptions() async {
    try {
      final response = await _apiClient.dio.get('/medical/api/v1/medical/records');
      _prescriptions = _parseList(response.data);
    } catch (e) {
      debugPrint('Error fetchPrescriptions: $e');
      _prescriptions = [];
    }
  }

  Future<void> fetchBills() async {
    try {
      final response = await _apiClient.dio.get('/pharmacy/api/billing/invoices');
      _bills = _parseList(response.data);
    } catch (e) {
      debugPrint('Error fetchBills: $e');
      _bills = [];
    }
  }

  Future<void> fetchAccounts() async {
    try {
      final response = await _apiClient.dio.get('/pharmacy/api/auth/users');
      _accounts = _parseList(response.data);
    } catch (e) {
      debugPrint('Error fetchAccounts: $e');
      _accounts = [];
    }
  }

  // --- CRUD METHODS ---

  // Doctor CRUD
  Future<void> createDoctor(Map<String, dynamic> payload) async {
    await _apiClient.dio.post('/appointment/api/doctors', data: payload);
    await fetchDoctors();
    notifyListeners();
  }

  Future<void> updateDoctor(int id, Map<String, dynamic> payload) async {
    await _apiClient.dio.put('/appointment/api/doctors/$id', data: payload);
    await fetchDoctors();
    notifyListeners();
  }

  Future<void> deleteDoctor(int id) async {
    await _apiClient.dio.delete('/appointment/api/doctors/$id');
    await fetchDoctors();
    notifyListeners();
  }

  // Specialty CRUD
  Future<void> createSpecialty(Map<String, dynamic> payload) async {
    await _apiClient.dio.post('/appointment/api/specialties', data: payload);
    await fetchSpecialties();
    notifyListeners();
  }

  Future<void> updateSpecialty(int id, Map<String, dynamic> payload) async {
    await _apiClient.dio.put('/appointment/api/specialties/$id', data: payload);
    await fetchSpecialties();
    notifyListeners();
  }

  Future<void> deleteSpecialty(int id) async {
    await _apiClient.dio.delete('/appointment/api/specialties/$id');
    await fetchSpecialties();
    notifyListeners();
  }

  // Schedule CRUD
  Future<void> createSchedule(Map<String, dynamic> payload) async {
    await _apiClient.dio.post('/appointment/api/doctor-schedules', data: payload);
    await fetchSchedules();
    notifyListeners();
  }

  Future<void> updateSchedule(int id, Map<String, dynamic> payload) async {
    await _apiClient.dio.put('/appointment/api/doctor-schedules/$id', data: payload);
    await fetchSchedules();
    notifyListeners();
  }

  Future<void> deleteSchedule(int id) async {
    await _apiClient.dio.delete('/appointment/api/doctor-schedules/$id');
    await fetchSchedules();
    notifyListeners();
  }

  // Bulk Create Schedules (Dart Client Implementation)
  Future<void> createBulkSchedules(
    int doctorId,
    List<int> weekdays, // 1 to 7
    DateTime fromDate,
    DateTime toDate,
    String startTime,
    String endTime,
    int slotDuration,
  ) async {
    List<Map<String, dynamic>> payloads = [];
    
    // Tìm tất cả các ngày phù hợp trong khoảng từ fromDate đến toDate
    for (int i = 0; i <= toDate.difference(fromDate).inDays; i++) {
      final date = fromDate.add(Duration(days: i));
      if (weekdays.contains(date.weekday)) {
        final dateStr = date.toIso8601String().substring(0, 10);
        payloads.add({
          'doctorId': doctorId,
          'workDate': dateStr,
          'startTime': startTime,
          'endTime': endTime,
          'slotDurationMinutes': slotDuration,
          'isAvailable': true,
        });
      }
    }

    // Gửi song song tất cả các lịch trực bằng Future.wait
    if (payloads.isNotEmpty) {
      await Future.wait(payloads.map((payload) {
        return _apiClient.dio.post('/appointment/api/doctor-schedules', data: payload);
      }));
      await fetchSchedules();
      notifyListeners();
    }
  }

  // Patient CRUD
  Future<void> createPatient(Map<String, dynamic> payload) async {
    await _apiClient.dio.post('/medical/api/v1/medical/patients', data: payload);
    await fetchPatients();
    notifyListeners();
  }

  Future<void> updatePatient(int id, Map<String, dynamic> payload) async {
    await _apiClient.dio.put('/medical/api/v1/medical/patients/$id', data: payload);
    await fetchPatients();
    notifyListeners();
  }

  Future<void> deletePatient(int id) async {
    await _apiClient.dio.delete('/medical/api/v1/medical/patients/$id');
    await fetchPatients();
    notifyListeners();
  }

  // Appointment Actions
  Future<void> confirmAppointment(int id) async {
    await _apiClient.dio.put('/appointment/api/appointments/$id/confirm');
    await fetchAppointments();
    notifyListeners();
  }

  Future<void> cancelAppointment(int id, String reason) async {
    await _apiClient.dio.put(
      '/appointment/api/appointments/$id/cancel',
      queryParameters: reason.isNotEmpty ? {'reason': reason} : null,
    );
    await fetchAppointments();
    notifyListeners();
  }

  Future<void> checkInAppointment(Map<String, dynamic> apt) async {
    final int appointmentId = apt['appointmentId'] ?? apt['id'] ?? 0;
    
    // 1. Call Check-in in appointment service
    await _apiClient.dio.put('/appointment/api/appointments/$appointmentId/check-in');
    
    // 2. Call sync events to medical service (AC event)
    try {
      final scheduledAt = apt['appointmentDate'] != null 
          ? "${apt['appointmentDate'].toString().substring(0, 10)}T${apt['slotTime'] ?? '00:00'}:00Z"
          : DateTime.now().toUtc().toIso8601String();
          
      await _apiClient.dio.post('/medical/api/v1/medical/events/appointment-confirmed', data: {
        'eventId': 'AC$appointmentId',
        'eventType': 'appointment.confirmed',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'data': {
          'appointmentId': appointmentId,
          'patientName': apt['patientName'] ?? apt['patientNameSnapshot'] ?? '',
          'dateOfBirth': apt['dateOfBirth'] ?? null,
          'gender': apt['gender'] ?? null,
          'phoneNumber': apt['patientPhone'] ?? apt['patientPhoneSnapshot'] ?? apt['phoneNumber'] ?? apt['phone'] ?? null,
          'citizenId': apt['citizenId'] ?? null,
          'doctorId': apt['doctorId'] ?? 0,
          'doctorName': apt['doctorName'] ?? null,
          'specialtyId': apt['specialtyId'] ?? null,
          'specialtyName': apt['specialtyName'] ?? null,
          'reason': apt['reason'] ?? null,
          'scheduledAt': scheduledAt,
          'queueNumber': apt['queueNumber'] ?? null,
          'status': 'Confirmed',
        }
      });
    } catch (e) {
      debugPrint('Sync appointment confirmed event failed (optional): $e');
    }

    // 3. Call sync events for patient check-in to medical service (CI event)
    try {
      await _apiClient.dio.post('/medical/api/v1/medical/events/patient-checked-in', data: {
        'eventId': 'CI$appointmentId',
        'eventType': 'patient.checked_in',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'data': {
          'appointmentId': appointmentId,
          'doctorId': apt['doctorId'] ?? 0,
          'queueNumber': apt['queueNumber'] ?? null,
          'reason': apt['reason'] ?? null,
          'checkedInAt': DateTime.now().toUtc().toIso8601String(),
          'status': 'CheckedIn',
        }
      });
    } catch (e) {
      debugPrint('Sync patient checked-in event failed (optional): $e');
    }

    // Refresh appointments list
    await fetchAppointments();
    notifyListeners();
  }

  // Get medical visit by appointment ID
  Future<Map<String, dynamic>?> getVisitByAppointment(int appointmentId) async {
    try {
      final response = await _apiClient.dio.get('/medical/api/v1/medical/visits/by-appointment/$appointmentId');
      final data = ApiClient.readApiResponse(response.data);
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      debugPrint('Error getVisitByAppointment: $e');
    }
    return null;
  }

  // Update vitals/signs for a visit
  Future<void> updateVisitVitals(int visitId, Map<String, dynamic> payload) async {
    await _apiClient.dio.put('/medical/api/v1/medical/visits/$visitId/vitals', data: payload);
    await fetchAppointments();
    notifyListeners();
  }

  // Medicine CRUD
  Future<void> createMedicine(Map<String, dynamic> payload) async {
    await _apiClient.dio.post('/pharmacy/api/medicines', data: payload);
    await fetchMedicines();
    notifyListeners();
  }

  Future<void> updateMedicine(int id, Map<String, dynamic> payload) async {
    await _apiClient.dio.put('/pharmacy/api/medicines/$id', data: payload);
    await fetchMedicines();
    notifyListeners();
  }

  Future<void> deleteMedicine(int id) async {
    await _apiClient.dio.delete('/pharmacy/api/medicines/$id');
    await fetchMedicines();
    notifyListeners();
  }

  // Bills / Invoices Action
  Future<void> confirmPayment(int id) async {
    await _apiClient.dio.put('/pharmacy/api/billing/invoices/$id/pay');
    await fetchBills();
    notifyListeners();
  }

  // Accounts CRUD
  Future<void> createUser(Map<String, dynamic> payload) async {
    await _apiClient.dio.post('/pharmacy/api/auth/register', data: payload);
    await fetchAccounts();
    notifyListeners();
  }

  Future<void> updateUser(int id, Map<String, dynamic> payload) async {
    await _apiClient.dio.put('/pharmacy/api/auth/users/$id', data: payload);
    await fetchAccounts();
    notifyListeners();
  }

  Future<void> deleteUser(int id) async {
    await _apiClient.dio.delete('/pharmacy/api/auth/users/$id');
    await fetchAccounts();
    notifyListeners();
  }

  Future<void> lockUser(int id) async {
    await _apiClient.dio.put('/pharmacy/api/auth/users/$id/lock');
    await fetchAccounts();
    notifyListeners();
  }

  Future<void> unlockUser(int id) async {
    await _apiClient.dio.put('/pharmacy/api/auth/users/$id/unlock');
    await fetchAccounts();
    notifyListeners();
  }
}
