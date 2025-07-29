// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      userId: json['userId'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      imageUrl: json['imageUrl'] as String?,
      referralUserId: json['referralUserId'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      country: json['country'] as String?,
      referralCode: json['referralCode'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      hours: (json['hours'] as num?)?.toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      isVerified: json['isVerified'] as bool? ?? false,
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'email': instance.email,
      'username': instance.username,
      'imageUrl': instance.imageUrl,
      'referralUserId': instance.referralUserId,
      'phoneNumber': instance.phoneNumber,
      'country': instance.country,
      'referralCode': instance.referralCode,
      'rating': instance.rating,
      'hours': instance.hours,
      'createdAt': instance.createdAt?.toIso8601String(),
      'isVerified': instance.isVerified,
    };