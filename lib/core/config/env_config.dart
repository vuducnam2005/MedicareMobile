import 'dart:convert';

class EnvConfig {
  // Base URL của hệ thống gateway Medicare
  static const String baseUrl = 'https://api.hwpresents.site';

  // API Key Gemini (Mã hóa Base64)
  static String get geminiApiKey {
    final bytes = base64.decode('QVEuQWI4Uk42SVloNHBkRDdGVURESDZuV1c0VWp5ZF9mMWRKNEFZeFpRdnNpSlFSY1Roamc=');
    return utf8.decode(bytes);
  }
  static const String geminiModel = 'gemini-2.5-flash';

  // Cấu hình thanh toán qua VietQR / SePay ngân hàng
  static const String bankTransferBank = 'Techcombank';
  static const String bankTransferAccount = '20058888866666';
  static const String bankTransferAccountName = 'MedicareDNU';
  static const String bankTransferPrefix = 'MEDDNU';

  // Client ID từ Google Cloud Console (Dùng cho Google Sign-In)
  static const String googleClientId = '807372784575-sa6fcvhdh2fh6rcdj2sb3i6n0q6ilqeu.apps.googleusercontent.com'; // iOS Client ID
  static const String googleServerClientId = '807372784575-4efmnootusg8irvv4kai866gucskqh7v.apps.googleusercontent.com'; // Web Client ID / Server Client ID

  // Chế độ giả lập Google Login
  static const bool useMockGoogleLogin = false;
}
