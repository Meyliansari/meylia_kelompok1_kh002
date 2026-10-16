import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'consultation_booking_screen.dart';
import 'consultation_history_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init warning: $e');
  }

  // Mode debug: OTP memakai nomor uji dari console Firebase
  if (kDebugMode) {
    try {
      await FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: true,
      );
    } catch (e) {
      debugPrint('Auth settings warning: $e');
    }
  }

  runApp(const RuangRancangApp());
}

class RuangRancangApp extends StatelessWidget {
  const RuangRancangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RuangRancang',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,

      // Menggunakan Rute Awal
      initialRoute: '/',

      // Mendaftarkan Rute Halaman agar URL di Web/Chrome berubah
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/booking': (context) {
          final uid = FirebaseAuth.instance.currentUser?.uid ?? 'user_guest';
          return ConsultationBookingScreen(userId: uid);
        },
        '/history': (context) {
          final uid = FirebaseAuth.instance.currentUser?.uid ?? 'user_guest';
          return ConsultationHistoryScreen(userId: uid);
        },
      },
    );
  }
}