import 'package:dailymoji/data/data_sources/daily_summary_data_source.dart';
import 'package:dailymoji/data/data_sources/daily_summary_data_source_impl.dart';
import 'package:dailymoji/data/repositories/daily_summary_repository_impl.dart';
import 'package:dailymoji/domain/repositories/daily_summary_repository.dart';
import 'package:dailymoji/domain/use_cases/daily_summary_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _dailySummaryDataSourceProvider = Provider<DailySummaryDataSource>(
  (ref) {
    return DailySummaryDataSourceImpl();
  },
);

final _dailySummaryRepositoryProvider = Provider<DailySummaryRepository>(
  (ref) {
    return DailySummaryRepositoryImpl(
        ref.read(_dailySummaryDataSourceProvider));
  },
);

final dailySummaryUsecaseProvider = Provider(
  (ref) {
    return DailySummaryUsecase(ref.read(_dailySummaryRepositoryProvider));
  },
);
