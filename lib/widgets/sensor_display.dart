 import 'package:flutter/material.dart';
  
  class SensorDisplay extends StatelessWidget {
    const SensorDisplay({Key? key}) : super(key: key);
  
    @override
    Widget build(BuildContext context) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sensors_off, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Sensors Not Connected',
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Connect your environmental sensors\nto see data here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
  }