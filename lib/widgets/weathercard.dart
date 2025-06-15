import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class WeatherCard extends StatelessWidget {
  final Map<String, dynamic> currentWeather;
  final String city;
  final bool isDarkMode;

  const WeatherCard({
    super.key,
    required this.currentWeather,
    required this.city,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.amber.shade700 : Colors.amberAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.wb_sunny, size: 64, color: isDarkMode ? Colors.white : Colors.black),
          const SizedBox(height: 8),
          Text(
            currentWeather['weather'][0]['main'],
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
          ),
          const SizedBox(height: 4),
          Text(
            "${currentWeather['main']['temp'].round()}°   ${currentWeather['main']['humidity']}%H",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
          ),
          const SizedBox(height: 4),
          Text(
            city.toLowerCase(),
            style: TextStyle(fontSize: 20, fontFamily: 'monospace', color: isDarkMode ? Colors.white70 : Colors.black),
          ),
        ],
      ),
    );
  }

  /// Skeleton loader for WeatherCard
  static Widget buildSkeleton({required bool isDarkMode}) {
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.amber.shade700 : Colors.amberAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 120,
              height: 32,
              color: Colors.white24,
            ),
            const SizedBox(height: 4),
            Container(
              width: 100,
              height: 20,
              color: Colors.white24,
            ),
            const SizedBox(height: 4),
            Container(
              width: 80,
              height: 20,
              color: Colors.white24,
            ),
          ],
        ),
      ),
    );
  }
}