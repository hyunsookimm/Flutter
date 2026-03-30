import 'package:flutter/material.dart';
import 'package:navigation_widget/bottom_navigation/main_screen.dart';
import 'package:navigation_widget/routes/home_screen.dart';
import 'package:navigation_widget/routes/profile_screen.dart';
import 'package:navigation_widget/routes/settings_screen.dart';
import 'package:navigation_widget/screens/first_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // home: FirstScreen(),
      // 시작 경로
      initialRoute: '/main',
      // 라우팅 설정
      routes: {
        // '/경로'    : (context) => 화면위젯(),
        '/main'       : (context) => MainScreen(),
        '/home'       : (context) => HomeScreen(),
        '/profile'    : (context) => ProfileScreen(),
        '/setting'    : (context) => SettingsScreen(),
      },
    );
  }
}
