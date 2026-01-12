import 'package:flutter/material.dart';

class ExploreFilter extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onChanged;

  const ExploreFilter({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Votes', 'Event'];

    return Row(
      children: List.generate(filters.length, (index) {
        final isActive = selectedIndex == index;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(index),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isActive ? Colors.red : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                filters[index],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
