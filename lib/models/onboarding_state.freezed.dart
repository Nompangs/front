// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

OnboardingState _$OnboardingStateFromJson(Map<String, dynamic> json) {
  return _OnboardingState.fromJson(json);
}

/// @nodoc
mixin _$OnboardingState {
  String get nickname => throw _privateConstructorUsedError;
  String get humorStyle => throw _privateConstructorUsedError;
  String get purpose => throw _privateConstructorUsedError;
  String get location => throw _privateConstructorUsedError;
  String get duration => throw _privateConstructorUsedError;
  String get objectType => throw _privateConstructorUsedError;
  String? get photoPath => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  bool get isGenerating => throw _privateConstructorUsedError;
  double get generationProgress => throw _privateConstructorUsedError;
  String get generationMessage =>
      throw _privateConstructorUsedError; // personality sliders
  int get warmth => throw _privateConstructorUsedError;
  int get competence => throw _privateConstructorUsedError;
  int get extroversion => throw _privateConstructorUsedError;

  /// Serializes this OnboardingState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OnboardingStateCopyWith<OnboardingState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OnboardingStateCopyWith<$Res> {
  factory $OnboardingStateCopyWith(
    OnboardingState value,
    $Res Function(OnboardingState) then,
  ) = _$OnboardingStateCopyWithImpl<$Res, OnboardingState>;
  @useResult
  $Res call({
    String nickname,
    String humorStyle,
    String purpose,
    String location,
    String duration,
    String objectType,
    String? photoPath,
    bool isLoading,
    String? errorMessage,
    bool isGenerating,
    double generationProgress,
    String generationMessage,
    int warmth,
    int competence,
    int extroversion,
  });
}

