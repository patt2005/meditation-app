class Story {
  final String id;
  final DateTime createdAt;
  final String prompt;
  final String imagePath;
  final Map<int, String> userResponses;
  final String? title;
  final bool isFavorite;

  Story({
    required this.id,
    required this.createdAt,
    required this.prompt,
    required this.imagePath,
    required this.userResponses,
    this.title,
    this.isFavorite = false,
  });

  // Create a Story from JSON (for persistence)
  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      prompt: json['prompt'] as String,
      imagePath: json['imagePath'] as String,
      userResponses: Map<int, String>.from(json['userResponses'] as Map),
      title: json['title'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  // Convert Story to JSON (for persistence)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'prompt': prompt,
      'imagePath': imagePath,
      'userResponses': userResponses,
      'title': title,
      'isFavorite': isFavorite,
    };
  }

  // Create a copy with updated fields
  Story copyWith({
    String? id,
    DateTime? createdAt,
    String? prompt,
    String? imagePath,
    Map<int, String>? userResponses,
    String? title,
    bool? isFavorite,
  }) {
    return Story(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      prompt: prompt ?? this.prompt,
      imagePath: imagePath ?? this.imagePath,
      userResponses: userResponses ?? this.userResponses,
      title: title ?? this.title,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Story &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}