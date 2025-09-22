import 'package:dailymoji/data/data_sources/user_data_source.dart';
import 'package:dailymoji/data/data_sources/user_data_source_impl.dart';
import 'package:dailymoji/data/repositories/user_repository_impl.dart';
import 'package:dailymoji/domain/repositories/user_repository.dart';
import 'package:dailymoji/domain/use_cases/user_use_cases/get_survey_response_use_case.dart';
import 'package:dailymoji/domain/use_cases/user_use_cases/get_user_profile_use_case.dart';
import 'package:dailymoji/domain/use_cases/user_use_cases/insert_survey_response_use_case.dart';
import 'package:dailymoji/domain/use_cases/user_use_cases/insert_user_profile_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _userDataSourceProvider = Provider<UserDataSource>(
  (ref) {
    return UserDataSourceImpl();
  },
);

final _userRepositoryProvider = Provider<UserRepository>(
  (ref) {
    return UserRepositoryImpl(ref.read(_userDataSourceProvider));
  },
);

final insertUserProfileUseCaseProvier = Provider(
  (ref) {
    return InsertUserProfileUseCase(
        ref.read(_userRepositoryProvider));
  },
);

final getUserProfileUseCaseProvier = Provider(
  (ref) {
    return GetUserProfileUseCase(
        ref.read(_userRepositoryProvider));
  },
);

final insertSurveyUseCaseProvider = Provider(
  (ref) {
    return InsertSurveyResponseUseCase(
        ref.read(_userRepositoryProvider));
  },
);

final getSurveyUseCaseProvider = Provider(
  (ref) {
    return GetSurveyResponseUseCase(
        ref.read(_userRepositoryProvider));
  },
);
