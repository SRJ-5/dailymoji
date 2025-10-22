import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/icons.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final uuidStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    autoLogin();
  }

  // Rin: 가입여부 확인하고 프로필 이미 있으면 넘어가는 함수 따로 뺌
  Future<void> _handleLogin(Future<String?> loginFuture,
      TargetPlatform platform) async {
    try {
      final userId = await loginFuture;
      if (userId != null && mounted) {
        // 로그인 성공 후, 프로필이 있는지 확인
        final isRegistered = await checkLoginUser(userId);
        if (mounted) {
          // 프로필 유무에 따라 다른 페이지로 이동
          if (isRegistered) {
            // 내부에 uuid 저장
            final localUserId = await checkLocalUuid();
            await savelocalUuid(
                userId: userId, localUserId: localUserId);
            //MIN: 로그인 성공 후, FCM 토큰 Supabase에 저장
            await ref
                .read(userViewModelProvider.notifier)
                .saveFcmTokenToSupabase(
                    platform: platform, userId: userId);
            context.go('/home'); // 이미 가입했으면 홈으로
          } else {
            context.go('/onboarding1'); // 처음이면 온보딩으로
          }
        }
      } else if (mounted) {
        // TODO: 로그인 실패 처리 디자인하기!!
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: AppText("로그인에 실패했습니다. 다시 시도해주세요.")));
      }
    } catch (e) {
      // 예외 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: AppText("오류가 발생했습니다: ${e.toString()}")));
      }
    }
  }

  Future<String?> checkLocalUuid() async {
    final localUserId = await uuidStorage.read(key: 'user_id');
    print('local uuid $localUserId');
    return localUserId;
  }

  Future<void> savelocalUuid(
      {required String? userId,
      required String? localUserId}) async {
    if (localUserId == null || localUserId != userId) {
      await uuidStorage.write(key: 'user_id', value: userId);
      print('local uuid 저장완료 $userId');
    }
  }

  Future<bool> checkLoginUser(String userId) async {
    final result = await ref
        .read(userViewModelProvider.notifier)
        .getUserProfile(userId);
    return result;
  }

  Future<void> autoLogin() async {
    final localUserId = await checkLocalUuid();
    if (localUserId != null) {
      final isRegistered = await checkLoginUser(localUserId);
      if (mounted) {
        final platform = Theme.of(context).platform;
        // 프로필 유무에 따라 다른 페이지로 이동
        if (isRegistered) {
          //MIN: 로그인 성공 후, FCM 토큰 Supabase에 저장
          await ref
              .read(userViewModelProvider.notifier)
              .saveFcmTokenToSupabase(
                  platform: platform, userId: localUserId);
          context.go('/home'); // 이미 가입했으면 홈으로
        }
      }
    }
  }

  void _goToInfoWebView(String title) async {
    await context.push('/info/$title');
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    return Scaffold(
      backgroundColor: AppColors.yellow50,
      appBar: AppBar(
        backgroundColor: AppColors.yellow50,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    AppIcons.dailymojiLogoColor,
                    height: 48.h,
                    width: 174.w,
                  ),
                  SizedBox(
                    height: 8.h,
                  ),
                  AppText(
                    '매일매일 감정 관리',
                    style: AppFontStyles.bodyRegular18
                        .copyWith(color: AppColors.grey500),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Spacer(),
                    GestureDetector(
                      onTap: () => _handleLogin(
                          ref
                              .read(
                                  userViewModelProvider.notifier)
                              .googleLogin(),
                          platform),
                      child: CircleAvatar(
                        radius: 30.r,
                        child: Image.asset(
                          AppImages.googleLoginLogo,
                        ),
                      ),
                    ),
                    // iOS 플랫폼일 경우에만 애플 로그인 버튼 표시
                    platform == TargetPlatform.iOS
                        ? Row(
                            children: [
                              SizedBox(width: 24.w),
                              GestureDetector(
                                onTap: () => _handleLogin(
                                    ref
                                        .read(
                                            userViewModelProvider
                                                .notifier)
                                        .appleLogin(),
                                    platform),
                                child: CircleAvatar(
                                  radius: 30.r,
                                  child: Image.asset(
                                    AppImages.appleLoginLogo,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : SizedBox.shrink(),
                    Spacer()
                  ],
                ),
                SizedBox(height: 18.h),
                RichText(
                  textScaler: TextScaler.noScaling,
                  text: TextSpan(
                    text: '가입 시 ',
                    style: AppFontStyles.noticeRelgular10
                        .copyWith(color: AppColors.grey500),
                    children: <TextSpan>[
                      TextSpan(
                          text: '이용약관',
                          style: AppFontStyles
                              .underlinedNoticeRelgular10
                              .copyWith(
                                  color: AppColors.grey500),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _goToInfoWebView('이용 약관');
                            }),
                      TextSpan(text: '과 '),
                      TextSpan(
                        text: '개인정보 처리방침',
                        style: AppFontStyles
                            .underlinedNoticeRelgular10
                            .copyWith(color: AppColors.grey500),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            _goToInfoWebView('개인정보 처리방침');
                          },
                      ),
                      TextSpan(text: '에 동의하게 됩니다.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(child: SizedBox(height: 30.h)),
        ],
      ),
    );
  }
}
