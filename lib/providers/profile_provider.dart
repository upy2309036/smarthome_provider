import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/device.dart';
import '../models/profile.dart';
import 'device_provider.dart';

class ProfileProvider extends ChangeNotifier {
  // --- Private State ---
  List<Profile> _profiles = [];
  Profile? _currentProfile;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;
  final DeviceProvider _deviceProvider;

  // --- Public Getters ---
  List<Profile> get profiles => List.unmodifiable(_profiles);
  Profile? get currentProfile => _currentProfile;

  // --- Constructor ---
  ProfileProvider(this._deviceProvider, this._scaffoldMessengerKey) {
    _initializeProfiles();
    // Listen for changes in DeviceProvider to keep profile data in sync.
    _deviceProvider.addListener(_onDeviceProviderChange);
  }

  // --- Core Methods ---

  /// Initializes a default set of user profiles with random device settings.
  void _initializeProfiles() {
    const userNames = ['Shuber', 'Alice', 'Bob', 'Charlie', 'Diana'];
    const profileIcons = [
      Icons.person,
      Icons.face,
      Icons.account_circle,
      Icons.supervised_user_circle,
      Icons.emoji_emotions,
    ];

    _profiles = List.generate(userNames.length, (index) {
      final userName = userNames[index];
      // Cycle through icons if there are more users than icons
      final icon = profileIcons[index % profileIcons.length];
      return Profile(
        name: userName,
        icon: icon,
        deviceSettings: _generateDeviceSettingsForProfile(index),
      );
    });

    // Set the first profile as the currently active one by default.
    if (_profiles.isNotEmpty) {
      _currentProfile = _profiles.first;
      _deviceProvider.applyProfileSettings(_currentProfile!.deviceSettings);
    }
    notifyListeners();
  }

  /// Generates a list of smart devices with predefined settings based on profile index.
  List<SmartDevice> _generateDeviceSettingsForProfile(int profileIndex) {
    // Predefined settings for different profiles to avoid randomness
    // and ensure consistent state for testing and demonstration.
    final settings = [
      // Settings for Profile 0 (Uriel)
      [true, false, true, 45, 0],
      // Settings for Profile 1 (Alice)
      [false, true, true, 90, 90],
      // Settings for Profile 2 (Bob)
      [true, true, false, 120, 0],
      // Settings for Profile 3 (Charlie)
      [false, false, false, 0, 90],
      // Settings for Profile 4 (Diana)
      [true, true, true, 180, 0],
    ];

    // Use modulo to cycle through settings if there are more profiles than settings
    final profileSettings = settings[profileIndex % settings.length];

    return [
      SmartDevice(
          id: 'led1',
          name: 'Living Room LED',
          type: DeviceType.led,
          isOn: profileSettings[0] as bool),
      SmartDevice(
          id: 'led2',
          name: 'Bedroom LED',
          type: DeviceType.led,
          isOn: profileSettings[1] as bool),
      SmartDevice(
          id: 'led3',
          name: 'Kitchen LED',
          type: DeviceType.led,
          isOn: profileSettings[2] as bool),
      SmartDevice(
          id: 'servo1',
          name: 'Window Blind',
          type: DeviceType.servo,
          angle: profileSettings[3] as int),
      SmartDevice(
          id: 'servo2',
          name: 'Door Lock',
          type: DeviceType.servo,
          angle: profileSettings[4] as int),
    ];
  }

  /// Sets the currently active profile.
  void setCurrentProfile(Profile profile) {
    _currentProfile = profile;
    _deviceProvider.applyProfileSettings(profile.deviceSettings);

    // Show a notification that the profile has changed.
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('Profile changed to ${profile.name}'),
        backgroundColor: Colors.green,
      ),
    );
    notifyListeners();
  }

  /// Callback function that listens for changes in the [DeviceProvider].
  ///
  /// When device states change (e.g., a light is turned on), this function
  /// updates the device settings of the currently active profile to reflect
  /// those changes. This ensures that the profile's configuration is always
  /// up-to-date with the actual state of the devices.
  void _onDeviceProviderChange() {
    if (_currentProfile != null) {
      // Check if there's an actual change to avoid unnecessary updates and notifications.
      if (listEquals(_currentProfile!.deviceSettings, _deviceProvider.devices)) {
        return;
      }

      // Create a deep copy of the device settings from the DeviceProvider.
      final updatedSettings =
          _deviceProvider.devices.map((d) => d.copyWith()).toList();

      // Update the current profile with the new settings.
      _currentProfile = _currentProfile!.copyWith(deviceSettings: updatedSettings);

      // Show a notification that the profile data has been updated.
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Current profile data updated.'),
          duration: Duration(seconds: 2),
        ),
      );
      // Notify listeners that the profile data has changed.
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _deviceProvider.removeListener(_onDeviceProviderChange);
    super.dispose();
  }
}