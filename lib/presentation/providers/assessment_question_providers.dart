import 'package:dailymoji/data/data_sources/srj5_questions_data_source.dart';
import 'package:dailymoji/data/data_sources/srj5_questions_data_source_impl.dart';
import 'package:dailymoji/data/repositories/assessment_repository_impl.dart';
import 'package:dailymoji/domain/repositories/assessment_repository.dart';
import 'package:dailymoji/domain/use_cases/assessment_use_cases/getQuestion_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _srj5QuestionsDataSourceProvider =
    Provider<Srj5QuestionsDataSource>(
  (ref) {
    return Srj5QuestionsDataSourceImpl();
  },
);

final _assessmentRepositoryProvider =
    Provider<AssessmentRepository>(
  (ref) {
    return AssessmentRepositoryImpl(
        ref.read(_srj5QuestionsDataSourceProvider));
  },
);

final getQuestionsUseCaseProvider = Provider(
  (ref) {
    return GetquestionUseCase(
        ref.read(_assessmentRepositoryProvider));
  },
);
