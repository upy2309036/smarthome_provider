// lib/widgets/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../screens/bluetooth_devices_screen.dart';
import '../screens/profiles_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Use Consumer only on the header, which needs profile data.
          Consumer<ProfileProvider>(
            builder: (context, profileProvider, child) => _buildDrawerHeader(context, profileProvider),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profiles'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilesScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bluetooth),
            title: const Text('Bluetooth Devices'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const BluetoothDevicesScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, ProfileProvider profileProvider) {
    final profile = profileProvider.currentProfile;
    final userName = profile?.name ?? 'Guest';
    final userIcon = profile?.icon ?? Icons.person;

    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              child: Icon(userIcon, size: 50), // Adjusted size for better fit
            ),
            const SizedBox(height: 12),
            Text(
              userName,
              style: Theme.of(context).primaryTextTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
