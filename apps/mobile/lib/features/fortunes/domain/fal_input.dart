import 'package:flutter/material.dart';
import '../../../shared/models/localized_text.dart';
import 'fortune_definition.dart';

/// Typed user offering for a fortune (Sprint 01 requirement).
/// One sealed hierarchy — the reading pipeline never receives raw maps.
sealed class FalInput {
  const FalInput({required this.fortuneId});
  final String fortuneId;
}

/// Optional short intention (Hafez, Tarot). Empty is a valid, quiet offering.
final class IntentionInput extends FalInput {
  const IntentionInput({required super.fortuneId, this.intention});
  final String? intention;
}

/// Required long narration (Dream).
final class DreamInput extends FalInput {
  const DreamInput({required super.fortuneId, required this.narration});
  final String narration;
}

/// Two required names (Love).
final class LoveInput extends FalInput {
  const LoveInput({
    required super.fortuneId,
    required this.selfName,
    required this.otherName,
  });
  final String selfName;
  final String otherName;
}

/// Outcome of gentle validation: either the offering is ready, or the user
/// receives calm guidance (never an error, never blame).
sealed class OfferingOutcome {
  const OfferingOutcome();
}

final class OfferingReady extends OfferingOutcome {
  const OfferingReady(this.input);
  final FalInput input;
}

final class OfferingNeedsMore extends OfferingOutcome {
  const OfferingNeedsMore(this.guidance);
  final LocalizedText guidance;
}

/// Builds and validates a [FalInput] from raw field values, driven entirely by
/// the fortune's registry definition — no per-fortune logic in widgets.
abstract final class FalInputFactory {
  static const _fallbackGuide = LocalizedText(
    fa: 'برای ادامه، همین‌جا چند کلمه بنویس.',
    en: 'A few words here are enough to continue.',
  );

  static OfferingOutcome build({
    required FortuneDefinition fortune,
    String primary = '',
    String secondary = '',
  }) {
    final first = primary.trim();
    final second = secondary.trim();

    switch (fortune.inputKind) {
      case FortuneInputKind.intention:
        return OfferingReady(
          IntentionInput(
            fortuneId: fortune.id,
            intention: first.isEmpty ? null : first,
          ),
        );

      case FortuneInputKind.longText:
        final words = first.isEmpty ? 0 : first.split(RegExp(r'\s+')).length;
        if (words < (fortune.minWords ?? 1)) {
          return OfferingNeedsMore(fortune.guide ?? _fallbackGuide);
        }
        return OfferingReady(
          DreamInput(fortuneId: fortune.id, narration: first),
        );

      case FortuneInputKind.twoNames:
        if (first.isEmpty || second.isEmpty) {
          return OfferingNeedsMore(fortune.guide ?? _fallbackGuide);
        }
        return OfferingReady(
          LoveInput(fortuneId: fortune.id, selfName: first, otherName: second),
        );

      case FortuneInputKind.photo:
        // Photo offerings arrive in a later sprint; the registry keeps these
        // families marked `soon`, so entry never reaches this branch.
        return OfferingNeedsMore(_fallbackGuide);
    }
  }
}

/// Debug-friendly description without leaking personal content into logs.
extension FalInputRedacted on FalInput {
  String get redactedDescription => switch (this) {
        IntentionInput(intention: final i) => 'IntentionInput(${i == null ? 'silent' : 'written'})',
        DreamInput() => 'DreamInput([redacted])',
        LoveInput() => 'LoveInput([redacted])',
      };
}
