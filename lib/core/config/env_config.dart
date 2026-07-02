class EnvConfig {
  // Base URL của hệ thống gateway Medicare
  static const String baseUrl = 'https://api.hwpresents.site';

  // API Key & Model dành cho Trợ lý AI Gemini (Dogky)
  // Đọc từ Environment Variables qua --dart-define khi build trên Codemagic
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String geminiModel = 'gemini-2.5-flash';

  // Cấu hình thanh toán qua VietQR / SePay ngân hàng
  static const String bankTransferBank = 'Techcombank';
  static const String bankTransferAccount = '20058888866666';
  static const String bankTransferAccountName = 'MedicareDNU';
  static const String bankTransferPrefix = 'MEDDNU';

  // Client ID từ Google Cloud Console (Dùng cho Google Sign-In)
  // Đọc từ Environment Variables qua --dart-define khi build trên Codemagic
  static const String googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID',
    defaultValue: '807372784575-4efmnootusg8irvv4kai866gucskqh7v.apps.googleusercontent.com');

  // Chế độ giả lập Google Login
  static const bool useMockGoogleLogin = false;
}
