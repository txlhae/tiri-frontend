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
    @Default(false) bool isVerified,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  // Factory method specifically for parsing requester objects from API
  factory UserModel.fromRequesterJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['id'] ?? '',
      email: '', // Requester doesn't have email, use empty string
      username: json['username'] ?? '',
      imageUrl: json['profile_image_url'],
      rating: (json['average_rating'] as num?)?.toDouble(),
      hours: json['total_hours_helped'] as int?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      isVerified: json['is_verified'] ?? false,
      // Map the additional fields to existing fields where possible
      country: json['location_display'], // Use country field for location_display
      referralCode: json['full_name'], // Use referralCode field for full_name (temp solution)
    );
  }
}