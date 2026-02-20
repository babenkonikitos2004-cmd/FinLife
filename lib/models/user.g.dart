// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      monthlyIncome: (json['monthlyIncome'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      gender: json['gender'] as String?,
      age: (json['age'] as num?)?.toInt(),
      financialGoal: json['financialGoal'] as String?,
    );

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'monthlyIncome': instance.monthlyIncome,
      'createdAt': instance.createdAt.toIso8601String(),
      'gender': instance.gender,
      'age': instance.age,
      'financialGoal': instance.financialGoal,
    };
