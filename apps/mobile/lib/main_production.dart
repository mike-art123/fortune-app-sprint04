import 'app/app.dart';
import 'app/bootstrap/bootstrap.dart';
import 'core/config/app_flavor.dart';

Future<void> main() => bootstrap(
      flavor: AppFlavor.production,
      builder: () => const FortuneApp(),
    );
