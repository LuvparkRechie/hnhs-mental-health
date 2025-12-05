class Conversation {
  final String id;
  final String userId;
  final String message;
  final DateTime timestamp;
  final bool isUser;
  final double? suicideRiskScore;
  final bool? flaggedForReview;

  Conversation({
    required this.id,
    required this.userId,
    required this.message,
    required this.timestamp,
    required this.isUser,
    this.suicideRiskScore,
    this.flaggedForReview,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['created_date']),
      isUser: json['isUser'] ?? true,
      suicideRiskScore: json['suicideRiskScore']?.toDouble(),
      flaggedForReview: json['flaggedForReview'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'message': message,
      'created_date': timestamp.toIso8601String(),
      'isUser': isUser,
      'suicideRiskScore': suicideRiskScore,
      'flaggedForReview': flaggedForReview,
    };
  }
}
