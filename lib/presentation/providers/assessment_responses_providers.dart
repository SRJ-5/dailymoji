import 'package:dailymoji/data/data_sources/assessment_response_remote_data_source.dart';
import 'package:dailymoji/data/data_sources/assessment_response_remote_data_source_impl.dart';
import 'package:dailymoji/data/repositories/assessment_response_repository_impl.dart';
import 'package:dailymoji/domain/repositories/assessment_response_repository.dart';
import 'package:dailymoji/domain/use_cases/assessment_use_cases/submit_assessment_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _assessmentResponsesDataSourceProvider =
    Provider<AssessmentResponseRemoteDataSource>(
  (ref) {
    return AssessmentResponseRemoteDataSourceImpl();
  },
);

final _assessmentResponsesRepositoryProvider =
    Provider<AssessmentResponseRepository>(
  (ref) {
    return AssessmentResponseRepositoryImpl(
        ref.read(_assessmentResponsesDataSourceProvider));
  },
);

final submitAssessmentUseCaseProvider = Provider(
  (ref) {
    return SubmitAssessmentUseCase(
        ref.read(_assessmentResponsesRepositoryProvider));
  },
);
