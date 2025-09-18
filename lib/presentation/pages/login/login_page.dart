import 'package:dailymoji/presentation/pages/login/dummy_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // TODO: test로 여기에 구현 test완료 후 클린아키텍쳐 구조로 변환해야함
  Future<bool> googleLogin() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        authScreenLaunchMode: LaunchMode.externalApplication,
        redirectTo: 'dailymoji://login-callback',
      );
      final user = Supabase.instance.client.auth.currentUser;
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // TODO: test로 여기에 구현 test완료 후 클린아키텍쳐 구조로 변환해야함
  Future<bool> appleLogin() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.apple,
          authScreenLaunchMode: LaunchMode.externalApplication,
          redirectTo: 'dailymoji://login-callback');
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 100),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 50,
                    child: Image.asset(
                      'assets/icons/dailymoji_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Text(
                    '매일매일 감정 관리',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 150,
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 80,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final result = await googleLogin();
                            if (result) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DummyPage(),
                                  ));
                            }
                          },
                          child: CircleAvatar(
                            radius: 30,
                            child: Image.asset(
                              'assets/icons/google_login_logo.png',
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final result = await appleLogin();
                            if (result) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DummyPage(),
                                  ));
                            }
                          },
                          child: CircleAvatar(
                            radius: 30,
                            child: Image.asset(
                              'assets/icons/apple_login_logo.png',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                RichText(
                  text: TextSpan(
                    text: '시작함으로써 ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: '이용약관',
                        style: TextStyle(
                          color: Colors.blueAccent,
                        ),
                      ),
                      TextSpan(text: '과 '),
                      TextSpan(
                        text: '개인정보 수집 및 이용',
                        style: TextStyle(
                          color: Colors.blueAccent,
                        ),
                      ),
                      TextSpan(text: '에 동의하게 됩니다.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(child: SizedBox(height: 50)),
        ],
      ),
    );
  }
}
