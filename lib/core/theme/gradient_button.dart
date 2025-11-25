import 'package:flutter/material.dart';
import 'app_colors.dart';

/// A custom elevated button with blue gradient background
class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final BorderRadius? borderRadius;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return Material(
      elevation: elevation ?? 0,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isDisabled
                ? LinearGradient(
                    colors: [Colors.grey.shade300, Colors.grey.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [
                      AppColors.capizBlue,
                      Color(0xFF2196F3), // Lighter blue
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: borderRadius ?? BorderRadius.circular(16),
          ),
          child: Container(
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            alignment: Alignment.center,
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Extension to easily create gradient buttons
extension GradientButtonExtension on ElevatedButton {
  static Widget gradient({
    required VoidCallback? onPressed,
    required Widget child,
    EdgeInsetsGeometry? padding,
    double? elevation,
    BorderRadius? borderRadius,
  }) {
    return GradientButton(
      onPressed: onPressed,
      padding: padding,
      elevation: elevation,
      borderRadius: borderRadius,
      child: child,
    );
  }
}
