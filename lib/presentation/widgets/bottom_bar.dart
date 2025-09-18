import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: Colors.grey[200],
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(40),
                    onTap: () {
                      context.push('/chat');
                    },
                    child: BottomBarIcon(title: 'Home'),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(40),
                    onTap: () {},
                    child: BottomBarIcon(title: 'Report'),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(40),
                    onTap: () {},
                    child: BottomBarIcon(title: 'My Page'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//TODO: 바텀에 사용될 아이콘이 정해지면 회색박스 대신 넣어야함
class BottomBarIcon extends StatelessWidget {
  final String title;
  const BottomBarIcon({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Container(
              width: 28,
              height: 28,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 5),
          Text(title),
        ],
      ),
    );
  }
}

// context.push('/next');
