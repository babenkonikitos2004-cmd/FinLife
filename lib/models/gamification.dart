import 'package:freezed_annotation/freezed_annotation.dart';

part 'gamification.freezed.dart';
part 'gamification.g.dart';

@freezed
class Gamification with _$Gamification {
  const factory Gamification({
    required String id,
    required String userId,
    required int streak,
    required String achievements,
    required DateTime lastActivity,
  }) = _Gamification;

  factory Gamification.fromJson(Map<String, dynamic> json) => _$GamificationFromJson(json);
}