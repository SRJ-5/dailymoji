import 'package:dailymoji/data/data_sources/user_data_source.dart';
import 'package:dailymoji/data/dtos/survey_response_dto.dart';
import 'package:dailymoji/data/dtos/user_profile_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserDataSourceImpl implements UserDataSource {
  final supabase = Supabase.instance.client;

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

  @override
  Future<ServeyResponseDto> getServeyResponses(
      ServeyResponseDto serveyResponseDto) {
    throw UnimplementedError();
  }

  @override
  Future<void> insertServeyResponses(
      ServeyResponseDto serveyResponseDto) async {
    await supabase
        .from('servey_responses')
        .insert(serveyResponseDto.toJson());
  }
}
