import 'dart:convert';
import 'dart:io';
import 'package:dailymoji/core/config/api_config.dart';
import 'package:dailymoji/data/data_sources/user_profile_data_source.dart';
import 'package:dailymoji/data/dtos/user_profile_dto.dart';
import 'package:dailymoji/domain/enums/enum_data.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/src/foundation/platform.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class UserProfileDataSourceImpl
    implements UserProfileDataSource {
  final supabase = Supabase.instance.client;
  final auth = Supabase.instance.client.auth;
  final google = GoogleSignIn(
      clientId: Platform.isIOS
          ? dotenv.env['GOOGLE_IOS_CLIENT_ID']
          : null,
      serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID']);

  @override
  Future<String?> appleLogin() async {
    try {
      final apple = await SignInWithApple.getAppleIDCredential(
          webAuthenticationOptions: WebAuthenticationOptions(
              clientId: 'com.dailymoji.service',
              redirectUri: Uri.parse(
                  'https://dltzahlhemuigebsiafi.supabase.co/auth/v1/callback')),
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName
          ]);
      final idToken = apple.identityToken;
      final accessToken = apple.authorizationCode;
      if (idToken == null) {
        return null;
      }
      final result = await Supabase.instance.client.auth
          .signInWithIdToken(
              provider: OAuthProvider.apple,
              idToken: idToken,
              accessToken: accessToken);
      return result.user?.id;
      // await auth.signInWithOAuth(OAuthProvider.apple,
      //     authScreenLaunchMode: LaunchMode.externalApplication,
      //     redirectTo: 'dailymoji://login-callback');
      // final user = Supabase.instance.client.auth.currentUser;
      // return user!.id;
    } catch (e) {
      print(e);
      return null;
    }
  }

  @override
  Future<String?> googleLogin() async {
    try {
      final id = await google.signIn();
      final auth = await id?.authentication;
      if (auth?.idToken == null) {
        return null;
      }
      final result = await Supabase.instance.client.auth
          .signInWithIdToken(
              provider: OAuthProvider.google,
              idToken: auth!.idToken!,
              accessToken: auth.accessToken);
      return result.user?.id;
      // await auth.signInWithOAuth(
      //   OAuthProvider.google,
      //   authScreenLaunchMode: LaunchMode.externalApplication,
      //   redirectTo: 'dailymoji://login-callback',
      // );
      // print('!@#%^^&');
      // final user = Supabase.instance.client.auth.currentUser;
      // return user!.id;
    } catch (e) {
      print(e);
      return null;
    }
  }

  @override
  Future<UserProfileDto?> getUserProfile(String uuid) async {
    final result = await supabase
        .from('user_profiles')
        .select()
        .eq('id', uuid)
        .maybeSingle();
    if (result != null) {
      return UserProfileDto.fromJson(result);
    } else {
      return null;
    }
  }

  @override
  Future<void> insertUserProfile(
      UserProfileDto userProfileDto) async {
    print(userProfileDto.id!);
    await supabase
        .from('user_profiles')
        .upsert(userProfileDto.toJson())
        .match({'id': userProfileDto.id!});
  }

  @override
  Future<UserProfileDto> updateUserNickNM(
      {required String userNickNM, required String uuid}) async {
    final updated = await supabase
        .from('user_profiles')
        .update({
          'user_nick_nm': userNickNM,
        })
        .eq('id', uuid)
        .select()
        .single();
    return UserProfileDto.fromJson(updated);
  }

  @override
  Future<UserProfileDto> updateCharacterNM(
      {required String uuid,
      required String characterNM}) async {
    final updated = await supabase
        .from('user_profiles')
        .update({'character_nm': characterNM})
        .eq('id', uuid)
        .select()
        .single();
    return UserProfileDto.fromJson(updated);
  }

  @override
  Future<UserProfileDto> updateCharacterPersonality(
      {required String uuid,
      required String characterPersonality}) async {
    final updated = await supabase
        .from('user_profiles')
        .update({
          'character_personality': CharacterPersonality.values
              .firstWhere(
                (e) => e.myLabel == characterPersonality,
              )
              .dbValue
        })
        .eq('id', uuid)
        .select()
        .single();
    return UserProfileDto.fromJson(updated);
  }

  @override
  Future<String> fetchSleepHygieneTip(
      {String? personality, String? userNickNm}) async {
    try {
      final queryParams = {
        if (personality != null) 'personality': personality,
        if (userNickNm != null) 'user_nick_nm': userNickNm,
      };
      final uri =
          Uri.parse('${ApiConfig.baseUrl}/dialogue/sleep-tip')
              .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['tip'] as String;
      } else {
        throw Exception('Failed to load sleep tip');
      }
    } catch (e) {
      print('Error fetching sleep tip: $e');
      return '규칙적인 수면 습관을 가져보세요.'; // Fallback message
    }
  }

  @override
  Future<String> fetchActionMission(
      {String? personality, String? userNickNm}) async {
    try {
      final queryParams = {
        if (personality != null) 'personality': personality,
        if (userNickNm != null) 'user_nick_nm': userNickNm,
      };
      final uri = Uri.parse(
              '${ApiConfig.baseUrl}/dialogue/action-mission')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['mission'] as String;
      } else {
        throw Exception('Failed to load action mission');
      }
    } catch (e) {
      print('Error fetching action mission: $e');
      return '잠시 자리에서 일어나 굳은 몸을 풀어보는 건 어때요?'; // Fallback message
    }
  }

  @override
  Future<void> logOut() async {
    print("확인");
    await google.signOut();
    // 실제 로그아웃 처리
    await supabase.auth.signOut();
    final user = Supabase
        .instance.client.auth.currentUser; // 로그아웃 확인 // 잘됨!
    print("아아아아아아$user"); // 로그아웃 전: User 객체 / 로그아웃 후: null
  }

  @override
  Future<void> deleteAccount(String userId) async {
    print("확인");
    await google.signOut();
    // 실제 로그아웃 처리
    await supabase
        .from('user_profiles')
        .delete()
        .eq('id', userId);
    await supabase.auth.signOut();
    final user = Supabase
        .instance.client.auth.currentUser; // 로그아웃 확인 // 잘됨!
    print("오오오오오오$user"); // 로그아웃 전: User 객체 / 로그아웃 후: null
  }

  // 자동로그인을 위해 userId를 가져다 쓰는걸로 변경
  @override
  Future<void> saveFcmTokenToSupabase(
      {required TargetPlatform platform,
      required String userId}) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        print("⚠️ FCM 토큰을 가져올 수 없습니다.");
        return;
      }

      await supabase.from('user_tokens').upsert({
        'user_id': userId,
        'token': token,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      print("✅ Supabase에 FCM 토큰 저장 완료: $token");
    } catch (e) {
      print("⚠️ FCM 토큰 저장 실패: $e");
    }
  }
}
