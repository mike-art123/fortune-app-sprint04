import 'dart:convert';

import 'package:image_picker/image_picker.dart';

/// Native capture for the coffee ritual (the Play build): the camera first —
/// mirroring the web input's `capture="environment"` — and the photo picker
/// as a fallback when no camera can serve (emulator, stripped device). The
/// picker itself downscales to the same 1080px / JPEG budget the web canvas
/// uses, and the return value is the identical data-URL contract. A cancel
/// returns null so the caller simply asks again; nothing is ever stored.
const double _maxDimension = 1080;
const int _jpegQuality = 82;

Future<String?> captureCupPhotoAndroid() async {
  final picker = ImagePicker();
  try {
    return await _pick(picker, ImageSource.camera);
  } catch (_) {
    // No usable camera — offer the gallery instead.
  }
  try {
    return await _pick(picker, ImageSource.gallery);
  } catch (_) {
    return null;
  }
}

Future<String?> _pick(ImagePicker picker, ImageSource source) async {
  final file = await picker.pickImage(
    source: source,
    maxWidth: _maxDimension,
    maxHeight: _maxDimension,
    imageQuality: _jpegQuality,
  );
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  return 'data:image/jpeg;base64,${base64Encode(bytes)}';
}

/// Straight to the photo library — the separate "from gallery" button.
Future<String?> pickCupPhotoGalleryAndroid() async {
  try {
    return await _pick(ImagePicker(), ImageSource.gallery);
  } catch (_) {
    return null;
  }
}
