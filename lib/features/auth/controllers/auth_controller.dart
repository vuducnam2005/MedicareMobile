import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/config/env_config.dart';
import '../models/user_model.dart';

class AuthController extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isCheckingAuth = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isCheckingAuth => _isCheckingAuth;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // Kiểm tra trạng thái đăng nhập khi mở app
  Future<void> checkLoginStatus() async {
    _isCheckingAuth = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await SecureStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        final response = await _apiClient.dio.get('/pharmacy/api/auth/profile');
        if (response.statusCode == 200 && response.data != null) {
          final rawUser = UserModel.fromJson(response.data);
          _currentUser = await _enrichDoctorProfileIfNeeded(rawUser);
        } else {
          await SecureStorage.clearAll();
          _currentUser = null;
        }
      } else {
        _currentUser = null;
      }
    } catch (e) {
      await SecureStorage.clearAll();
      _currentUser = null;
    } finally {
      _isCheckingAuth = false;
      notifyListeners();
    }
  }

  // Đăng nhập tài khoản
  Future<bool> login(String usernameOrEmail, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        '/pharmacy/api/auth/login',
        data: {
          'emailOrUsername': usernameOrEmail,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final token = response.data['token'];
        final userData = response.data['user'];

        if (token != null) {
          await SecureStorage.saveAccessToken(token);
          final rawUser = UserModel.fromJson(userData);
          _currentUser = await _enrichDoctorProfileIfNeeded(rawUser);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _errorMessage = 'Đăng nhập thất bại. Không nhận được mã xác thực.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = _getDioErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra lỗi ngoài ý muốn: $e';
      notifyListeners();
      return false;
    }
  }

  // Đăng nhập bằng Google
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (EnvConfig.useMockGoogleLogin) {
      try {
        // Giả lập giao diện kết nối Google 1 giây
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Đăng nhập bằng tài khoản test thật để lấy JWT Token thật từ database
        final success = await login('vuducnam123456788', 'Patient@123');
        if (!success) {
          // Thử tài khoản patient mặc định khác nếu tài khoản trên không tồn tại
          final retrySuccess = await login('patient', 'Patient@123');
          if (!retrySuccess) {
            _isLoading = false;
            _errorMessage = 'Giả lập đăng nhập thất bại. Tài khoản test không hợp lệ.';
            notifyListeners();
            return false;
          }
          return retrySuccess;
        }
        return success;
      } catch (e) {
        _isLoading = false;
        _errorMessage = 'Lỗi kết nối giả lập Google: $e';
        notifyListeners();
        return false;
      }
    }

    try {
      // 1. Khởi tạo Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: EnvConfig.googleClientId,
        serverClientId: EnvConfig.googleClientId,
        scopes: ['email', 'profile'],
      );

      // Đăng xuất trước để luôn hiển thị bảng chọn tài khoản
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      // 2. Kích hoạt giao diện chọn tài khoản Google native
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // Người dùng hủy bỏ chọn tài khoản
        _isLoading = false;
        _errorMessage = 'Đăng nhập Google bị hủy.';
        notifyListeners();
        return false;
      }

      // 3. Lấy thông tin xác thực bao gồm idToken
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        _isLoading = false;
        _errorMessage = 'Không thể lấy ID Token từ Google.';
        notifyListeners();
        return false;
      }

      // 4. Gửi token lên backend Medicare
      final response = await _apiClient.dio.post(
        '/pharmacy/api/auth/google-login',
        data: {
          'idToken': idToken,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final token = response.data['token'];
        final userData = response.data['user'];

        if (token != null) {
          await SecureStorage.saveAccessToken(token);
          final rawUser = UserModel.fromJson(userData);
          _currentUser = await _enrichDoctorProfileIfNeeded(rawUser);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _errorMessage = 'Đăng nhập Google thất bại.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = _getDioErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi Google Login: $e';
      notifyListeners();
      return false;
    }
  }

  // Đăng ký tài khoản
  Future<bool> register({
    required String fullName,
    required String email,
    String? phoneNumber,
    String? username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        '/pharmacy/api/auth/register',
        data: {
          'fullName': fullName,
          'email': email,
          'phoneNumber': phoneNumber,
          'username': username,
          'password': password,
          'role': 'Patient', // Mặc định đăng ký trên Mobile là Patient
        },
      );

      _isLoading = false;
      notifyListeners();
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = _getDioErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi đăng ký: $e';
      notifyListeners();
      return false;
    }
  }

  // Yêu cầu khôi phục mật khẩu (Gửi OTP)
  Future<bool> initiateResetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        '/pharmacy/api/auth/forgot-password/initiate',
        data: {
          'email': email,
        },
      );
      _isLoading = false;
      notifyListeners();
      return response.statusCode == 200;
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = _getDioErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Xác thực mã OTP
  Future<String?> verifyOtp(String email, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        '/pharmacy/api/auth/forgot-password/verify-otp',
        data: {
          'email': email,
          'otpCode': otp,
        },
      );
      _isLoading = false;
      notifyListeners();
      if (response.statusCode == 200 && response.data != null) {
        return response.data['resetToken'];
      }
      return null;
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = _getDioErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  // Đặt lại mật khẩu mới
  Future<bool> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        '/pharmacy/api/auth/forgot-password/reset',
        data: {
          'resetToken': resetToken,
          'newPassword': newPassword,
        },
      );
      _isLoading = false;
      notifyListeners();
      return response.statusCode == 200;
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = _getDioErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Thay đổi mật khẩu khi đã đăng nhập
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.put(
        '/pharmacy/api/auth/profile/password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': newPassword,
        },
      );
      _isLoading = false;
      notifyListeners();
      return response.statusCode == 200;
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = _getDioErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await SecureStorage.clearAll();
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getDioErrorMessage(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map) {
        return data['message'] ?? data['Message'] ?? 'Đã xảy ra lỗi hệ thống.';
      }
    }
    return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng.';
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Lấy chi tiết hồ sơ bác sĩ từ dịch vụ Cuộc hẹn (N1) nếu đăng nhập với vai trò Doctor
  Future<UserModel> _enrichDoctorProfileIfNeeded(UserModel user) async {
    if (user.role == 'Doctor') {
      int? doctorId = user.doctorId;
      String? specialtyName = user.specialtyName;
      String? avatarUrl = user.avatarUrl;

      // 1. Thử gọi API by-user trước
      if (doctorId == null || avatarUrl == null) {
        try {
          final response = await _apiClient.dio.get('/appointment/api/doctors/by-user/${user.userId}');
          if (response.statusCode == 200 && response.data != null) {
            final docData = response.data;
            doctorId = docData['doctorId'] ?? docData['id'];
            specialtyName = docData['specialtyName'];
            avatarUrl = docData['avatarUrl'] ?? docData['AvatarUrl'];
          }
        } catch (e) {
          debugPrint('Không tìm thấy liên kết bác sĩ theo userId từ N1, thử khớp theo tên...');
        }
      }

      // 2. Nếu không tìm thấy, tải danh sách tất cả bác sĩ và khớp theo tên
      if (doctorId == null || avatarUrl == null) {
        try {
          final response = await _apiClient.dio.get('/appointment/api/doctors');
          if (response.statusCode == 200 && response.data != null) {
            final List<dynamic> doctors = response.data is List
                ? response.data
                : response.data['data'] is List
                    ? response.data['data']
                    : [];
            
            final match = doctors.firstWhere(
              (doc) => _normalizeDoctorName(doc['doctorName'] ?? doc['fullName'] ?? '') == _normalizeDoctorName(user.fullName),
              orElse: () => null,
            );

            if (match != null) {
              doctorId = match['doctorId'] ?? match['id'];
              specialtyName = match['specialtyName'];
              avatarUrl = match['avatarUrl'] ?? match['AvatarUrl'];
              debugPrint('Đã tìm thấy bác sĩ khớp tên từ N1: $doctorId - $specialtyName');
            }
          }
        } catch (e) {
          debugPrint('Lỗi tải danh sách bác sĩ để khớp tên từ N1: $e');
        }
      }

      return UserModel(
        userId: user.userId,
        fullName: user.fullName,
        email: user.email,
        username: user.username,
        phoneNumber: user.phoneNumber,
        patientId: user.patientId,
        doctorId: doctorId ?? user.doctorId,
        specialtyName: specialtyName ?? user.specialtyName,
        avatarUrl: avatarUrl,
        role: user.role,
        status: user.status,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
      );
    }
    return user;
  }

  String _normalizeDoctorName(String name) {
    return name.toLowerCase()
        .replaceAll(RegExp(r'^(bs\.|bs|bác sĩ)\s*'), '')
        .trim();
  }
}
