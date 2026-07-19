import 'validation_result.dart';

/// Shared input validators (doc 51 §36.1).
abstract final class Validators {
  static ValidationResult required(String? value, {String messageKey = 'validationRequired'}) {
    return (value == null || value.trim().isEmpty)
        ? ValidationResult.invalid(messageKey)
        : const ValidationResult.valid();
  }

  static ValidationResult minLength(String? value, int min,
      {String messageKey = 'validationTooShort'}) {
    return (value == null || value.trim().length < min)
        ? ValidationResult.invalid(messageKey)
        : const ValidationResult.valid();
  }

  static ValidationResult maxLength(String? value, int max,
      {String messageKey = 'validationTooLong'}) {
    return (value != null && value.characters > max)
        ? ValidationResult.invalid(messageKey)
        : const ValidationResult.valid();
  }
}

extension on String {
  int get characters => runes.length;
}
