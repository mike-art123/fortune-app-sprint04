import '../../fortunes/domain/fal_input.dart';

/// Maps the typed [FalInput] onto the API contract:
/// { fortuneId, input: { ... } }. The wire shape lives only here.
abstract final class FalInputPayload {
  static Map<String, dynamic> toJson(FalInput input) => {
    'fortuneId': input.fortuneId,
    'input': switch (input) {
      IntentionInput(:final intention) => {
        if (intention != null) 'intention': intention,
      },
      DreamInput(:final narration) => {'narration': narration},
      LoveInput(:final selfName, :final otherName) => {
        'selfName': selfName,
        'otherName': otherName,
      },
    },
  };
}
