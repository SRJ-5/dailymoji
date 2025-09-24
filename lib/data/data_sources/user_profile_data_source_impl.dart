import 'dart:io';

import 'package:dailymoji/data/data_sources/user_profile_data_source.dart';
import 'package:dailymoji/data/dtos/user_profile_dto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class UserProfileDataSourceImpl
    implements UserProfileDataSource {
  final supabase = Supabase.instance.client;
  final auth = Supabase.instance.client.auth;

  @override
  Future<String?> appleLogin() async {
    try {
      final apple =
          await SignInWithApple.getAppleIDCredential(
            webAuthenticationOptions: WebAuthenticationOptions(clientId: 'com.dailymoji.service', redirectUri: Uri.parse('https://dltzahlhemuigebsiafi.supabase.co/auth/v1/callback')),
            scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName
      ]);
      final idToken = apple.identityToken;
      final accessToken = apple.authorizationCode;
      print('idtoken : $idToken');
      if (idToken == null) {
        return null;
      }
      final result = await Supabase.instance.client.auth
          .signInWithIdToken(
              provider: OAuthProvider.apple,
              idToken: idToken,
              accessToken: accessToken);
        print('result : ${result.user!.id}');
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
      print('!@!@##');
      final google = GoogleSignIn(
          clientId: Platform.isIOS ? dotenv.env['GOOGLE_IOS_CLIENT_ID'] : null,
          serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID']);
      final id = await google.signIn();
      final auth = await id?.authentication;
      print('id : $id');
      if (auth?.idToken == null) {
        return null;
      }
      final result = await Supabase.instance.client.auth
          .signInWithIdToken(
              provider: OAuthProvider.google,
              idToken: auth!.idToken!,
              accessToken: auth.accessToken);
      print(result.user?.id);
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
    await supabase
        .from('user_profiles')
        .insert(userProfileDto.toJson());
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
        .update({'character_personality': characterPersonality})
        .eq('id', uuid)
        .select()
        .single();
    return UserProfileDto.fromJson(updated);
  }
}
