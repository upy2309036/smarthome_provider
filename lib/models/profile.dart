import 'package:flutter/material.dart';
import 'package:smarthome_provider/models/device.dart';

class Profile {
  final String name;
  final IconData icon;
  final List<SmartDevice> deviceSettings;

  Profile({
    required this.name,
    required this.icon,
    required this.deviceSettings,
  });

  Profile copyWith({
    String? name,
    IconData? icon,
    List<SmartDevice>? deviceSettings,
  }) {
    return Profile(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      deviceSettings: deviceSettings ?? this.deviceSettings,
    );
  }

  // Convert a Profile instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': {
        'codePoint': icon.codePoint,
        'fontFamily': icon.fontFamily,
        'fontPackage': icon.fontPackage,
      },
      'deviceSettings':
          deviceSettings.map((device) => device.toJson()).toList(),
    };
  }

  // Create a Profile instance from a JSON map.
  factory Profile.fromJson(Map<String, dynamic> json) {
    final deviceList = json['deviceSettings'] as List<dynamic>? ?? [];
    final iconData = json['icon'] as Map<String, dynamic>?;

    return Profile(
      name: json['name'] as String,
      icon: iconData != null
          ? IconData(
              iconData['codePoint'] as int,
              fontFamily: iconData['fontFamily'] as String?,
              fontPackage: iconData['fontPackage'] as String?,
            )
          : Icons.person, // Default icon if not found
      deviceSettings: deviceList
          .map((deviceJson) =>
              SmartDevice.fromJson(deviceJson as Map<String, dynamic>))
          .toList(),
    );
  }
}