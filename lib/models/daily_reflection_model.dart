class DailyReflectionModel {
  final String id;
  final String userId;
  final DateTime date;
  final String verseId;
  final String reflectionText;
  final String mood;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyReflectionModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.verseId,
    required this.reflectionText,
    this.mood = 'peaceful',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'date': date.toIso8601String(),
    'verseId': verseId,
    'reflectionText': reflectionText,
    'mood': mood,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory DailyReflectionModel.fromJson(Map<String, dynamic> json) => DailyReflectionModel(
    id: json['id'] ?? '',
    userId: json['userId'] ?? '',
    date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    verseId: json['verseId'] ?? '',
    reflectionText: json['reflectionText'] ?? '',
    mood: json['mood'] ?? 'peaceful',
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
  );

  DailyReflectionModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? verseId,
    String? reflectionText,
    String? mood,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DailyReflectionModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    date: date ?? this.date,
    verseId: verseId ?? this.verseId,
    reflectionText: reflectionText ?? this.reflectionText,
    mood: mood ?? this.mood,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
