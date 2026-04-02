// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';

class ExploreFilterNew extends StatelessWidget {
  final Map<String, dynamic> bahasa;
  final int selectedIndex;
  final List<String> timeFilter;
  final List<String> priceFilter;
  final Function() onReset;

  const ExploreFilterNew({
    super.key,
    required this.bahasa,
    required this.selectedIndex,
    required this.timeFilter,
    required this.priceFilter,
    required this.onReset,
  });

  String getTypeLabel() {
    switch (selectedIndex) {
      case 1:
        return "Vote";
      case 2:
        return "Event";
      default:
        return "All";
    }
  }

  String mapTime(String key) {
    switch (key) {
      case 'this_week':
        return bahasa['this_week'];
      case 'this_month':
        return bahasa['this_month'];
      case 'next_month':
        return bahasa['next_month'];
      default:
        return key;
    }
  }

  String mapPrice(String key) {
    switch (key) {
      case 'free':
        return bahasa['harga_detail'];
      case 'paid':
        return bahasa['berbayar'];
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> filters = [];

    // TYPE
    if (selectedIndex != null) {
      filters.add(getTypeLabel());
    }

    // TIME -> gabung jadi satu
    if (timeFilter.isNotEmpty) {
      final timeLabel = timeFilter.map(mapTime).join(", ");
      filters.add(timeLabel);
    }

    // PRICE -> gabung jadi satu
    if (priceFilter.isNotEmpty) {
      final priceLabel = priceFilter.map(mapPrice).join(", ");
      filters.add(priceLabel);
    }

    if (filters.isEmpty) return const SizedBox();

    // return Align(
    //   alignment: Alignment.centerLeft,
    //   child: SingleChildScrollView(
    //     scrollDirection: Axis.horizontal,
    //     child: Row(
    //       mainAxisAlignment: MainAxisAlignment.start,
    //       children: filters.map((label) {
    //         return Container(
    //           margin: const EdgeInsets.only(right: 8),
    //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    //           decoration: BoxDecoration(
    //             color: Colors.red,
    //             borderRadius: BorderRadius.circular(8),
    //           ),
    //           child: Text(
    //             label,
    //             style: const TextStyle(color: Colors.white),
    //           ),
    //         );
    //       }).toList(),
    //     ),
    //   ),
    // );

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8, // jarak horizontal antar chip
        runSpacing: 8, // jarak antar baris
        children: filters.map((label) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
      ),
    );
  }
}