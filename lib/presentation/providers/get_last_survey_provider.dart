import 'package:dailymoji/core/providers.dart';
import 'package:dailymoji/data/data_sources/assessment_history_data_source.dart';
import 'package:dailymoji/data/data_sources/assessment_history_data_source_impl.dart';
import 'package:dailymoji/data/repositories/assessment_history_repository_impl.dart';
import 'package:dailymoji/domain/repositories/assessment_history_repository.dart';
import 'package:dailymoji/domain/use_cases/get_last_survey_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//DI 연결에서 watch 사용: Provider 체인에선 ref.watch(...)가 일반적.

final _assessmentHistoryDataSourceProvider =
    Provider<AssessmentHistoryDataSource>(
  (ref) {
    return AssessmentHistoryDataSourceImpl(ref.watch(supabaseClientProvider));
  },
);

final _assessmentHistoryRepositoryProvider =
    Provider<AssessmentHistoryRepository>(
  (ref) {
    return AssessmentHistoryRepositoryImpl(
        ref.watch(_assessmentHistoryDataSourceProvider));
  },
);

final getLastSurveyUsecaseProvider = Provider<GetLastSurveyUsecase>(
  (ref) {
    return GetLastSurveyUsecase(
        ref.watch(_assessmentHistoryRepositoryProvider));
  },
);
