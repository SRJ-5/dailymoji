import 'package:dailymoji/data/data_sources/user_profile_data_source.dart';
import 'package:dailymoji/data/dtos/user_profile_dto.dart';
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
          await SignInWithApple.getAppleIDCredential(scopes: [
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
      final google = GoogleSignIn(
          serverClientId:
              '18885609599-o0jg2pk712561eakcm2qgu7nj8uglpic.apps.googleusercontent.com');
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
  Future<UserProfileDto> getUserProfile(
      UserProfileDto userProfileDto) {
    throw UnimplementedError();
  }

  @override
  Future<void> insertUserProfile(
      UserProfileDto userProfileDto) async {
    await supabase
        .from('user_profiles')
        .insert(userProfileDto.toJson());
  }
}
