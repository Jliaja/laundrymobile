import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register.dart';
import 'screens/dashboard.dart';
import 'screens/forgot.dart';
import 'screens/order.dart';
import 'screens/profile.dart';
import 'screens/confirmorder.dart';
import 'screens/edit_profile.dart';
import 'screens/verifikasiotp.dart';
import 'package:laundry_mobile/config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // wajib untuk async init sebelum runApp
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Laundry App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/profile': (context) => const ProfilePage(),
        '/forgot': (context) => const ForgotPasswordScreen(),
        '/order': (context) => OrderScreen(username: "User"),
        '/confirmorder': (context) => const ConfirmOrderScreen(),
      },
      // Untuk navigasi OTP kita pakai MaterialPageRoute langsung di screen, tidak perlu route statis
      onGenerateRoute: (settings) {
        if (settings.name == '/verify-otp') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => VerifikasiOtpScreen(
              email: args['email'],
              purpose: args['purpose'],
              onVerified: args['onVerified'],
            ),
          );
        }
        return null;
      },
    );
  }
}
