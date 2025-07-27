import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  @JsonSerializable(explicitToJson: true)
  const factory UserModel({
    required String userId,
    required String email,
    required String username,
    String? imageUrl,
    String? referralUserId,
    String? phoneNumber,
    String? country,
    String? referralCode,
    double? rating,
    int? hours,
    @Default(null) DateTime? createdAt,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}