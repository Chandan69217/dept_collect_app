import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/shared/splash_screen.dart';
import 'screens/shared/login_screen.dart';
import 'screens/agent/agent_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/agent/security_settings.dart';
import 'screens/admin/upload_data_screen.dart';
import 'services/shared_prefs_service.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPrefsService.init();
  
  // Try restoring saved session
  await DatabaseService().tryAutoLogin();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppTheme.appName,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/agent_dashboard': (context) => const AgentDashboard(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        '/security_settings': (context) => const SecuritySettingsScreen(),
        '/upload_data': (context) => const UploadDataScreen(),
      },
    );
  }
}
