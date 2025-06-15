import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class WeeklyForecast extends StatelessWidget {
  final List<dynamic> dailyForecast;
  final bool isDarkMode;
  final String Function(int) weekdayToString;

  const WeeklyForecast({
    super.key,
    required this.dailyForecast,
    required this.isDarkMode,
    required this.weekdayToString,
  });

  static Widget buildSkeleton({required bool isDarkMode}) {
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.blueGrey.shade800 : Colors.blueAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        height: 220,
        child: Row(
          children: List.generate(5, (index) =>
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 100,
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 20,
                      color: Colors.white24,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 48,
                      height: 24,
                      color: Colors.white24,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 32,
                      color: Colors.white24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (dailyForecast.isEmpty) return SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.blueGrey.shade800 : Colors.blueAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      height: 240,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: dailyForecast.map((day) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      weekdayToString(day['day'].weekday),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Image.network(
                      'https://openweathermap.org/img/wn/${day['icon']}@2x.png',
                      width: 60,
                      height: 60,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${day['temp'].round()}°',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(day['rain'] * 100).round()}%\nchance\nof rain',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}