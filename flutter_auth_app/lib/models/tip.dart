// lib/models/tip.dart

class Tip {
  final int id;
  final String category;
  final String icon;
  final String title;
  final String description;

  Tip({
    required this.id,
    required this.category,
    required this.icon,
    required this.title,
    required this.description,
  });

  factory Tip.fromJson(Map<String, dynamic> json) {
    return Tip(
      id: json['id'],
      category: json['category'],
      icon: json['icon'],
      title: json['title'],
      description: json['description'],
    );
  }
}