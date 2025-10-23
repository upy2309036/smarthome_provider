// lib/screens/profiles_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../providers/profile_provider.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('User Profiles')),
        // Use a Consumer to listen for changes in the ProfileProvider
        body: Consumer<ProfileProvider>(
            builder: (context, profileProvider, child) {
      final profiles = profileProvider.profiles;
      final currentProfile = profileProvider.currentProfile;

      if (profiles.isEmpty) {
        return const Center(child: Text('No profiles found.'));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          final profile = profiles[index];
          final isCurrent = profile.name == currentProfile?.name;
          return _buildProfileTile(context, profile, isCurrent);
        },
      );
    }));
  }

  Widget _buildProfileTile(
      BuildContext context, Profile profile, bool isCurrent) {
    final profileProvider = context.read<ProfileProvider>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor:
              isCurrent ? Colors.blue.shade100 : Colors.grey.shade200,
          child: Icon(
            profile.icon,
            color: isCurrent ? Colors.blue.shade700 : Colors.grey.shade600,
          ),
        ),
        title: Text(
          profile.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: isCurrent
            ? Chip(
                avatar: Icon(Icons.check_circle,
                    color: Colors.green.shade700, size: 18),
                label: const Text('Active'),
                backgroundColor: Colors.green.shade100,
                labelStyle: TextStyle(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.w500,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              )
            : ElevatedButton(
                onPressed: () {
                  // Set the new profile. The provider will show a SnackBar.
                  profileProvider.setCurrentProfile(profile);
                  // Pop the screen to return to the home screen.
                  Navigator.pop(context);
                },
                child: const Text('Select'),
              ),
      ),
    );
  }
}