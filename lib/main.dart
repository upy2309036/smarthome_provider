// lib/main.dart

import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  // Global key for showing SnackBars from providers.
  final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  runApp(MyApp(scaffoldMessengerKey: scaffoldMessengerKey));
}
