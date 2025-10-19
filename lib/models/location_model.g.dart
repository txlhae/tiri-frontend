// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LocationModelImpl _$$LocationModelImplFromJson(Map<String, dynamic> json) =>
    _$LocationModelImpl(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      displayName: json['displayName'] as String?,
      locality: json['locality'] as String?,
      subLocality: json['subLocality'] as String?,
      administrativeArea: json['administrativeArea'] as String?,
      country: json['country'] as String?,
      postalCode: json['postalCode'] as String?,
      fullAddress: json['fullAddress'] as String?,
    );

Map<String, dynamic> _$$LocationModelImplToJson(_$LocationModelImpl instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'displayName': instance.displayName,
      'locality': instance.locality,
      'subLocality': instance.subLocality,
      'administrativeArea': instance.administrativeArea,
      'country': instance.country,
      'postalCode': instance.postalCode,
      'fullAddress': instance.fullAddress,
    };
