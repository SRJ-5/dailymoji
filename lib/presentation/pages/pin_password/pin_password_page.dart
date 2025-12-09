import 'package:dailymoji/presentation/pages/pin_password/widgets/password_change_modal.dart';
import 'package:flutter/material.dart';

class PinPasswordPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PasswordChangeModal(
        isChangePassword: false,
        isAuthenticated: false,
      ),
    );
  }
}
