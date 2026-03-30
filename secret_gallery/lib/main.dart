import 'package:flutter/material.dart';

import 'pages/lock_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '시크릿 갤러리',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const LockPage(),
    );
  }
}
