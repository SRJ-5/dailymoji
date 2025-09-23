import 'dart:async';

import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // Stream을 구독하고 나중에 취소하기 위한 변수
  late final StreamSubscription<AuthState> _authSubscription;

  // onAuthStateChange를 로그인페이지가 아닌 전페이지 즉, 스플레쉬 페이지에서
  @override
  void initState() {
    super.initState();

    // Supabase 클라이언트에 쉽게 접근하기 위해 변수 선언
    final supabase = Supabase.instance.client;

    // initState에서 단 한 번만 onAuthStateChange 스트림을 구독 시작
    _authSubscription =
        supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final event = data.event;

      if (event == AuthChangeEvent.signedIn && session != null) {
        if (mounted) {
          final userId = supabase.auth.currentUser;
          ref
              .read(userViewModelProvider.notifier)
              .insertUserId(userId!.id);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.go('/onboarding1');
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    // 페이지가 사라질 때 리스너를 반드시 취소하여 메모리 누수 방지
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // auth.onAuthStateChange.listen(
    //   (event) {
    //     if (event.session != null) {
    //       final userId = auth.currentUser!.id;
    //       ref.read(userViewModelProvider);
    //       context.go('/onboarding1');
    //     }
    //   },
    // );
    return Scaffold(
      backgroundColor: AppColors.yellow50,
      body: Column(
        children: [
          SizedBox(height: 110.h),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 47.44.h,
                    child: Image.asset(
                      'assets/icons/dailymoji_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(
                    height: 5.h,
                  ),
                  Text(
                    '매일매일 감정 관리',
                    style: AppFontStyles.bodyRegular18
                        .copyWith(color: AppColors.grey400),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 150.h,
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 75.w,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            await ref
                                .read(userViewModelProvider
                                    .notifier)
                                .googleLogin();
                          },
                          child: CircleAvatar(
                            radius: 30.r,
                            child: Image.asset(
                              'assets/icons/google_login_logo.png',
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            await ref
                                .read(userViewModelProvider
                                    .notifier)
                                .appleLogin();
                          },
                          child: CircleAvatar(
                            radius: 30.r,
                            child: Image.asset(
                              'assets/icons/apple_login_logo.png',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                RichText(
                  text: TextSpan(
                    text: '가입 시 ',
                    style: AppFontStyles.bodyRegular12
                        .copyWith(color: AppColors.grey600),
                    children: <TextSpan>[
                      TextSpan(
                        text: '이용약관',
                        style: AppFontStyles.bodyRegular12
                            .copyWith(
                                color: AppColors.orange400),
                      ),
                      TextSpan(text: '과 '),
                      TextSpan(
                        text: '개인정보 수집 및 이용',
                        style: AppFontStyles.bodyRegular12
                            .copyWith(
                                color: AppColors.orange400),
                      ),
                      TextSpan(text: '에 동의하게 됩니다.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(child: SizedBox(height: 40.h)),
        ],
      ),
    );
  }
}
