import 'package:dailymoji/data/data_sources/srj5_questions_data_source.dart';
import 'package:dailymoji/data/dtos/srj5_questions_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Srj5QuestionsDataSourceImpl
    implements Srj5QuestionsDataSource {
  final supabase = Supabase.instance.client;

  @override
  Future<List<Srj5QuestionsDto?>> getQuestion(
      String cluster) async {
    print(cluster);
    final result = await supabase
        .from('srj5_questions')
        .select()
        .eq('cluster', cluster)
        .order('display_order', ascending: true);
    if (result.isNotEmpty) {
      final list = result.map(
        (e) {
          return Srj5QuestionsDto.fromJson(e);
        },
      );
      return list.toList();
    }
    return [];
  }
}
