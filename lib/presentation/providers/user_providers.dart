import 'package:dailymoji/data/data_sources/user_profile_data_source.dart';
import 'package:dailymoji/data/data_sources/user_profile_data_source_impl.dart';
import 'package:dailymoji/data/repositories/user_profile_repository_impl.dart';
import 'package:dailymoji/domain/repositories/user_profile_repository.dart';
import 'package:dailymoji/domain/use_cases/user_use_cases/get_user_profile_use_case.dart';
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
