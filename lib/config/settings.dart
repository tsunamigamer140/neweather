import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neweather/config/themer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return SafeArea(
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        appBar: AppBar(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          elevation: 0,
          title: Text('Settings',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
        ),
        body: ListView(
          children: [
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: isDarkMode,
              onChanged: (value) => themeProvider.toggleTheme(value),
              secondary: const Icon(Icons.brightness_6),
              activeColor: Colors.green,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              subtitle: const Text('Toggle between dark and light mode'),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Your theme preference is saved locally.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