/// @nodoc
class _$OnboardingStateCopyWithImpl<$Res, $Val extends OnboardingState>
    implements $OnboardingStateCopyWith<$Res> {
  _$OnboardingStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nickname = null,
    Object? humorStyle = null,
    Object? purpose = null,
    Object? location = null,
    Object? duration = null,
    Object? objectType = null,
    Object? photoPath = freezed,
    Object? isLoading = null,
    Object? errorMessage = freezed,
    Object? isGenerating = null,
    Object? generationProgress = null,
    Object? generationMessage = null,
    Object? warmth = null,
    Object? competence = null,
    Object? extroversion = null,
  }) {
    return _then(
      _value.copyWith(
            nickname:
                null == nickname
                    ? _value.nickname
                    : nickname // ignore: cast_nullable_to_non_nullable
                        as String,
            humorStyle:
                null == humorStyle
                    ? _value.humorStyle
                    : humorStyle // ignore: cast_nullable_to_non_nullable
                        as String,
            purpose:
                null == purpose
                    ? _value.purpose
                    : purpose // ignore: cast_nullable_to_non_nullable
                        as String,
            location:
                null == location
                    ? _value.location
                    : location // ignore: cast_nullable_to_non_nullable
                        as String,
            duration:
                null == duration
                    ? _value.duration
                    : duration // ignore: cast_nullable_to_non_nullable
                        as String,
            objectType:
                null == objectType
                    ? _value.objectType
                    : objectType // ignore: cast_nullable_to_non_nullable
                        as String,
            photoPath:
                freezed == photoPath
                    ? _value.photoPath
                    : photoPath // ignore: cast_nullable_to_non_nullable
                        as String?,
            isLoading:
                null == isLoading
                    ? _value.isLoading
                    : isLoading // ignore: cast_nullable_to_non_nullable
                        as bool,
            errorMessage:
                freezed == errorMessage
                    ? _value.errorMessage
                    : errorMessage // ignore: cast_nullable_to_non_nullable
                        as String?,
            isGenerating:
                null == isGenerating
                    ? _value.isGenerating
                    : isGenerating // ignore: cast_nullable_to_non_nullable
                        as bool,
            generationProgress:
                null == generationProgress
                    ? _value.generationProgress
                    : generationProgress // ignore: cast_nullable_to_non_nullable
                        as double,
            generationMessage:
                null == generationMessage
                    ? _value.generationMessage
                    : generationMessage // ignore: cast_nullable_to_non_nullable
                        as String,
            warmth:
                null == warmth
                    ? _value.warmth
                    : warmth // ignore: cast_nullable_to_non_nullable
                        as int,
            competence:
                null == competence
                    ? _value.competence
                    : competence // ignore: cast_nullable_to_non_nullable
                        as int,
            extroversion:
                null == extroversion
                    ? _value.extroversion
                    : extroversion // ignore: cast_nullable_to_non_nullable
                        as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OnboardingStateImplCopyWith<$Res>
    implements $OnboardingStateCopyWith<$Res> {
  factory _$$OnboardingStateImplCopyWith(
    _$OnboardingStateImpl value,
    $Res Function(_$OnboardingStateImpl) then,
  ) = __$$OnboardingStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String nickname,
    String humorStyle,
    String purpose,
    String location,
    String duration,
    String objectType,
    String? photoPath,
    bool isLoading,
    String? errorMessage,
    bool isGenerating,
    double generationProgress,
    String generationMessage,
    int warmth,
    int competence,
    int extroversion,
  });
}

/// @nodoc
class __$$OnboardingStateImplCopyWithImpl<$Res>
    extends _$OnboardingStateCopyWithImpl<$Res, _$OnboardingStateImpl>
    implements _$$OnboardingStateImplCopyWith<$Res> {
  __$$OnboardingStateImplCopyWithImpl(
    _$OnboardingStateImpl _value,
    $Res Function(_$OnboardingStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nickname = null,
    Object? humorStyle = null,
    Object? purpose = null,
    Object? location = null,
    Object? duration = null,
    Object? objectType = null,
    Object? photoPath = freezed,
    Object? isLoading = null,
    Object? errorMessage = freezed,
    Object? isGenerating = null,
    Object? generationProgress = null,
    Object? generationMessage = null,
    Object? warmth = null,
    Object? competence = null,
    Object? extroversion = null,
  }) {
    return _then(
      _$OnboardingStateImpl(
        nickname:
            null == nickname
                ? _value.nickname
                : nickname // ignore: cast_nullable_to_non_nullable
                    as String,
        humorStyle:
            null == humorStyle
                ? _value.humorStyle
                : humorStyle // ignore: cast_nullable_to_non_nullable
                    as String,
        purpose:
            null == purpose
                ? _value.purpose
                : purpose // ignore: cast_nullable_to_non_nullable
                    as String,
        location:
            null == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                    as String,
        duration:
            null == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                    as String,
        objectType:
            null == objectType
                ? _value.objectType
                : objectType // ignore: cast_nullable_to_non_nullable
                    as String,
        photoPath:
            freezed == photoPath
                ? _value.photoPath
                : photoPath // ignore: cast_nullable_to_non_nullable
                    as String?,
        isLoading:
            null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                    as bool,
        errorMessage:
            freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                    as String?,
        isGenerating:
            null == isGenerating
                ? _value.isGenerating
                : isGenerating // ignore: cast_nullable_to_non_nullable
                    as bool,
        generationProgress:
            null == generationProgress
                ? _value.generationProgress
                : generationProgress // ignore: cast_nullable_to_non_nullable
                    as double,
        generationMessage:
            null == generationMessage
                ? _value.generationMessage
                : generationMessage // ignore: cast_nullable_to_non_nullable
                    as String,
        warmth:
            null == warmth
                ? _value.warmth
                : warmth // ignore: cast_nullable_to_non_nullable
                    as int,
        competence:
            null == competence
                ? _value.competence
                : competence // ignore: cast_nullable_to_non_nullable
                    as int,
        extroversion:
            null == extroversion
                ? _value.extroversion
                : extroversion // ignore: cast_nullable_to_non_nullable
                    as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OnboardingStateImpl implements _OnboardingState {
  const _$OnboardingStateImpl({
    this.nickname = '',
    this.humorStyle = '',
    this.purpose = '',
    this.location = '',
    this.duration = '',
    this.objectType = '',
    this.photoPath,
    this.isLoading = false,
    this.errorMessage = null,
    this.isGenerating = false,
    this.generationProgress = 0.0,
    this.generationMessage = '',
    this.warmth = 5,
    this.competence = 5,
    this.extroversion = 5,
  });

  factory _$OnboardingStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$OnboardingStateImplFromJson(json);

  @override
  @JsonKey()
  final String nickname;
  @override
  @JsonKey()
  final String humorStyle;
  @override
  @JsonKey()
  final String purpose;
  @override
  @JsonKey()
  final String location;
  @override
  @JsonKey()
  final String duration;
  @override
  @JsonKey()
  final String objectType;
  @override
  final String? photoPath;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final String? errorMessage;
  @override
  @JsonKey()
  final bool isGenerating;
  @override
  @JsonKey()
  final double generationProgress;
  @override
  @JsonKey()
  final String generationMessage;
  // personality sliders
  @override
  @JsonKey()
  final int warmth;
  @override
  @JsonKey()
  final int competence;
  @override
  @JsonKey()
  final int extroversion;

  @override
  String toString() {
    return 'OnboardingState(nickname: $nickname, humorStyle: $humorStyle, purpose: $purpose, location: $location, duration: $duration, objectType: $objectType, photoPath: $photoPath, isLoading: $isLoading, errorMessage: $errorMessage, isGenerating: $isGenerating, generationProgress: $generationProgress, generationMessage: $generationMessage, warmth: $warmth, competence: $competence, extroversion: $extroversion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OnboardingStateImpl &&
            (identical(other.nickname, nickname) ||
                other.nickname == nickname) &&
            (identical(other.humorStyle, humorStyle) ||
                other.humorStyle == humorStyle) &&
            (identical(other.purpose, purpose) || other.purpose == purpose) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.objectType, objectType) ||
                other.objectType == objectType) &&
            (identical(other.photoPath, photoPath) ||
                other.photoPath == photoPath) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.isGenerating, isGenerating) ||
                other.isGenerating == isGenerating) &&
            (identical(other.generationProgress, generationProgress) ||
                other.generationProgress == generationProgress) &&
            (identical(other.generationMessage, generationMessage) ||
                other.generationMessage == generationMessage) &&
            (identical(other.warmth, warmth) || other.warmth == warmth) &&
            (identical(other.competence, competence) ||
                other.competence == competence) &&
            (identical(other.extroversion, extroversion) ||
                other.extroversion == extroversion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    nickname,
    humorStyle,
    purpose,
    location,
    duration,
    objectType,
    photoPath,
    isLoading,
    errorMessage,
    isGenerating,
    generationProgress,
    generationMessage,
    warmth,
    competence,
    extroversion,
  );

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OnboardingStateImplCopyWith<_$OnboardingStateImpl> get copyWith =>
      __$$OnboardingStateImplCopyWithImpl<_$OnboardingStateImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$OnboardingStateImplToJson(this);
  }
}

abstract class _OnboardingState implements OnboardingState {
  const factory _OnboardingState({
    final String nickname,
    final String humorStyle,
    final String purpose,
    final String location,
    final String duration,
    final String objectType,
    final String? photoPath,
    final bool isLoading,
    final String? errorMessage,
    final bool isGenerating,
    final double generationProgress,
    final String generationMessage,
    final int warmth,
    final int competence,
    final int extroversion,
  }) = _$OnboardingStateImpl;

  factory _OnboardingState.fromJson(Map<String, dynamic> json) =
      _$OnboardingStateImpl.fromJson;

  @override
  String get nickname;
  @override
  String get humorStyle;
  @override
  String get purpose;
  @override
  String get location;
  @override
  String get duration;
  @override
  String get objectType;
  @override
  String? get photoPath;
  @override
  bool get isLoading;
  @override
  String? get errorMessage;
  @override
  bool get isGenerating;
  @override
  double get generationProgress;
  @override
  String get generationMessage; // personality sliders
  @override
  int get warmth;
  @override
  int get competence;
  @override
  int get extroversion;

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OnboardingStateImplCopyWith<_$OnboardingStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Character _$CharacterFromJson(Map<String, dynamic> json) {
  return _Character.fromJson(json);
}

/// @nodoc
mixin _$Character {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get objectType => throw _privateConstructorUsedError;
  Personality get personality => throw _privateConstructorUsedError;
  String get greeting => throw _privateConstructorUsedError;
  List<String> get traits => throw _privateConstructorUsedError;
  String get systemPrompt => throw _privateConstructorUsedError;
  String get qrCode => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Character to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Character
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CharacterCopyWith<Character> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CharacterCopyWith<$Res> {
  factory $CharacterCopyWith(Character value, $Res Function(Character) then) =
      _$CharacterCopyWithImpl<$Res, Character>;
  @useResult
  $Res call({
    String id,
    String name,
    String objectType,
    Personality personality,
    String greeting,
    List<String> traits,
    String systemPrompt,
    String qrCode,
    DateTime? createdAt,
  });

  $PersonalityCopyWith<$Res> get personality;
}

/// @nodoc
class _$CharacterCopyWithImpl<$Res, $Val extends Character>
    implements $CharacterCopyWith<$Res> {
  _$CharacterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Character
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? objectType = null,
    Object? personality = null,
    Object? greeting = null,
    Object? traits = null,
    Object? systemPrompt = null,
    Object? qrCode = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            objectType:
                null == objectType
                    ? _value.objectType
                    : objectType // ignore: cast_nullable_to_non_nullable
                        as String,
            personality:
                null == personality
                    ? _value.personality
                    : personality // ignore: cast_nullable_to_non_nullable
                        as Personality,
            greeting:
                null == greeting
                    ? _value.greeting
                    : greeting // ignore: cast_nullable_to_non_nullable
                        as String,
            traits:
                null == traits
                    ? _value.traits
                    : traits // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            systemPrompt:
                null == systemPrompt
                    ? _value.systemPrompt
                    : systemPrompt // ignore: cast_nullable_to_non_nullable
                        as String,
            qrCode:
                null == qrCode
                    ? _value.qrCode
                    : qrCode // ignore: cast_nullable_to_non_nullable
                        as String,
            createdAt:
                freezed == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of Character
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PersonalityCopyWith<$Res> get personality {
    return $PersonalityCopyWith<$Res>(_value.personality, (value) {
      return _then(_value.copyWith(personality: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CharacterImplCopyWith<$Res>
    implements $CharacterCopyWith<$Res> {
  factory _$$CharacterImplCopyWith(
    _$CharacterImpl value,
    $Res Function(_$CharacterImpl) then,
  ) = __$$CharacterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String objectType,
    Personality personality,
    String greeting,
    List<String> traits,
    String systemPrompt,
    String qrCode,
    DateTime? createdAt,
  });

  @override
  $PersonalityCopyWith<$Res> get personality;
}

/// @nodoc
class __$$CharacterImplCopyWithImpl<$Res>
    extends _$CharacterCopyWithImpl<$Res, _$CharacterImpl>
    implements _$$CharacterImplCopyWith<$Res> {
  __$$CharacterImplCopyWithImpl(
    _$CharacterImpl _value,
    $Res Function(_$CharacterImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Character
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? objectType = null,
    Object? personality = null,
    Object? greeting = null,
    Object? traits = null,
    Object? systemPrompt = null,
    Object? qrCode = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$CharacterImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        objectType:
            null == objectType
                ? _value.objectType
                : objectType // ignore: cast_nullable_to_non_nullable
                    as String,
        personality:
            null == personality
                ? _value.personality
                : personality // ignore: cast_nullable_to_non_nullable
                    as Personality,
        greeting:
            null == greeting
                ? _value.greeting
                : greeting // ignore: cast_nullable_to_non_nullable
                    as String,
        traits:
            null == traits
                ? _value._traits
                : traits // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        systemPrompt:
            null == systemPrompt
                ? _value.systemPrompt
                : systemPrompt // ignore: cast_nullable_to_non_nullable
                    as String,
        qrCode:
            null == qrCode
                ? _value.qrCode
                : qrCode // ignore: cast_nullable_to_non_nullable
                    as String,
        createdAt:
            freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CharacterImpl implements _Character {
  const _$CharacterImpl({
    required this.id,
    required this.name,
    required this.objectType,
    required this.personality,
    required this.greeting,
    required final List<String> traits,
    this.systemPrompt = "",
    this.qrCode = "",
    this.createdAt,
  }) : _traits = traits;

  factory _$CharacterImpl.fromJson(Map<String, dynamic> json) =>
      _$$CharacterImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String objectType;
  @override
  final Personality personality;
  @override
  final String greeting;
  final List<String> _traits;
  @override
  List<String> get traits {
    if (_traits is EqualUnmodifiableListView) return _traits;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_traits);
  }

  @override
  @JsonKey()
  final String systemPrompt;
  @override
  @JsonKey()
  final String qrCode;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Character(id: $id, name: $name, objectType: $objectType, personality: $personality, greeting: $greeting, traits: $traits, systemPrompt: $systemPrompt, qrCode: $qrCode, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CharacterImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.objectType, objectType) ||
                other.objectType == objectType) &&
            (identical(other.personality, personality) ||
                other.personality == personality) &&
            (identical(other.greeting, greeting) ||
                other.greeting == greeting) &&
            const DeepCollectionEquality().equals(other._traits, _traits) &&
            (identical(other.systemPrompt, systemPrompt) ||
                other.systemPrompt == systemPrompt) &&
            (identical(other.qrCode, qrCode) || other.qrCode == qrCode) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    objectType,
    personality,
    greeting,
    const DeepCollectionEquality().hash(_traits),
    systemPrompt,
    qrCode,
    createdAt,
  );

  /// Create a copy of Character
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CharacterImplCopyWith<_$CharacterImpl> get copyWith =>
      __$$CharacterImplCopyWithImpl<_$CharacterImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CharacterImplToJson(this);
  }
}

abstract class _Character implements Character {
  const factory _Character({
    required final String id,
    required final String name,
    required final String objectType,
    required final Personality personality,
    required final String greeting,
    required final List<String> traits,
    final String systemPrompt,
    final String qrCode,
    final DateTime? createdAt,
  }) = _$CharacterImpl;

  factory _Character.fromJson(Map<String, dynamic> json) =
      _$CharacterImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get objectType;
  @override
  Personality get personality;
  @override
  String get greeting;
  @override
  List<String> get traits;
  @override
  String get systemPrompt;
  @override
  String get qrCode;
  @override
  DateTime? get createdAt;

  /// Create a copy of Character
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CharacterImplCopyWith<_$CharacterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Personality _$PersonalityFromJson(Map<String, dynamic> json) {
  return _Personality.fromJson(json);
}

/// @nodoc
mixin _$Personality {
  int get warmth => throw _privateConstructorUsedError; // 온기 (0-100)
  int get competence => throw _privateConstructorUsedError; // 유능함 (0-100)
  int get extroversion => throw _privateConstructorUsedError;

  /// Serializes this Personality to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Personality
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PersonalityCopyWith<Personality> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PersonalityCopyWith<$Res> {
  factory $PersonalityCopyWith(
    Personality value,
    $Res Function(Personality) then,
  ) = _$PersonalityCopyWithImpl<$Res, Personality>;
  @useResult
  $Res call({int warmth, int competence, int extroversion});
}

/// @nodoc
class _$PersonalityCopyWithImpl<$Res, $Val extends Personality>
    implements $PersonalityCopyWith<$Res> {
  _$PersonalityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Personality
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? warmth = null,
    Object? competence = null,
    Object? extroversion = null,
  }) {
    return _then(
      _value.copyWith(
            warmth:
                null == warmth
                    ? _value.warmth
                    : warmth // ignore: cast_nullable_to_non_nullable
                        as int,
            competence:
                null == competence
                    ? _value.competence
                    : competence // ignore: cast_nullable_to_non_nullable
                        as int,
            extroversion:
                null == extroversion
                    ? _value.extroversion
                    : extroversion // ignore: cast_nullable_to_non_nullable
                        as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PersonalityImplCopyWith<$Res>
    implements $PersonalityCopyWith<$Res> {
  factory _$$PersonalityImplCopyWith(
    _$PersonalityImpl value,
    $Res Function(_$PersonalityImpl) then,
  ) = __$$PersonalityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int warmth, int competence, int extroversion});
}

/// @nodoc
class __$$PersonalityImplCopyWithImpl<$Res>
    extends _$PersonalityCopyWithImpl<$Res, _$PersonalityImpl>
    implements _$$PersonalityImplCopyWith<$Res> {
  __$$PersonalityImplCopyWithImpl(
    _$PersonalityImpl _value,
    $Res Function(_$PersonalityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Personality
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? warmth = null,
    Object? competence = null,
    Object? extroversion = null,
  }) {
    return _then(
      _$PersonalityImpl(
        warmth:
            null == warmth
                ? _value.warmth
                : warmth // ignore: cast_nullable_to_non_nullable
                    as int,
        competence:
            null == competence
                ? _value.competence
                : competence // ignore: cast_nullable_to_non_nullable
                    as int,
        extroversion:
            null == extroversion
                ? _value.extroversion
                : extroversion // ignore: cast_nullable_to_non_nullable
                    as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PersonalityImpl implements _Personality {
  const _$PersonalityImpl({
    this.warmth = 50,
    this.competence = 50,
    this.extroversion = 50,
  });

  factory _$PersonalityImpl.fromJson(Map<String, dynamic> json) =>
      _$$PersonalityImplFromJson(json);

  @override
  @JsonKey()
  final int warmth;
  // 온기 (0-100)
  @override
  @JsonKey()
  final int competence;
  // 유능함 (0-100)
  @override
  @JsonKey()
  final int extroversion;

  @override
  String toString() {
    return 'Personality(warmth: $warmth, competence: $competence, extroversion: $extroversion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PersonalityImpl &&
            (identical(other.warmth, warmth) || other.warmth == warmth) &&
            (identical(other.competence, competence) ||
                other.competence == competence) &&
            (identical(other.extroversion, extroversion) ||
                other.extroversion == extroversion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, warmth, competence, extroversion);

  /// Create a copy of Personality
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PersonalityImplCopyWith<_$PersonalityImpl> get copyWith =>
      __$$PersonalityImplCopyWithImpl<_$PersonalityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PersonalityImplToJson(this);
  }
}

abstract class _Personality implements Personality {
  const factory _Personality({
    final int warmth,
    final int competence,
    final int extroversion,
  }) = _$PersonalityImpl;

  factory _Personality.fromJson(Map<String, dynamic> json) =
      _$PersonalityImpl.fromJson;

  @override
  int get warmth; // 온기 (0-100)
  @override
  int get competence; // 유능함 (0-100)
  @override
  int get extroversion;

  /// Create a copy of Personality
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PersonalityImplCopyWith<_$PersonalityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FinalPersonality _$FinalPersonalityFromJson(Map<String, dynamic> json) {
  return _FinalPersonality.fromJson(json);
}

/// @nodoc
mixin _$FinalPersonality {
  int get extroversion =>
      throw _privateConstructorUsedError; // 1(수줍음) ~ 10(활발함)
  int get warmth => throw _privateConstructorUsedError; // 1(차가움) ~ 10(따뜻함)
  int get competence => throw _privateConstructorUsedError; // 1(서툼) ~ 10(능숙함)
  bool get userAdjusted => throw _privateConstructorUsedError;

  /// Serializes this FinalPersonality to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FinalPersonality
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FinalPersonalityCopyWith<FinalPersonality> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FinalPersonalityCopyWith<$Res> {
  factory $FinalPersonalityCopyWith(
    FinalPersonality value,
    $Res Function(FinalPersonality) then,
  ) = _$FinalPersonalityCopyWithImpl<$Res, FinalPersonality>;
  @useResult
  $Res call({int extroversion, int warmth, int competence, bool userAdjusted});
}

/// @nodoc
class _$FinalPersonalityCopyWithImpl<$Res, $Val extends FinalPersonality>
    implements $FinalPersonalityCopyWith<$Res> {
  _$FinalPersonalityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FinalPersonality
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? extroversion = null,
    Object? warmth = null,
    Object? competence = null,
    Object? userAdjusted = null,
  }) {
    return _then(
      _value.copyWith(
            extroversion:
                null == extroversion
                    ? _value.extroversion
                    : extroversion // ignore: cast_nullable_to_non_nullable
                        as int,
            warmth:
                null == warmth
                    ? _value.warmth
                    : warmth // ignore: cast_nullable_to_non_nullable
                        as int,
            competence:
                null == competence
                    ? _value.competence
                    : competence // ignore: cast_nullable_to_non_nullable
                        as int,
            userAdjusted:
                null == userAdjusted
                    ? _value.userAdjusted
                    : userAdjusted // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FinalPersonalityImplCopyWith<$Res>
    implements $FinalPersonalityCopyWith<$Res> {
  factory _$$FinalPersonalityImplCopyWith(
    _$FinalPersonalityImpl value,
    $Res Function(_$FinalPersonalityImpl) then,
  ) = __$$FinalPersonalityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int extroversion, int warmth, int competence, bool userAdjusted});
}

/// @nodoc
class __$$FinalPersonalityImplCopyWithImpl<$Res>
    extends _$FinalPersonalityCopyWithImpl<$Res, _$FinalPersonalityImpl>
    implements _$$FinalPersonalityImplCopyWith<$Res> {
  __$$FinalPersonalityImplCopyWithImpl(
    _$FinalPersonalityImpl _value,
    $Res Function(_$FinalPersonalityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FinalPersonality
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? extroversion = null,
    Object? warmth = null,
    Object? competence = null,
    Object? userAdjusted = null,
  }) {
    return _then(
      _$FinalPersonalityImpl(
        extroversion:
            null == extroversion
                ? _value.extroversion
                : extroversion // ignore: cast_nullable_to_non_nullable
                    as int,
        warmth:
            null == warmth
                ? _value.warmth
                : warmth // ignore: cast_nullable_to_non_nullable
                    as int,
        competence:
            null == competence
                ? _value.competence
                : competence // ignore: cast_nullable_to_non_nullable
                    as int,
        userAdjusted:
            null == userAdjusted
                ? _value.userAdjusted
                : userAdjusted // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FinalPersonalityImpl implements _FinalPersonality {
  const _$FinalPersonalityImpl({
    required this.extroversion,
    required this.warmth,
    required this.competence,
    this.userAdjusted = false,
  });

  factory _$FinalPersonalityImpl.fromJson(Map<String, dynamic> json) =>
      _$$FinalPersonalityImplFromJson(json);

  @override
  final int extroversion;
  // 1(수줍음) ~ 10(활발함)
  @override
  final int warmth;
  // 1(차가움) ~ 10(따뜻함)
  @override
  final int competence;
  // 1(서툼) ~ 10(능숙함)
  @override
  @JsonKey()
  final bool userAdjusted;

  @override
  String toString() {
    return 'FinalPersonality(extroversion: $extroversion, warmth: $warmth, competence: $competence, userAdjusted: $userAdjusted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FinalPersonalityImpl &&
            (identical(other.extroversion, extroversion) ||
                other.extroversion == extroversion) &&
            (identical(other.warmth, warmth) || other.warmth == warmth) &&
            (identical(other.competence, competence) ||
                other.competence == competence) &&
            (identical(other.userAdjusted, userAdjusted) ||
                other.userAdjusted == userAdjusted));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, extroversion, warmth, competence, userAdjusted);

  /// Create a copy of FinalPersonality
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FinalPersonalityImplCopyWith<_$FinalPersonalityImpl> get copyWith =>
      __$$FinalPersonalityImplCopyWithImpl<_$FinalPersonalityImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$FinalPersonalityImplToJson(this);
  }
}

abstract class _FinalPersonality implements FinalPersonality {
  const factory _FinalPersonality({
    required final int extroversion,
    required final int warmth,
    required final int competence,
    final bool userAdjusted,
  }) = _$FinalPersonalityImpl;

  factory _FinalPersonality.fromJson(Map<String, dynamic> json) =
      _$FinalPersonalityImpl.fromJson;

  @override
  int get extroversion; // 1(수줍음) ~ 10(활발함)
  @override
  int get warmth; // 1(차가움) ~ 10(따뜻함)
  @override
  int get competence; // 1(서툼) ~ 10(능숙함)
  @override
  bool get userAdjusted;

  /// Create a copy of FinalPersonality
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FinalPersonalityImplCopyWith<_$FinalPersonalityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
