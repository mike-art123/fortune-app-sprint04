/// Mirrors the backend envelope `{ success, data, error, requestId }` (doc 33).
/// Kept in the data layer — domain entities never see wire format.
class ApiEnvelope {
  const ApiEnvelope({
    required this.success,
    this.data,
    this.errorCode,
    this.errorMessage,
    this.requestId,
    this.meta,
  });

  final bool success;
  final Map<String, dynamic>? data;
  final String? errorCode;
  final String? errorMessage;
  final String? requestId;
  final Map<String, dynamic>? meta;

  static ApiEnvelope fromJson(Map<String, dynamic> json) {
    final error = json['error'];
    return ApiEnvelope(
      success: json['success'] == true,
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : null,
      errorCode: error is Map ? error['code'] as String? : null,
      errorMessage: error is Map ? error['message'] as String? : null,
      requestId: json['requestId'] as String?,
      meta: json['meta'] is Map<String, dynamic>
          ? json['meta'] as Map<String, dynamic>
          : null,
    );
  }
}
