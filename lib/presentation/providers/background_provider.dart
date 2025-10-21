import 'package:dailymoji/core/styles/images.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ✅ 배경 이미지 경로를 관리하는 Provider (SharedPreferences 연동)
final backgroundImageProvider =
    StateNotifierProvider<BackgroundImageNotifier, String>((ref) {
  return BackgroundImageNotifier();
});

class BackgroundImageNotifier extends StateNotifier<String> {
  BackgroundImageNotifier() : super(AppImages.bgHouse) {
    _loadBackground(); // 앱 시작 시 저장된 배경 불러오기
  }

  /// SharedPreferences에서 마지막으로 선택한 배경 불러오기
  Future<void> _loadBackground() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selectedBackground');
    if (saved != null) {
      state = saved;
    }
  }

  /// 배경 변경 + 저장
  Future<void> setBackground(String newPath) async {
    state = newPath;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedBackground', newPath);
  }
}
