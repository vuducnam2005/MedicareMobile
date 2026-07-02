import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

import '../config/env_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  // Giải mã Envelope Pattern từ API (bóc tách {success: true, data: ...})
  static dynamic readApiResponse(dynamic responseData) {
    if (responseData is Map && responseData.containsKey('success') && responseData.containsKey('data')) {
      if (responseData['success'] == false) {
        throw Exception(responseData['message'] ?? 'API request failed');
      }
      return responseData['data'];
    }
    return responseData;
  }

  // Cấu hình Base URL tự động nhận diện máy ảo Android vs iOS/Web
  static String get baseUrl {
    return EnvConfig.baseUrl;
  }

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Thêm Interceptor để tự động đính kèm Access Token vào Header mỗi khi gọi API
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Xử lý khi Token hết hạn (401 Unauthorized)
          if (e.response?.statusCode == 401) {
            await SecureStorage.clearAll();
          }
          return handler.next(e);
        },
      ),
    );
  }
}
