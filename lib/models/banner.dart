import 'package:freezed_annotation/freezed_annotation.dart';

part 'banner.freezed.dart';
part 'banner.g.dart';

@freezed
class Banner with _$Banner {
  const factory Banner({
    required String id,
    required String title,
    required String imageUrl,
    required String targetUrl,
    required BannerType type,
    @Default(true) bool isActive,
    DateTime? startDate,
    DateTime? endDate,
  }) = _Banner;

  factory Banner.fromJson(Map<String, dynamic> json) => _$BannerFromJson(json);
}

enum BannerType {
  promotional,
  educational,
  referral,
  seasonal,
}