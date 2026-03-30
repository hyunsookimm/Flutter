import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:input_widget/screens/home_screen.dart';

void main() {
  // SafeArea 초록색 테두리 제거
  debugPaintSizeEnabled = false;
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 디버그 리본 제거
      debugShowCheckedModeBanner: false,
      title: "입력 위젯",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: HomeScreen(),
    );
  }
}
