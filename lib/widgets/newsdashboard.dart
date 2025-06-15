import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class NewsDashboardSkeleton extends StatelessWidget {
  final bool isDarkMode;
  const NewsDashboardSkeleton({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 8, 152, 219),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Shimmer.fromColors(
                baseColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                highlightColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                child: Container(
                  width: 160,
                  height: 28,
                  color: Colors.white24,
                ),
              ),
              const SizedBox(width: 16),
              Shimmer.fromColors(
                baseColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                highlightColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                child: Container(
                  width: 32,
                  height: 28,
                  color: Colors.white24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 420,
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) => Shimmer.fromColors(
                baseColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                highlightColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                child: Container(
                  height: 120,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}