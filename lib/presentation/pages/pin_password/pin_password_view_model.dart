import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinPasswordState {
  String pinNum;
  bool isPasswordEnabled;

  PinPasswordState(
      {required this.pinNum, required this.isPasswordEnabled});

  PinPasswordState copyWith(
      {String? pinNum, bool? isPasswordEnabled}) {
    return PinPasswordState(
        pinNum: pinNum ?? this.pinNum,
        isPasswordEnabled:
            isPasswordEnabled ?? this.isPasswordEnabled);
  }
}

class PinPasswordViewModel extends Notifier<PinPasswordState> {
  String passwordList = '';
  final secureStorage = const FlutterSecureStorage(
      iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock));

  @override
  PinPasswordState build() {
    return PinPasswordState(
        pinNum: '', isPasswordEnabled: false);
  }

  // pin암호 설정을 했는지 안했는지 확인
  Future<void> hasPin() async {
    try {
      final savedPin =
          await secureStorage.read(key: 'pinPassWord');
      final result = savedPin != null; // 있으면 true, 없으면 false

      state = state.copyWith(isPasswordEnabled: result);
      print("🔐 PIN 존재 여부: $result");
    } catch (e) {
      print("hasPin error: $e");
    }
  }

  // pin 암호 입력시 처리
  Future<bool?> selectedPinNum({
    required String password,
    required bool isChangePin,
  }) async {
    if (passwordList.length < 4) {
      passwordList += password;
      state = state.copyWith(pinNum: passwordList);

      print("입력 PIN: ${state.pinNum}");

      if (state.pinNum.length == 4) {
        return isChangePin ? savePinNum() : checkPinNum();
      }
      return null;
    }
  }

  // pin 암호가 맞는지 확인
  Future<bool> checkPinNum() async {
    try {
      final savedPassword =
          await secureStorage.read(key: 'pinPassWord');

      final isMatch =
          savedPassword != null && savedPassword == state.pinNum;

      print("🔍 PIN 확인 결과: $isMatch");
      return isMatch;
    } catch (e) {
      print("checkPinNum error: $e");
      return false;
    }
  }

  // pin 암호 내부에 저장하기
  Future<bool> savePinNum() async {
    try {
      await secureStorage.write(
        key: 'pinPassWord',
        value: state.pinNum,
      );

      // 저장 성공했으면 상태 업데이트
      state = state.copyWith(isPasswordEnabled: true);
      return true;
    } catch (e) {
      print('SecureStorage save error: $e');
      return false;
    }
  }

  // 암호 사용 안함
  Future<bool> deletePinNum() async {
    try {
      await secureStorage.delete(key: 'pinPassWord');

      state = state.copyWith(isPasswordEnabled: false);

      print("PIN 삭제됨");
      return true;
    } catch (e) {
      print("deletePinNum error: $e");
      return false;
    }
  }

  // 입력된 pin 암호 전부 지우기
  void clearAllPinNum() {
    passwordList = '';
    state = state.copyWith(pinNum: passwordList);
  }

  // 입력된 pin 암호 마지막 하나 지우기
  void clearPinNum() {
    if (passwordList.isNotEmpty) {
      passwordList =
          passwordList.substring(0, passwordList.length - 1);
      state = state.copyWith(pinNum: passwordList);
      print(state.pinNum);
    }
  }
}

final pinPasswordViewModelProvider =
    NotifierProvider<PinPasswordViewModel, PinPasswordState>(() {
  return PinPasswordViewModel();
});
