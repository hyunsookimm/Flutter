import 'package:flutter/material.dart';
import 'package:navigation_widget/models/profile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("홈 화면"),),
      body: Center(
        child:  
          Text("홈 화면", style: TextStyle(fontSize: 32),),
      ),
      bottomSheet: Container(
        padding: EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 프로필 버튼
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // ⭐ 화면 이동하며 데이터 전달하기
                  // * arguments : 전달할 데이터 지정

                  Profile profile = Profile(
                    id: "aloha1004", 
                    name: "알로하천사",
                    email: "aloha1004@naver.com"
                  );

                  // 라우팅 경로로 화면 이동
                  Navigator.pushNamed(context, "/profile",
                    arguments: profile
                  );
                }, 
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)
                  ),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white
                ),
                child: Text("프로필", style: TextStyle(fontSize: 20.0)),
              ),
            ),
            SizedBox(width: 20,),
            // 설정 버튼
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // 라우팅 경로로 화면 이동
                  Navigator.pushNamed(
                    context, "/setting",
                    arguments: {
                      "id"          : 'ALOHACLASS',
                      "name"        : 'Aloha',
                      "content"     : 'Aloha, World~!'
                    }
                  );
                }, 
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)
                  ),
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white
                ),
                child: Text("설정", style: TextStyle(fontSize: 20.0))
              ),
            ),
          ],
        ),
      ),
    );
  }
}