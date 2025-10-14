import 'package:dailymoji/data/data_sources/assessment_response_remote_data_source.dart';
import 'package:dailymoji/data/dtos/assessment_responses_dto.dart';
import 'package:dailymoji/domain/entities/assessment_responses.dart';
import 'package:dailymoji/domain/repositories/assessment_response_repository.dart';

class AssessmentResponseRepositoryImpl
    implements AssessmentResponseRepository {
  AssessmentResponseRepositoryImpl(this._responseDataSource);
  final AssessmentResponseRemoteDataSource _responseDataSource;

  @override
  Future<void> submitAssessment(
      AssessmentResponses assessmentResponses) async {
    final assessmentResponsesDto = AssessmentResponsesDto(
      cluster: assessmentResponses.cluster,
      responses: assessmentResponses.responses,
      userId: assessmentResponses.userId,
    );
    await _responseDataSource
        .submitAssessment(assessmentResponsesDto);
  }
}
