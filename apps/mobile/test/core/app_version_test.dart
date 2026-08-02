import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/core/config/app_flavor.dart';
import 'package:fortune_app/core/config/environment_loader.dart';

/// The version the app shows on the About screen, and reports in every
/// request's client-version header, now comes from two `--dart-define`s so an
/// iOS build can finally say what TestFlight says.
///
/// This test is the guard on the other side of that change. It runs with no
/// defines at all — exactly how the web bundle and the Play job compile today
/// — and pins the fallback to the constants those builds have always produced.
/// If the fallback ever drifts, web and Android would start reporting a
/// different version than they do now, and this goes red first.
void main() {
  test('with no defines the app reports what it always has', () {
    final config = EnvironmentLoader.load(AppFlavor.production);

    expect(config.appVersion, '0.1.0');
    expect(config.buildNumber, '1');
  });
}
