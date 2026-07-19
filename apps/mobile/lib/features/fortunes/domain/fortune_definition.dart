import 'package:flutter/material.dart';
import '../../../shared/models/localized_text.dart';

/// How a fortune gathers its offering from the user.
enum FortuneInputKind {
  /// Optional short intention (Hafez, Tarot).
  intention,

  /// Required long narration (Dream).
  longText,

  /// Two required names joined by a bond (Love).
  twoNames,

  /// Requires a photo — arrives in a later sprint (Coffee).
  photo,
}

enum FortuneAvailability { available, soon }

/// Per-family motion pace: ritual entries breathe at their own rhythm.
class RitualPace {
  const RitualPace({required this.enter, required this.step});
  final Duration enter;
  final Duration step;
}

/// A single fortune family. The registry is the ONLY source of truth for
/// fortune behavior — UI renders whatever is described here (Sprint-01 rule:
/// no hardcoded fortune behavior in widgets).
@immutable
class FortuneDefinition {
  const FortuneDefinition({
    required this.id,
    required this.accent,
    required this.inputKind,
    required this.title,
    required this.subtitle,
    required this.ritualLine,
    required this.cta,
    required this.pace,
    this.placeholder,
    this.placeholderSecond,
    this.guide,
    this.privacy,
    this.minWords,
    this.maxLength = 300,
    this.availability = FortuneAvailability.available,
  });

  final String id;

  /// Family accent (from CategoryAccents). One dominant accent per screen.
  final Color accent;

  final FortuneInputKind inputKind;
  final LocalizedText title;
  final LocalizedText subtitle;

  /// The single calm line that opens the ritual.
  final LocalizedText ritualLine;

  final LocalizedText cta;
  final RitualPace pace;

  /// Whisper placeholder(s). Second is used by [FortuneInputKind.twoNames].
  final LocalizedText? placeholder;
  final LocalizedText? placeholderSecond;

  /// Gentle guidance when a required offering is missing — never an "error".
  final LocalizedText? guide;

  /// Quiet privacy reassurance for sensitive offerings.
  final LocalizedText? privacy;

  /// Minimum meaningful words for [FortuneInputKind.longText].
  final int? minWords;

  final int maxLength;
  final FortuneAvailability availability;

  bool get isAvailable => availability == FortuneAvailability.available;
}
