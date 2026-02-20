// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gamification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GamificationImpl _$$GamificationImplFromJson(Map<String, dynamic> json) =>
    _$GamificationImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      streak: (json['streak'] as num).toInt(),
      achievements: json['achievements'] as String,
      lastActivity: DateTime.parse(json['lastActivity'] as String),
    );

Map<String, dynamic> _$$GamificationImplToJson(_$GamificationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'streak': instance.streak,
      'achievements': instance.achievements,
      'lastActivity': instance.lastActivity.toIso8601String(),
    };
