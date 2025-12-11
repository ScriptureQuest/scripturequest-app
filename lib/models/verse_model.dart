class VerseModel {
  final String id;
  final String reference;
  final String text;
  final String category;
  final int xpReward;
  final int difficulty;
  final bool isCompleted;
  final DateTime? completedAt;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  VerseModel({
    required this.id,
    required this.reference,
    required this.text,
    required this.category,
    this.xpReward = 10,
    this.difficulty = 1,
    this.isCompleted = false,
    this.completedAt,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'reference': reference,
    'text': text,
    'category': category,
    'xpReward': xpReward,
    'difficulty': difficulty,
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory VerseModel.fromJson(Map<String, dynamic> json) => VerseModel(
    id: json['id'] ?? '',
    reference: json['reference'] ?? '',
    text: json['text'] ?? '',
    category: json['category'] ?? 'faith',
    xpReward: json['xpReward'] ?? 10,
    difficulty: json['difficulty'] ?? 1,
    isCompleted: json['isCompleted'] ?? false,
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    notes: json['notes'] ?? '',
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
  );

  VerseModel copyWith({
    String? id,
    String? reference,
    String? text,
    String? category,
    int? xpReward,
    int? difficulty,
    bool? isCompleted,
    DateTime? completedAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => VerseModel(
    id: id ?? this.id,
    reference: reference ?? this.reference,
    text: text ?? this.text,
    category: category ?? this.category,
    xpReward: xpReward ?? this.xpReward,
    difficulty: difficulty ?? this.difficulty,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAt: completedAt ?? this.completedAt,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
