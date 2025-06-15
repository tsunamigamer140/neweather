import 'package:flutter/material.dart';

class CategoryBar extends StatelessWidget {
  final List<String> categories;
  final int currentCategoryIndex;
  final bool isDarkMode;
  final void Function(int) onCategorySelected;

  const CategoryBar({
    super.key,
    required this.categories,
    required this.currentCategoryIndex,
    required this.isDarkMode,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade300,
      padding: const EdgeInsets.symmetric(vertical: 12),
      height: 60,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((cat) {
            final isSelected = categories.indexOf(cat) == currentCategoryIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GestureDetector(
                onTap: () => onCategorySelected(categories.indexOf(cat)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDarkMode ? Colors.white : Colors.black)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? (isDarkMode ? Colors.black : Colors.white)
                          : (isDarkMode ? Colors.white70 : Colors.black87),
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}