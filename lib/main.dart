import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/views/login_view.dart';
import 'features/dashboard/views/dashboard_view.dart';
import 'features/dashboard/controllers/patient_dashboard_controller.dart';
import 'features/dashboard/views/patient_dashboard_view.dart';
import 'features/appointment/controllers/booking_controller.dart';
import 'features/dashboard/controllers/doctor_dashboard_controller.dart';
import 'features/dashboard/views/doctor_dashboard_view.dart';
import 'features/dashboard/controllers/admin_dashboard_controller.dart';
import 'features/dashboard/views/admin_dashboard_view.dart';
import 'features/dashboard/controllers/nurse_dashboard_controller.dart';
import 'features/dashboard/views/nurse_dashboard_view.dart';
import 'features/dashboard/controllers/notification_controller.dart';
import 'features/dashboard/controllers/ai_assistant_controller.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => PatientDashboardController()),
        ChangeNotifierProvider(create: (_) => BookingController()),
        ChangeNotifierProvider(create: (_) => DoctorDashboardController()),
        ChangeNotifierProvider(create: (_) => AdminDashboardController()),
        ChangeNotifierProvider(create: (_) => NurseDashboardController()),
        ChangeNotifierProvider(create: (_) => NotificationController()),
        ChangeNotifierProvider(create: (_) => AiAssistantController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medicare Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F56B3),
          primary: const Color(0xFF0F56B3),
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Kiểm tra trạng thái đăng nhập ngay khi ứng dụng khởi chạy
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthController>().checkLoginStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    // Nếu đang kiểm tra trạng thái token ban đầu
    if (authController.isCheckingAuth) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang kết nối đến hệ thống...'),
            ],
          ),
        ),
      );
    }

    // Nếu đã đăng nhập thành công
    if (authController.isAuthenticated) {
      final role = authController.currentUser?.role;
      if (role == 'Patient') {
        return const PatientDashboardView();
      } else if (role == 'Doctor') {
        return const DoctorDashboardView();
      } else if (role == 'Admin') {
        return const AdminDashboardView();
      } else if (role == 'Nurse') {
        return const NurseDashboardView();
      }
      return const DashboardView();
    }

    // Nếu chưa đăng nhập hoặc token hết hạn
    return const LoginView();
  }
}
