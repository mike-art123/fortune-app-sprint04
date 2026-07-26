import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/navigation/app_back.dart';

/// The app's single app bar. Calm and RTL-correct: when the current route can
/// be left it shows exactly one back control on the leading (right, in Persian)
/// edge, routed through [AppBack] so this button, the Telegram BackButton and
/// browser/system back always agree. On a stack root it shows no leading —
/// never a stray or dead control.
///
/// The leading is Flutter's [BackButton], so it keeps the platform icon,
/// RTL mirroring, the localized tooltip/semantics and a 48px touch target;
/// only its action is redirected to the shared handler (which also falls back
/// to Explore when there is no previous route, e.g. a cold deep link).
class FortuneAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FortuneAppBar({super.key, this.title});

  final Widget? title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = GoRouter.of(context).canPop();
    final location = GoRouterState.of(context).uri.path;
    final showBack = AppBack.showBack(location: location, canPop: canPop);
    return AppBar(
      title: title,
      automaticallyImplyLeading: false,
      leading: showBack
          ? BackButton(onPressed: () => AppBack.goBack(context))
          : null,
    );
  }
}
