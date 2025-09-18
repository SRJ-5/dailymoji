import 'package:dailymoji/presentation/pages/my/widgets/Ai_profile.dart';
import 'package:dailymoji/presentation/pages/my/widgets/diagnostic_test_box.dart';
import 'package:dailymoji/presentation/widgets/bottom_bar.dart';
import 'package:flutter/material.dart';

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 50),
            GestureDetector(
              onTap: () {
                // TODO: 닉네임 변경 페이지 또는 팝업 이동 만들기
                print('닉네임 변경 페이지 오픈');
              },
              child: Row(
                children: [
                  Text(
                    '닉네임',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.add_circle_outline_rounded,
                    size: 16,
                    color: Colors.blueAccent,
                  ),
                ],
              ),
            ),
            Text(' 님의 페이지'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: 설정 페이지 이동 만들기
              print('설정 페이지로 이동');
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView(
          children: [
            AiProfil(),
            SizedBox(height: 15),
            Container(
              height: 56,
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '튜토리얼',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            DiagnosticTestBox(),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(),
    );
  }
}
