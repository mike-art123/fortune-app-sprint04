import '../config/android_bridges_switch.dart';
import 'cup_photo_io.dart';

/// Non-web resolution. The Play build (ENABLE_ANDROID_BRIDGES) captures the
/// cup through the native camera / photo picker; every other non-web target —
/// analyze, `flutter test`, desktop — returns null so the caller asks for the
/// photo again rather than crash. The web build never loads this file (see
/// the conditional export in `cup_photo.dart`).
Future<String?> captureCupPhoto() => kAndroidBridgesEnabled
    ? captureCupPhotoAndroid()
    : Future<String?>.value(null);
