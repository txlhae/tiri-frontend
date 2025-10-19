import 'package:freezed_annotation/freezed_annotation.dart';

part 'location_model.freezed.dart';
part 'location_model.g.dart';

@freezed
class LocationModel with _$LocationModel {
  const factory LocationModel({
    required double latitude,
    required double longitude,
    String? displayName, // e.g., "Kakkanad, Kochi"
    String? locality, // e.g., "Kakkanad"
    String? subLocality, // e.g., "Thrikkakara"
    String? administrativeArea, // e.g., "Kochi" or "Ernakulam"
    String? country,
    String? postalCode,
    String? fullAddress,
  }) = _LocationModel;

  factory LocationModel.fromJson(Map<String, dynamic> json) =>
      _$LocationModelFromJson(json);
}

extension LocationModelExtension on LocationModel {
  /// Get a user-friendly display name
  /// Format: "Locality, Administrative Area" or "SubLocality, Administrative Area"
  String get friendlyDisplayName {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }

    final List<String> parts = [];

    if (locality != null && locality!.isNotEmpty) {
      parts.add(locality!);
    } else if (subLocality != null && subLocality!.isNotEmpty) {
      parts.add(subLocality!);
    }

    if (administrativeArea != null && administrativeArea!.isNotEmpty) {
      parts.add(administrativeArea!);
    }

    if (parts.isEmpty) {
      return 'Location Selected';
    }

    return parts.join(', ');
  }
}
