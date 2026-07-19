import 'package:flutter/material.dart';

class KeyboardDismiss extends StatelessWidget {
  const KeyboardDismiss({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: child,
      );
}
