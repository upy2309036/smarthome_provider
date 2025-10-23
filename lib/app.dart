// lib/app.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/theme.dart';
import 'providers/device_provider.dart';
import 'providers/profile_provider.dart';
import 'screens/home_screen.dart';
import 'services/bluetooth_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.scaffoldMessengerKey,
  });

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => DeviceProvider(BluetoothService()),
        ),
        ChangeNotifierProxyProvider<DeviceProvider, ProfileProvider>(
          create: (context) => ProfileProvider(
              context.read<DeviceProvider>(), scaffoldMessengerKey),
          update: (context, deviceProvider, previousProfileProvider) =>
              ProfileProvider(deviceProvider, scaffoldMessengerKey),
        ),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: scaffoldMessengerKey,
        title: 'Smart Home Control',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}