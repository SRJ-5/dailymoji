import 'package:dailymoji/data/data_sources/user_profile_data_source.dart';
import 'package:dailymoji/data/data_sources/user_profile_data_source_impl.dart';
import 'package:dailymoji/data/repositories/user_profile_repository_impl.dart';
import 'package:dailymoji/domain/repositories/user_profile_repository.dart';
import 'package:dailymoji/domain/use_cases/user_use_cases/apple_login_use_case.dart';
import 'package:dailymoji/domain/use_cases/user_use_cases/get_user_profile_use_case.dart';
import 'package:dailymoji/domain/use_cases/user_use_cases/google_login_use_case.dart';
import 'package:dailymoji/domain/use_cases/user_use_cases/insert_user_profile_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _userDataSourceProvider = Provider<UserProfileDataSource>(
  (ref) {
    return UserProfileDataSourceImpl();
  },
);

final _userRepositoryProvider = Provider<UserProfileRepository>(
  (ref) {
    return UserProfileRepositoryImpl(
        ref.read(_userDataSourceProvider));
  },
);

final googleLoginUseCaseProvier = Provider(
  (ref) {
    return GoogleLoginUseCase(ref.read(_userRepositoryProvider));
  },
);

final appleLoginUseCaseProvier = Provider(
  (ref) {
    return AppleLoginUseCase(ref.read(_userRepositoryProvider));
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
