import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

// TODO: test로 여기에 구현 test완료 후 클린아키텍쳐 구조로 변환해야함
class _LoginPageState extends State<LoginPage> {
  Future<void> googleLogin() async {
    // final google = GoogleSignIn();
    // final result = await google.signIn();
    // final auth = await result?.authentication;
    // print('auth: $auth');
    // print('accessToken: ${auth?.accessToken}');
    // print('idToken: ${auth?.idToken}');
    // final response = await Supabase.instance.client.auth
    //     .signInWithIdToken(
    //         provider: OAuthProvider.google,
    //         idToken: auth!.idToken!);
    // print('user: ${response.user}');

    final response = await Supabase.instance.client.auth
        .signInWithOAuth(OAuthProvider.google,
            redirectTo: 'dailymoji://login-callback');
    final user = Supabase.instance.client.auth.currentUser;
    print('user: ${user?.email}');
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
                  Text(
                    'DailyMoji',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 44,
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
                          onTap: () {
                            googleLogin();
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
                          onTap: () {
                            print('애플 로그인 실행');
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
