class AssessmentResponsesDto {
  final String? userId;
  final String? cluster;
  final Map<String, int>? responses;
  AssessmentResponsesDto(
      {this.userId, this.cluster, this.responses});
}
