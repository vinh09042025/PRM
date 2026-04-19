import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/deck_provider.dart';
import 'screens/home_screen.dart';

void main() {
  // Đảm bảo các widget được khởi tạo trước khi chạy ứng dụng
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Database cho Windows/Linux
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeckProvider()),
      ],
      child: const WordSprintApp(),
    ),
  );
}

class WordSprintApp extends StatelessWidget {
  const WordSprintApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Định nghĩa màu chủ đạo #7F77DD
    const primaryColor = Color(0xFF7F77DD);

    return MaterialApp(
      title: 'WordSprint',
      debugShowCheckedModeBanner: false,
      
      // Cấu hình Theme Material 3
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          brightness: Brightness.light,
        ),
        
        // Cấu hình font chữ và giao diện chung
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        // Bo góc cho các Card và Button
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      
      // Màn hình chính
      home: const HomeScreen(),
    );
  }
}
