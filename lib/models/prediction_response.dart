class PredictionResponse {
  final String action;
  final double confidence;

  PredictionResponse({
    required this.action,
    required this.confidence,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    return PredictionResponse(
      action: json['action'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}
