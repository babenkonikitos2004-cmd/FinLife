// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gamification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Gamification _$GamificationFromJson(Map<String, dynamic> json) {
  return _Gamification.fromJson(json);
}

/// @nodoc
mixin _$Gamification {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  int get streak => throw _privateConstructorUsedError;
  String get achievements => throw _privateConstructorUsedError;
  DateTime get lastActivity => throw _privateConstructorUsedError;

  /// Serializes this Gamification to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Gamification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GamificationCopyWith<Gamification> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GamificationCopyWith<$Res> {
  factory $GamificationCopyWith(
          Gamification value, $Res Function(Gamification) then) =
      _$GamificationCopyWithImpl<$Res, Gamification>;
  @useResult
  $Res call(
      {String id,
      String userId,
      int streak,
      String achievements,
      DateTime lastActivity});
}

/// @nodoc
class _$GamificationCopyWithImpl<$Res, $Val extends Gamification>
    implements $GamificationCopyWith<$Res> {
  _$GamificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Gamification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? streak = null,
    Object? achievements = null,
    Object? lastActivity = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      streak: null == streak
          ? _value.streak
          : streak // ignore: cast_nullable_to_non_nullable
              as int,
      achievements: null == achievements
          ? _value.achievements
          : achievements // ignore: cast_nullable_to_non_nullable
              as String,
      lastActivity: null == lastActivity
          ? _value.lastActivity
          : lastActivity // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GamificationImplCopyWith<$Res>
    implements $GamificationCopyWith<$Res> {
  factory _$$GamificationImplCopyWith(
          _$GamificationImpl value, $Res Function(_$GamificationImpl) then) =
      __$$GamificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      int streak,
      String achievements,
      DateTime lastActivity});
}

/// @nodoc
class __$$GamificationImplCopyWithImpl<$Res>
    extends _$GamificationCopyWithImpl<$Res, _$GamificationImpl>
    implements _$$GamificationImplCopyWith<$Res> {
  __$$GamificationImplCopyWithImpl(
      _$GamificationImpl _value, $Res Function(_$GamificationImpl) _then)
      : super(_value, _then);

  /// Create a copy of Gamification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? streak = null,
    Object? achievements = null,
    Object? lastActivity = null,
  }) {
    return _then(_$GamificationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      streak: null == streak
          ? _value.streak
          : streak // ignore: cast_nullable_to_non_nullable
              as int,
      achievements: null == achievements
          ? _value.achievements
          : achievements // ignore: cast_nullable_to_non_nullable
              as String,
      lastActivity: null == lastActivity
          ? _value.lastActivity
          : lastActivity // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GamificationImpl implements _Gamification {
  const _$GamificationImpl(
      {required this.id,
      required this.userId,
      required this.streak,
      required this.achievements,
      required this.lastActivity});

  factory _$GamificationImpl.fromJson(Map<String, dynamic> json) =>
      _$$GamificationImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final int streak;
  @override
  final String achievements;
  @override
  final DateTime lastActivity;

  @override
  String toString() {
    return 'Gamification(id: $id, userId: $userId, streak: $streak, achievements: $achievements, lastActivity: $lastActivity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GamificationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.streak, streak) || other.streak == streak) &&
            (identical(other.achievements, achievements) ||
                other.achievements == achievements) &&
            (identical(other.lastActivity, lastActivity) ||
                other.lastActivity == lastActivity));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, userId, streak, achievements, lastActivity);

  /// Create a copy of Gamification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GamificationImplCopyWith<_$GamificationImpl> get copyWith =>
      __$$GamificationImplCopyWithImpl<_$GamificationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GamificationImplToJson(
      this,
    );
  }
}

abstract class _Gamification implements Gamification {
  const factory _Gamification(
      {required final String id,
      required final String userId,
      required final int streak,
      required final String achievements,
      required final DateTime lastActivity}) = _$GamificationImpl;

  factory _Gamification.fromJson(Map<String, dynamic> json) =
      _$GamificationImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  int get streak;
  @override
  String get achievements;
  @override
  DateTime get lastActivity;

  /// Create a copy of Gamification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GamificationImplCopyWith<_$GamificationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
