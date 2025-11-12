import 'package:flutter/material.dart';

class BackgroundShape extends StatelessWidget {
  final Color color;
  final double diameter;

  const BackgroundShape({
    super.key,
    required this.color,
    required this.diameter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
