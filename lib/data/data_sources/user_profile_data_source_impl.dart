import 'dart:convert';
import 'dart:io';
import 'package:dailymoji/core/config/api_config.dart';
import 'package:dailymoji/data/data_sources/user_profile_data_source.dart';
import 'package:dailymoji/data/dtos/user_profile_dto.dart';
import 'package:dailymoji/domain/enums/enum_data.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class UserProfileDataSourceImpl implements UserProfileDataSource {
  final supabase = Supabase.instance.client;
  final auth = Supabase.instance.client.auth;
  final google = GoogleSignIn(
      clientId: Platform.isIOS ? dotenv.env['GOOGLE_IOS_CLIENT_ID'] : null,
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
      final result = await Supabase.instance.client.auth.signInWithIdToken(
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
      final result = await Supabase.instance.client.auth.signInWithIdToken(
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
  Future<void> insertUserProfile(UserProfileDto userProfileDto) async {
    await supabase.from('user_profiles').insert(userProfileDto.toJson());
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

  // RIN: 솔루션 피드백을 백엔드로 전송하는 함수
  @override
  Future<void> submitSolutionFeedback({
    required String userId,
    required String solutionId,
    String? sessionId,
    required String solutionType,
    required String feedback,
  }) async {
    try {
      await supabase.rpc('handle_solution_feedback', params: {
        'p_user_id': userId,
        'p_solution_id': solutionId,
        'p_session_id': sessionId,
        'p_solution_type': solutionType,
        'p_feedback': feedback,
      });
    } catch (e) {
      print('Error submitting solution feedback: $e');
      rethrow;
    }
  }

  // RIN: '이런 종류 그만 보기' 태그를 백엔드로 전송하는 함수
  @override
  Future<void> addNegativeTags(
      {required String userId, required List<String> tags}) async {
    try {
      await supabase.rpc('add_negative_tags', params: {
        'p_user_id': userId,
        'p_tags_to_add': tags,
      });
    } catch (e) {
      print('Error adding negative tags: $e');
      rethrow;
    }
  }

  @override
  Future<UserProfileDto> updateCharacterNM(
      {required String uuid, required String characterNM}) async {
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
      {required String uuid, required String characterPersonality}) async {
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
      final uri = Uri.parse('${ApiConfig.baseUrl}/dialogue/sleep-tip')
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
      final uri = Uri.parse('${ApiConfig.baseUrl}/dialogue/action-mission')
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
    final user = Supabase.instance.client.auth.currentUser; // 로그아웃 확인 // 잘됨!
    print("아아아아아아$user"); // 로그아웃 전: User 객체 / 로그아웃 후: null
  }

  @override
  Future<void> deleteAccount(String userId) async {
    print("확인");
    await google.signOut();
    // 실제 로그아웃 처리
    await supabase.from('user_profiles').delete().eq('id', userId);
    await supabase.auth.signOut();
    final user = Supabase.instance.client.auth.currentUser; // 로그아웃 확인 // 잘됨!
    print("오오오오오오$user"); // 로그아웃 전: User 객체 / 로그아웃 후: null
  }
}
