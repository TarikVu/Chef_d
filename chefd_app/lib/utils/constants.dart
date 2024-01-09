import 'package:flutter/material.dart';
import '/theme/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//Supabase client
final supabase = Supabase.instance.client;

String userId = '';
User? user = supabase.auth.currentUser;

extension ShowSnackBar on BuildContext {
  void showErrorMessage(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: red),
      ),
      backgroundColor: grey,
    ));
  }
}

String krogerClientId =
    "chefd-4c1b19e6fa91623bf185fa77468702719051561562194413564";
String krogerClientSecret = "9E50_hMfp2Pq2OrmFvDgCWhy-dVYCuQ6V0K8h80b";

String krogerEncoded =
    "Y2hlZmQtNGMxYjE5ZTZmYTkxNjIzYmYxODVmYTc3NDY4NzAyNzE5MDUxNTYxNTYyMTk0NDEzNTY0OjlFNTBfaE1mcDJQcTJPcm1GdkRnQ1doeS1kVllDdVE2VjBLOGg4MGI=";

String krogerCartURL = "";
const double divHeight = 18;

const double basePadding = 10.0;

const double buttonWidthSpacing = 5;

/// user_id NOTE: This userid points to test@gmail.com
const String jax = 'bbe4d1ea-1c59-4a2a-bcce-8ebe0884ae50';
const String tarik = "5a64de94-9a52-45bd-80a1-0b0ec3b4bc50";

// The name of all tables. Useful for when access .from('') supabase.
const String allergiesDiets = 'allergies_diets';

const String comments = 'comments';

const String favorites = 'favorites';

const String follows = 'follows';

const String ingredients = 'ingredients';

const String mealPlans = 'meal_plans';

const String mealPlansRecipes = 'meal_plan_recipes';

const String pantry = 'pantry';

const String posts = 'posts';

const String recipeAllergiesDiets = 'recipe_allergies_diets';

const String recipeIngredients = 'recipe_ingredients';

const String recipeReviews = 'recipe_reviews';

const String recipeSteps = 'recipe_steps';

const String recipeTags = 'recipe_tags';

const String recipes = 'recipes';

const String shoppingCart = 'shopping_cart';

const String tags = 'tags';

const String userAllergiesDiets = 'user_allergies_diets';

const String userPreferences = 'user_preferences';

const String userInfo = 'userinfo';

int currentBotNavIndex = 0;

/// Used to build label and responding text on the Recipe page.
class TextLabel extends StatelessWidget {
  String label;
  Color clr;
  double fontSize;
  bool bold;

  /// Constructor = name of label (string + ':'), color (Color), font size (double), and bold (bool).
  /// Example: TextLabel("example label:", primaryOrange, 12.0, true);
  TextLabel(this.label, this.clr, this.fontSize, this.bold);

  @override
  Widget build(BuildContext context) {
    const SizedBox(height: 5.0);
    if (bold) {
      return Text(
        textAlign: TextAlign.center,
        label,
        style: TextStyle(
          color: clr,
          letterSpacing: 2.0,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (label.toString() == "N/A") {
      return const Text("");
    } else {
      return Text(
        textAlign: TextAlign.center,
        label,
        style: TextStyle(
          color: clr,
          letterSpacing: 2.0,
          fontSize: fontSize,
        ),
      );
    }
  }
}
