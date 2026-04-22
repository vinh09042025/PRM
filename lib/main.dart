import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
 import 'firebase_options.dart';
 // Bạn cần chạy 'flutterfire configure' để có file này
import 'providers/theme_provider.dart';
import 'providers/deck_provider.dart';
import 'providers/auth_provider.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  // Đảm bảo các widget được khởi tạo trước khi chạy ứng dụng
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Notification Service
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();
  await notificationService.scheduleDailyStudyReminder();

  // Khởi tạo Database cho Windows/Linux
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Khởi tạo Firebase
  // LƯU Ý: Nếu chưa có firebase_options.dart, hãy chạy: flutterfire configure
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, 
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, DeckProvider>(
          create: (_) => DeckProvider(),
          update: (_, auth, deck) => deck!..updateService(auth.uid),
        ),
      ],
      child: const WordSprintApp(),
    ),
  );
}

class WordSprintApp extends StatelessWidget {
  const WordSprintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        const primaryIndigo = Color(0xFF4255FF);

        return MaterialApp(
          title: 'WordSprint',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          
          // Light Theme Design
          theme: ThemeData(
            useMaterial3: true,
            textTheme: GoogleFonts.lexendTextTheme(),
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryIndigo,
              primary: primaryIndigo,
              surface: const Color(0xFFF6F7FB),
              surfaceContainer: Colors.white,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF6F7FB),
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFFF6F7FB),
              elevation: 0,
              centerTitle: true,
              titleTextStyle: GoogleFonts.lexend(
                color: const Color(0xFF1A1D23),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: const IconThemeData(color: Color(0xFF1A1D23)),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryIndigo,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          // Dark Theme Design (Midnight Blue Premium)
          darkTheme: ThemeData(
            useMaterial3: true,
            textTheme: GoogleFonts.lexendTextTheme(ThemeData.dark().textTheme),
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryIndigo,
              primary: const Color(0xFF5D6DFF),
              surface: const Color(0xFF0A0B1E),
              surfaceContainer: const Color(0xFF161832),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0A0B1E),
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF0A0B1E),
              elevation: 0,
              centerTitle: true,
              titleTextStyle: GoogleFonts.lexend(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF161832),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF242747)),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D6DFF),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          
          home: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isLoading) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return authProvider.isAuthenticated ? const HomeScreen() : const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
