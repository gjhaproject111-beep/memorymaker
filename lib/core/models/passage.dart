import 'enums.dart';

class Passage {
  final String id;
  final String title;
  final PassageCategory category;
  final PassageDifficulty difficulty;
  final String text;
  final bool isBuiltIn;

  Passage({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.text,
    this.isBuiltIn = true,
  });

  /// Whitespace-delimited word count — the same tokenization rule the
  /// comparison engine uses, so the number shown here always matches.
  int get wordCount => text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'difficulty': difficulty.name,
        'text': text,
        'isBuiltIn': isBuiltIn,
      };

  factory Passage.fromJson(Map<String, dynamic> json) => Passage(
        id: json['id'] as String,
        title: json['title'] as String,
        category: PassageCategoryX.fromName(json['category'] as String),
        difficulty: PassageDifficultyX.fromName(json['difficulty'] as String),
        text: json['text'] as String,
        isBuiltIn: json['isBuiltIn'] as bool? ?? true,
      );
}
