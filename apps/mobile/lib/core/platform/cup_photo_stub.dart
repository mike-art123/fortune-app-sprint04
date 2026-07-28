// Non-web builds (analyze, `flutter test`, native) never capture a cup photo —
// the coffee fortune is a web-only ritual. Returning null makes the caller ask
// for the photo again rather than crash.
Future<String?> captureCupPhoto() => Future<String?>.value(null);
