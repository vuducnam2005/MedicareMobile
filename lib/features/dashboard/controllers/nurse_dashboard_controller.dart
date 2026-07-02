import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

class NurseDashboardController extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  // --- State ---
  List<dynamic> _appointments = [];
  List<dynamic> _patients = [];
  List<dynamic> _queue = [];
  List<dynamic> _bills = [];
  List<dynamic> _prescriptions = [];
  List<dynamic> _medicines = [];
  List<dynamic> _slips = [];

  bool _isLoading = false;
  String? _errorMessage;

  // --- Getters ---
  List<dynamic> get appointments => _appointments;
  List<dynamic> get patients => _patients;
  List<dynamic> get queue => _queue;
  List<dynamic> get queueVisits => _queue;
  List<dynamic> get bills => _bills;
  List<dynamic> get prescriptions => _prescriptions;
  List<dynamic> get medicines => _medicines;
  List<dynamic> get slips => _slips;
  List<dynamic> get stockSlips => _slips;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Helper bóc tách dữ liệu từ API (đồng bộ pattern với Admin controller)
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

  // ===== LOAD ALL DATA =====
  Future<void> loadDashboardData() => loadAllNurseData();

  Future<void> loadAllNurseData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        fetchAppointments(),
        fetchPatients(),
        fetchQueue(),
        fetchBills(),
        fetchPrescriptions(),
        fetchMedicines(),
        fetchSlips(),
      ]);
    } catch (e) {
      _errorMessage = 'Lỗi tải dữ liệu y tá: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===== FETCH METHODS =====

  Future<void> fetchAppointments() async {
    try {
      final response = await _apiClient.dio.get(
        '/appointment/api/appointments',
      );
      _appointments = _parseList(response.data);
    } catch (e) {
      debugPrint('Error fetchAppointments: $e');
      _appointments = [];
    }
  }

  Future<void> fetchPatients() async {
    try {
      final response = await _apiClient.dio.get(
        '/medical/api/v1/medical/patients',
        queryParameters: {'pageSize': 100},
      );
      _patients = _parseList(response.data);
    } catch (e) {
      debugPrint('Error fetchPatients: $e');
      _patients = [];
    }
  }

  Future<void> fetchQueue() async {
    try {
      final response = await _apiClient.dio.get(
        '/medical/api/v1/medical/visits/today',
      );
      _queue = _parseList(response.data);
    } catch (e) {
      debugPrint('Error fetchQueue from visits/today: $e');
      // Fallback to waiting-queue API
      try {
        final today = DateTime.now().toIso8601String().substring(0, 10);
        final response = await _apiClient.dio.get(
          '/appointment/api/waiting-queue',
          queryParameters: {'date': today},
        );
        _queue = _parseList(response.data);
      } catch (e2) {
        debugPrint('Error fetchQueue fallback: $e2');
        _queue = [];
      }
    }
  }

  Future<void> fetchBills() async {
    try {
      final response = await _apiClient.dio.get(
        '/pharmacy/api/billing/invoices',
      );
      _bills = _parseList(response.data);
    } catch (e) {
      debugPrint('Error fetchBills: $e');
      _bills = [];
    }
  }

  Future<void> fetchPrescriptions() async {
    try {
      final response = await _apiClient.dio.get('/pharmacy/api/prescriptions');
      _prescriptions = _parseList(response.data);
    } catch (e) {
      debugPrint('Error fetchPrescriptions primary: $e');
      try {
        final response = await _apiClient.dio.get(
          '/pharmacy/api/billing/prescriptions',
        );
        _prescriptions = _parseList(response.data);
      } catch (e2) {
        debugPrint('Error fetchPrescriptions fallback: $e2');
        _prescriptions = [];
      }
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

  Future<void> fetchSlips() async {
    try {
      final response = await _apiClient.dio.get(
        '/pharmacy/api/inventory/slips',
      );
      _slips = _parseList(response.data);
    } catch (e) {
      debugPrint('Error fetchSlips: $e');
      _slips = [];
    }
  }

  // ===== APPOINTMENT ACTIONS =====

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

    // 1. Check-in on Appointment service
    await _apiClient.dio.put(
      '/appointment/api/appointments/$appointmentId/check-in',
    );

    // 2. Sync "appointment.confirmed" event to Medical Service
    try {
      final scheduledAt = apt['appointmentDate'] != null
          ? "${apt['appointmentDate'].toString().substring(0, 10)}T${apt['slotTime'] ?? '00:00'}:00Z"
          : DateTime.now().toUtc().toIso8601String();

      await _apiClient.dio.post(
        '/medical/api/v1/medical/events/appointment-confirmed',
        data: {
          'eventId': 'AC$appointmentId',
          'eventType': 'appointment.confirmed',
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'data': {
            'appointmentId': appointmentId,
            'patientName':
                apt['patientName'] ?? apt['patientNameSnapshot'] ?? '',
            'dateOfBirth': apt['dateOfBirth'],
            'gender': apt['gender'],
            'phoneNumber':
                apt['patientPhone'] ??
                apt['patientPhoneSnapshot'] ??
                apt['phoneNumber'] ??
                apt['phone'],
            'citizenId': apt['citizenId'],
            'doctorId': apt['doctorId'] ?? 0,
            'doctorName': apt['doctorName'],
            'specialtyId': apt['specialtyId'],
            'specialtyName': apt['specialtyName'],
            'reason': apt['reason'],
            'scheduledAt': scheduledAt,
            'queueNumber': apt['queueNumber'],
            'status': 'Confirmed',
          },
        },
      );
    } catch (e) {
      debugPrint('Sync appointment confirmed event failed (optional): $e');
    }

    // 3. Sync "patient.checked_in" event to Medical Service
    try {
      await _apiClient.dio.post(
        '/medical/api/v1/medical/events/patient-checked-in',
        data: {
          'eventId': 'CI$appointmentId',
          'eventType': 'patient.checked_in',
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'data': {
            'appointmentId': appointmentId,
            'doctorId': apt['doctorId'] ?? 0,
            'queueNumber': apt['queueNumber'],
            'reason': apt['reason'],
            'checkedInAt': DateTime.now().toUtc().toIso8601String(),
            'status': 'CheckedIn',
          },
        },
      );
    } catch (e) {
      debugPrint('Sync patient checked-in event failed (optional): $e');
    }

    await fetchAppointments();
    notifyListeners();
  }

  // ===== PATIENT ACTIONS =====

  Future<void> createPatient(Map<String, dynamic> payload) async {
    await _apiClient.dio.post(
      '/medical/api/v1/medical/patients',
      data: payload,
    );
    await fetchPatients();
    notifyListeners();
  }

  Future<void> updatePatient(int id, Map<String, dynamic> payload) async {
    await _apiClient.dio.put(
      '/medical/api/v1/medical/patients/$id',
      data: payload,
    );
    await fetchPatients();
    notifyListeners();
  }

  // ===== QUEUE / VITALS ACTIONS =====

  Future<Map<String, dynamic>?> getVisitByAppointment(int appointmentId) async {
    try {
      final response = await _apiClient.dio.get(
        '/medical/api/v1/medical/visits/by-appointment/$appointmentId',
      );
      final data = ApiClient.readApiResponse(response.data);
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      debugPrint('Error getVisitByAppointment: $e');
    }
    return null;
  }

  Future<void> updateVisitVitals(
    int visitId,
    Map<String, dynamic> payload,
  ) async {
    await _apiClient.dio.put(
      '/medical/api/v1/medical/visits/$visitId/vitals',
      data: payload,
    );
    await fetchQueue();
    notifyListeners();
  }

  // ===== BILLING / INVOICE ACTIONS =====

  Future<void> confirmPayment(int id) async {
    try {
      await _apiClient.dio.post('/pharmacy/api/invoices/$id/pay', data: {});
    } catch (_) {
      try {
        await _apiClient.dio.post(
          '/pharmacy/api/billing/invoices/$id/pay',
          data: {},
        );
      } catch (_) {
        await _apiClient.dio.put('/pharmacy/api/billing/invoices/$id/pay');
      }
    }
    await fetchBills();
    notifyListeners();
  }

  Future<void> cancelInvoice(int id) async {
    try {
      await _apiClient.dio.put('/pharmacy/api/invoices/$id/cancel');
    } catch (_) {
      await _apiClient.dio.put('/pharmacy/api/billing/invoices/$id/cancel');
    }
    await fetchBills();
    notifyListeners();
  }

  // ===== PRESCRIPTION / DISPENSE ACTIONS =====

  Future<void> dispensePrescription(int id) async {
    // Try primary endpoint first, fallback to second
    try {
      await _apiClient.dio.post(
        '/pharmacy/api/prescriptions/$id/dispense',
        data: {},
      );
    } catch (e) {
      await _apiClient.dio.post(
        '/pharmacy/api/billing/prescriptions/$id/dispense',
        data: {},
      );
    }
    await fetchPrescriptions();
    notifyListeners();
  }

  Future<Map<String, dynamic>?> checkPrescriptionStock(int id) async {
    try {
      final response = await _apiClient.dio.get(
        '/pharmacy/api/prescriptions/$id/stock-check',
      );
      final data = ApiClient.readApiResponse(response.data);
      if (data is Map) return Map<String, dynamic>.from(data);
    } catch (e) {
      debugPrint('Error checkPrescriptionStock primary: $e');
      try {
        final response = await _apiClient.dio.get(
          '/pharmacy/api/billing/prescriptions/$id/stock-check',
        );
        final data = ApiClient.readApiResponse(response.data);
        if (data is Map) return Map<String, dynamic>.from(data);
      } catch (e2) {
        debugPrint('Error checkPrescriptionStock fallback: $e2');
      }
    }
    return null;
  }

  // ===== INVENTORY SLIPS ACTIONS =====

  Future<void> createSlip(Map<String, dynamic> payload) async {
    await _apiClient.dio.post('/pharmacy/api/inventory/slips', data: payload);
    await fetchSlips();
    notifyListeners();
  }

  Future<void> voidSlip(int id) async {
    await _apiClient.dio.post(
      '/pharmacy/api/inventory/slips/$id/void',
      data: {},
    );
    await fetchSlips();
    notifyListeners();
  }
}
