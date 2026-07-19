import 'package:flutter/material.dart';
import '../../design_system/foundations/app_breakpoints.dart';

/// Constrains content to a comfortable reading width on wide screens.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth});
  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? AppBreakpoints.maxReadableWidth),
          child: child,
        ),
      );
}
