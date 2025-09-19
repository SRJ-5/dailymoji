import 'package:dailymoji/presentation/pages/onboarding/widgets/AiNameSetting.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/SelectAi.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/SelectAiPersonality.dart';
import 'package:dailymoji/presentation/pages/onboarding/onboarding_part2_page.dart';
import 'package:flutter/material.dart';

class OnboardingPart1Page extends StatefulWidget {
  @override
  State<OnboardingPart1Page> createState() =>
      _OnboardingPart1PageState();
}

class _OnboardingPart1PageState
    extends State<OnboardingPart1Page> {
  int stepIndex = 0;
  int totalSteps = 2;

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
        title: Text('도우미 설정'),
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
                SelectAi(),
                AiNameSetting(),
                SelectAiPersonality(),
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
                                OnboardingPart2Page()),
                      );
                    }
                  },
                  child: Text('다음'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TopIndicator extends StatelessWidget {
  const TopIndicator({
    super.key,
    required this.totalSteps,
    required this.stepIndex,
  });

  final int totalSteps;
  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps + 1, (index) {
        bool isActive = index <= stepIndex; // 현재 단계까지는 ●
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isActive ? Colors.amber : Colors.grey.shade300,
            ),
          ),
        );
      }),
    );
  }
}
