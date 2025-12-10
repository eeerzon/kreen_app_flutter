import 'package:flutter/material.dart';

class DetailVoteLang extends InheritedWidget {
  final Map<String, dynamic> values;

  const DetailVoteLang({
    super.key,
    required this.values,
    required super.child,
  });

  static DetailVoteLang of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DetailVoteLang>()!;
  }

  @override
  bool updateShouldNotify(DetailVoteLang oldWidget) {
    return values != oldWidget.values;
  }
}
