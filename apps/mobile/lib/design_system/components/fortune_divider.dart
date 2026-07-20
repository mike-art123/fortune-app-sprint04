import 'package:flutter/material.dart';
import '../../design_system/theme/fortune_theme_extension.dart';
import '../foundations/app_opacity.dart';

class FortuneDivider extends StatelessWidget {
  const FortuneDivider({super.key});

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    thickness: 1,
    color: context.fortuneColors.borderSubtle.withValues(
      alpha: AppOpacity.hairline,
    ),
  );
}
