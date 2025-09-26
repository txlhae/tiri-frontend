import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
@JsonSerializable(explicitToJson: true)
class UserModel with _$UserModel {
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
    // Approval system fields
    @Default(false) bool isApproved,
    String? approvalStatus, // 'pending', 'approved', 'rejected', 'expired'
    String? rejectionReason,
    @Default(null) DateTime? approvalExpiresAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  // Factory method specifically for parsing requester objects from API
  factory UserModel.fromRequesterJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['id'] ?? '',
      email: json['email'] ?? '', // Use the email from backend requester object
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
      referralCode: json['full_name'], // Use referralCode field for full_name
      // Approval fields
      isApproved: json['is_approved'] ?? false,
      approvalStatus: json['approval_status'],
      rejectionReason: json['rejection_reason'],
      approvalExpiresAt: json['approval_expires_at'] != null 
          ? DateTime.parse(json['approval_expires_at']) 
          : null,
    );
  }
}