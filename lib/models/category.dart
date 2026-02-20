import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

enum CategoryType { income, expense }

@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    required CategoryType type,
    required String icon,
    required int color,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
}