import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

@freezed
@JsonSerializable(explicitToJson: true)
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String notificationId,
    required String status,
    required String body,
    required bool isUserWaiting,
    required String userId,
    required DateTime timestamp,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
}
