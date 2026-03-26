import 'dart:math';

import 'package:flutter/material.dart';

// 프로그램 시작점
void main() {
  runApp(const MyApp());
}

// stf : StatefulWidget
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // 🧊 state
  String _menu = '점메추';
  final _menuList = ['짜장면','짬뽕','닭갈비','돈까스','햄버거'];

  void _random() {
    final r = Random().nextInt(_menuList.length);
    // State Update
    setState(() {
      _menu = _menuList[r];
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {}, 
            icon: const Icon(Icons.menu)
          ),
          title: const Text('점메추 앱'),
          actions: [
            IconButton(
              onPressed: () {}, 
              icon: Icon(Icons.more_vert)
              )
          ],
        ),
        body: Center(
          child: Text(
            _menu,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _random();
          },
          child: const Icon(Icons.restaurant),
        ),
      )
    );
  }
}

// stl : StatelessWidget
// class MyApp extends StatelessWidget {
//   // 생성자
//   const MyApp({super.key});

//   // UI
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(
//         appBar: AppBar(
//           leading: IconButton(
//             onPressed: () {}, 
//             icon: const Icon(Icons.menu)
//           ),
//           title: const Text("My App"),
//           actions: [
//             IconButton(
//               onPressed: () {}, 
//               icon: Icon(Icons.more_vert)
//             )
//           ],
//         ),
//         body: const Center(
//           child: Text("Hello World!"),
//         ),
//         bottomNavigationBar: BottomNavigationBar(
//           items: [
//             BottomNavigationBarItem(
//               icon: Icon(Icons.home),
//               label: 'Home'
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.shopping_bag),
//               label: 'Cart'
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.settings),
//               label: 'Settings'
//             ),
//           ]
//         ),
//       ),
//     );
//   }
// }



// - 초기 코드
// // stl : StatelessWidget
// class MyApp extends StatelessWidget {
//   // 생성자
//   const MyApp({super.key});

//   // build 메소드
//   // : 출력할 위젯을 반환하는 메소드
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         colorScheme: .fromSeed(seedColor: Colors.deepPurple),
//       ),
//       home: const MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }

// // stf : StatefulWidget
// class MyHomePage extends StatefulWidget {
//   // 생성자
//   const MyHomePage({super.key, required this.title});

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   // 🧊 state
//   int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       _counter++;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         title: Text(widget.title),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: .center,
//           children: [
//             const Text('You have pushed the button this many times:'),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }
