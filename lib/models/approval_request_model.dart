import 'package:freezed_annotation/freezed_annotation.dart';

part 'approval_request_model.freezed.dart';
part 'approval_request_model.g.dart';

@freezed
class ApprovalRequest with _$ApprovalRequest {
  const ApprovalRequest._();

  const factory ApprovalRequest({
    required String id,
    required String newUserEmail,
    required String newUserName,
    required String newUserCountry,
    String? newUserPhone,
    required String referralCodeUsed,
    required String status, // 'pending', 'approved', 'rejected', 'expired'
    required DateTime requestedAt,
    required DateTime expiresAt,
    String? newUserProfileImage,
    String? rejectionReason,
    DateTime? decidedAt,
  }) = _ApprovalRequest;

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) =>
      _$ApprovalRequestFromJson(json);

  // Computed property for time remaining
  String get timeRemaining {
    final now = DateTime.now();
    if (expiresAt.isBefore(now)) {
      return 'Expired';
    }
    
    final difference = expiresAt.difference(now);
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    
    if (days > 0) {
      return '$days days, $hours hours';
    } else if (hours > 0) {
      return '$hours hours';
    } else {
      final minutes = difference.inMinutes;
      return '$minutes minutes';
    }
  }

  // Computed property to check if expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  // Computed property to check if expiring soon (< 24 hours)
  bool get isExpiringSoon {
    final hoursRemaining = expiresAt.difference(DateTime.now()).inHours;
    return hoursRemaining <= 24 && hoursRemaining > 0;
  }
}