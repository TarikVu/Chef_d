// Class representing a Tag.
// Primarily used for parsing a Json Response inside of the create_recipe.dart file.

class Tag {
  // Primary Key:
  final int id;

  // Allergen name
  final String label;

  const Tag({
    required this.id,
    required this.label,
  });

  // Parse from json:
  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as int,
      label: json['label'] as String,
    );
  }
}
