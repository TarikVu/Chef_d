import 'ingredient.dart';

class Recipe {
  /// Primary key identifier for a recipe.
  int id;

  /// The name of the recipe.
  String title;

  /// Image file path of recipe.
  String image;

  /// Date of when recipe was created.
  DateTime date;

  /// Difficulty rating of the recipe.
  int diff;

  /// Total time required to make recipe.
  /// Prep + Cook time.
  int totalTime;

  /// The original source website of the recipe.
  String source;

  /// The rating of the recipe. Review average.
  double rating;

  double popularity;

  /// Total number of calories of recipe.
  int? calories;

  /// Amount of people the recipe will serve/feed.
  double? servings;

  /// Author and creator of the recipe.
  String author;

  /// Time needed to prepare the recipe.
  int? prepTime;

  /// Description of the recipe.
  String desc;

  /// Estimated time (in minutes) needed to make recipe.
  int? cookTime;

  int? carbs;

  int? cholesterol;

  int? fiber;

  int? protein;

  /// Saturated fat
  int? satFat;

  int? sodium;

  int? sugar;

  int? fat;

  /// Unsaturated fat
  int? unFat;

  /// Map of ingredient and the amount as a string.
  final Map<Ingredient, String> ingredients;

  /// Directions <step number, direction itself>
  final Map<int, String> directions;

  Recipe(
      this.id,
      this.title,
      this.image,
      this.diff,
      this.date,
      this.totalTime,
      this.source,
      this.rating,
      this.popularity,
      this.calories,
      this.servings,
      this.author,
      this.prepTime,
      this.desc,
      this.cookTime,
      this.carbs,
      this.cholesterol,
      this.fiber,
      this.protein,
      this.satFat,
      this.sodium,
      this.sugar,
      this.fat,
      this.unFat,
      this.ingredients,
      this.directions);

  static Recipe setRecipe(Map<dynamic, dynamic> r) {
    return Recipe(
        r['id'],
        r['title'],
        r['image'],
        r['difficulty'],
        DateTime.now(),
        r['total_time'],
        r['source'],
        double.parse(r['rating'].toString()),
        double.parse(r['popularity'].toString()),
        r['calories'],
        double.parse(r['servings'].toString()),
        r['author'],
        r['prep_time'],
        r['description'],
        r['cook_time'],
        r['carbs'],
        r['cholesterol'],
        r['fiber'],
        r['protein'],
        r['saturated_fat'],
        r['sodium'],
        r['sugar'],
        r['fat'],
        r['unsaturated_fat'], {}, {});
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recipe && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
