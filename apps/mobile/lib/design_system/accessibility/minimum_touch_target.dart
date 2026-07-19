import 'package:flutter/material.dart';

/// Enforces the 44x44 minimum touch target (doc 51 §34).
class MinimumTouchTarget extends StatelessWidget {
  const MinimumTouchTarget({super.key, required this.child, this.size = 44});
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(minWidth: size, minHeight: size),
        child: Center(child: child),
      );
}
