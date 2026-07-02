import 'dart:convert';

class EnvConfig {
  // Base URL của hệ thống gateway Medicare
  static const String baseUrl = 'https://api.hwpresents.site';

  // API Key & Model dành cho Trợ lý AI Gemini (Dogky)
  static String get geminiApiKey {
    final bytes = base64.decode('QVEuQWI4Uk42SVloNHBkRDdGVURESDZuV1c0VWp5ZF9mMWRKNEFZeFpRdnNpSlFSY1Roamc=');
    return utf8.decode(bytes);
  }
  static const String geminiModel = 'gemini-2.5-flash';

  // Cấu hình thanh toán qua VietQR / SePay ngân hàng
  static const String bankTransferBank = 'Techcombank';
  static const String bankTransferAccount = '0362183511'; // Hoặc số tài khoản thực tế
  static const String bankTransferAccountName = 'MedicareDNU';
  static const String bankTransferPrefix = 'MEDDNU';

  // Client ID từ Google Cloud Console (Dùng cho Google Sign-In)
  static const String googleClientId = '807372784575-4efmnootusg8irvv4kai866gucskqh7v.apps.googleusercontent.com';

  // Chế độ giả lập Google Login
  static const bool useMockGoogleLogin = false;
}
