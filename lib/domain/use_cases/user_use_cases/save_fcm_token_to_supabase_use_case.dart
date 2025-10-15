import 'package:dailymoji/domain/repositories/user_profile_repository.dart';
import 'package:flutter/material.dart';

class SaveFcmTokenToSupabaseUseCase {
  SaveFcmTokenToSupabaseUseCase(this._userRepository);
  final UserProfileRepository _userRepository;

  Future<void> execute(TargetPlatform platform) async {
    return await _userRepository
        .saveFcmTokenToSupabase(platform);
  }
}
