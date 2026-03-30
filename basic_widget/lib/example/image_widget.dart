import 'package:flutter/material.dart';

class ImageWidget extends StatelessWidget {
  const ImageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 50,),
            const Text(
              "네트워크 이미지",
              style: TextStyle(fontSize: 30),
            ),
            const SizedBox(height: 10,),
            Image.network(
              'https://i.imgur.com/fzADqJo.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 50,),
            const Text(
              "로컬 이미지",
              style: TextStyle(fontSize: 30),
            ),
            const SizedBox(height: 10,),
            const Image(
              image: AssetImage("image/logo.png"),
              width: 100,
              height: 100,
            )
          ],
        ),
      ),
    );
  }
}