import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinPasswordState {
  String pinNum;

  PinPasswordState({required this.pinNum});

  PinPasswordState copyWith({String? pinNum}) {
    return PinPasswordState(pinNum: pinNum ?? this.pinNum);
  }
}

class PinPasswordViewModel extends Notifier<PinPasswordState> {
  String passwordList = '';

  @override
  PinPasswordState build() {
    return PinPasswordState(pinNum: '');
  }

  Future<bool?> selectedPinNum(
      {required String password,
      required bool isChangePin}) async {
    if (passwordList.length < 4) {
      passwordList += password;
      state = state.copyWith(pinNum: passwordList);
      print(state.pinNum);
      if (state.pinNum.length == 4) {
        return isChangePin ? savePinNum() : checkPinNum();
      }
    }
    return null;
  }

  // pin 암호가 맞는지 확인
  Future<bool> checkPinNum() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString('pinPassWord');
    bool isMatch =
        savedPassword != null && savedPassword == state.pinNum;
    return isMatch;
  }

  // pin 암호 내부에 저장하기
  Future<bool> savePinNum() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isSavedPassword =
        await prefs.setString('pinPassWord', state.pinNum);
    return isSavedPassword;
  }

  // 암호 사용 안함
  Future<bool> deletePinNum() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isDeletePassword =
        await prefs.remove('pinPassWord');
    return isDeletePassword;
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
