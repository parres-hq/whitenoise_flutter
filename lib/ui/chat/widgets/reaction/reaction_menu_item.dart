import 'package:flutter/widgets.dart';

class MenuItem {
  final String label;
  final IconData icon;
  final bool isDestuctive;

  // contsructor
  const MenuItem({
    required this.label,
    required this.icon,
    this.isDestuctive = false,
  });
}