import 'package:flutter/material.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../design_system/components/fortune_scaffold.dart';
import '../../../../shared/widgets/placeholder_view.dart';

class ProfilePlaceholderPage extends StatelessWidget {
  const ProfilePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return FortuneScaffold(
      appBar: AppBar(title: Text(s.profileTitle)),
      child: PlaceholderView(title: s.profileTitle),
    );
  }
}
