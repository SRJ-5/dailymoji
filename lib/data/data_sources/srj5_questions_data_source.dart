import 'package:dailymoji/data/dtos/srj5_questions_dto.dart';

abstract class Srj5QuestionsDataSource {
  Future<List<Srj5QuestionsDto?>> getQuestion(String cluster);
}
