import 'package:chefd_app/models/ingredient.dart';

class RecipeIngredients {
  int recipeID;

  double amount;

  String unit;

  String fullText;

  int ingrID;

  Ingredient ingr;

  RecipeIngredients(this.recipeID, this.amount, this.unit, this.fullText,
      this.ingrID, this.ingr);

  /// Returns a list of RecipeIngredients. Takes in the recipeID
  /// and the result of query.
  static List<RecipeIngredients> getIngrList(
      List<dynamic> ingrs, int recipeID) {
    List<RecipeIngredients> l = [];
    for (int i = 0; i < ingrs.length; i++) {
      dynamic curIngr = ingrs[i];
      l.add(RecipeIngredients(
          recipeID,
          double.parse(
              double.parse(curIngr['amount'].toString()).toStringAsFixed(2)),
          curIngr['unit'],
          curIngr['full_text'],
          curIngr['ingredient_id'],
          Ingredient(curIngr['ingredients']['label'])));
    }
    return l;
  }
}
