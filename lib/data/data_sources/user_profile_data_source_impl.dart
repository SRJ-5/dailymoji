import 'package:dailymoji/data/data_sources/user_profile_data_source.dart';
import 'package:dailymoji/data/dtos/user_profile_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileDataSourceImpl
    implements UserProfileDataSource {
  final supabase = Supabase.instance.client;
  final auth = Supabase.instance.client.auth;

  @override
  Future<String?> appleLogin() async {
    try {
      await auth.signInWithOAuth(OAuthProvider.apple,
          authScreenLaunchMode: LaunchMode.externalApplication,
          redirectTo: 'dailymoji://login-callback');
      final user = Supabase.instance.client.auth.currentUser;
      return user!.id;
    } catch (e) {
      print(e);
      return null;
    }
  }

  @override
  Future<String?> googleLogin() async {
    try {
      await auth.signInWithOAuth(
        OAuthProvider.google,
        authScreenLaunchMode: LaunchMode.externalApplication,
        redirectTo: 'dailymoji://login-callback',
      );
      final user = Supabase.instance.client.auth.currentUser;
      return user!.id;
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
