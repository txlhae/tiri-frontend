import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

// Helper function to read fullName from both snake_case and camelCase
Object? _readFullName(Map json, String key) {
  // Try full_name (snake_case from backend) first, then fullName (camelCase)
  return json['full_name'] ?? json['fullName'] ?? json['first_name'] ?? json['firstName'];
}

@freezed
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
    // ignore: invalid_annotation_target
    @JsonKey(name: 'fullName', readValue: _readFullName) String? fullName, // Full name of the user
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
      fullName: json['full_name'], // Properly map full_name
      imageUrl: json['profile_image_url'],
      rating: (json['average_rating'] as num?)?.toDouble(),
      hours: json['total_hours_helped'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      isVerified: json['is_verified'] ?? false,
      // Map the additional fields to existing fields where possible
      country: json['location_display'], // Use country field for location_display
      referralCode: json['referral_code'], // Properly map referral_code
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

/// Extension methods for UserModel
extension UserModelExtension on UserModel {
  /// Get the display name - returns full name if available, otherwise username
  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) {
      return fullName!;
    }
    return username;
  }
}