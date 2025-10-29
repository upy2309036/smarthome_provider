// lib/widgets/profile_selector.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';

class ProfileSelector extends StatelessWidget {
  const ProfileSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DeviceProvider>(context);
    final profiles = provider.userProfiles;

    // Solo muestra el selector si hay conexión
    if (!provider.isConnected) return Container(); 

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Profiles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: profiles.keys.map((profileName) {
                return ElevatedButton.icon(
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          // Llama a la nueva función
                          await provider.applyProfile(profileName);
                        },
                  icon: const Icon(Icons.person),
                  label: Text(profileName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade400,
                    foregroundColor: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}