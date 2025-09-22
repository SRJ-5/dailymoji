import 'package:dailymoji/domain/entities/user_profile.dart';

abstract class UserProfileRepository {
  Future<void> insertUserProfile(UserProfile userProfile);
  Future<UserProfile> getUserProfile(UserProfile userProfile);
}
