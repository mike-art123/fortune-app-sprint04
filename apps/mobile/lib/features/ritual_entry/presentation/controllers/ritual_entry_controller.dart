import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/localized_text.dart';
import '../../../fortunes/domain/fal_input.dart';
import '../../../fortunes/domain/fortune_definition.dart';

/// UI state of a ritual entry (doc 51 §4.3 — explicit states, no bool soup).
class RitualEntryState {
  const RitualEntryState({this.guidance});

  /// Gentle guidance to show under the offering — null means all is calm.
  final LocalizedText? guidance;

  RitualEntryState copyWith({
    LocalizedText? guidance,
    bool clearGuidance = false,
  }) => RitualEntryState(
    guidance: clearGuidance ? null : (guidance ?? this.guidance),
  );
}

/// Holds validation state for one fortune's ritual entry. Widgets stay free of
/// business logic; the registry-driven factory decides everything.
class RitualEntryController extends FamilyNotifier<RitualEntryState, String> {
  @override
  RitualEntryState build(String arg) => const RitualEntryState();

  /// Attempts to seal the offering. Returns the typed input when ready;
  /// otherwise stores gentle guidance and returns null.
  FalInput? seal({
    required FortuneDefinition fortune,
    required String primary,
    required String secondary,
  }) {
    final outcome = FalInputFactory.build(
      fortune: fortune,
      primary: primary,
      secondary: secondary,
    );
    switch (outcome) {
      case OfferingReady(:final input):
        state = state.copyWith(clearGuidance: true);
        return input;
      case OfferingNeedsMore(:final guidance):
        state = state.copyWith(guidance: guidance);
        return null;
    }
  }

  void soften() {
    if (state.guidance != null) state = state.copyWith(clearGuidance: true);
  }
}

final ritualEntryControllerProvider =
    NotifierProvider.family<RitualEntryController, RitualEntryState, String>(
      RitualEntryController.new,
    );
