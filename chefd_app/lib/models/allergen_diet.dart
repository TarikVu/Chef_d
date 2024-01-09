// Class representing an Allergen.
// Note the supabase Table that supports allergens has a third col
// "is_allergy" because that table holds Allergens and diet types.
// This class omits the third field.

class AllergenDiet {
  // Primary Key:
  final int id;

  // Allergen name
  final String label;

  final bool is_allergy;

  const AllergenDiet({
    required this.id,
    required this.label,
    required this.is_allergy,
  });

  // Parse from json:
  factory AllergenDiet.fromJson(Map<String, dynamic> json) {
    return AllergenDiet(
      id: json['id'] as int,
      label: json['label'] as String,
      is_allergy: json['is_allergy'] as bool,
    );
  }
}
