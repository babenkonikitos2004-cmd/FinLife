import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlife/database/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});