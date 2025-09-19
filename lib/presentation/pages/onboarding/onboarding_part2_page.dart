import 'package:dailymoji/presentation/pages/onboarding/onboarding_part1_page.dart';
import 'package:flutter/material.dart';

class OnboardingPart2Page extends StatefulWidget {
  @override
  State<OnboardingPart2Page> createState() =>
      _OnboardingPart2PageState();
}

class _OnboardingPart2PageState
    extends State<OnboardingPart2Page> {
  int stepIndex = 0;
  int totalSteps = 9;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: stepIndex > 0
            ? IconButton(
                onPressed: () {
                  setState(() => stepIndex--);
                },
                icon: Icon(Icons.arrow_back))
            : null,
        title: Text('사용자 설정'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TopIndicator(
                totalSteps: totalSteps,
                stepIndex: stepIndex), // indicator 맨 위
            SizedBox(height: 20),
            Expanded(
              child: [
                Center(
                  child: Text('1'),
                ),
                Center(
                  child: Text('2'),
                ),
                Center(
                  child: Text('3'),
                ),
                Center(
                  child: Text('4'),
                ),
                Center(
                  child: Text('5'),
                ),
                Center(
                  child: Text('6'),
                ),
                Center(
                  child: Text('7'),
                ),
                Center(
                  child: Text('8'),
                ),
                Center(
                  child: Text('9'),
                ),
                Center(
                  child: Text('10'),
                ),
              ][stepIndex],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: SizedBox(
          width: 100,
          height: 100,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (stepIndex < totalSteps) {
                      setState(() {
                        stepIndex++;
                      });
                    } else if (stepIndex == totalSteps) {
                      // TODO: go router로 교체 해야함, 페이지 연결하고 진행
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                OnboardingPart1Page()),
                      );
                    }
                  },
                  child: stepIndex == totalSteps
                      ? Text('완료')
                      : Text('다음'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
