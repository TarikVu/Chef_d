/// This file contains various functions for interacting with the database (DB) in the chefd_app.
/// It includes functions for inserting ingredients into the shopping cart from recipes or meal plans,
/// fetching recipes and meal plans, updating meal plans, deleting meal plans and events,
/// retrieving monthly nutrition, and more.
/// The functions in this file utilize the Supabase library for database operations.

// ignore_for_file: file_names

import 'package:chefd_app/utils/constants.dart';
import 'package:intl/intl.dart';

//given a list of ingredients, insert them into the shopping cart table
Future<void> insertIngrsToShoppingCartFromRecipes(List<dynamic> recipes) async {
  //for now just delete all the ingredients in the shopping cart
  await supabase.from('shopping_cart').delete().match({"user_id": userId});

  for (int i = 0; i < recipes.length; i++) {
    final ingredients = await supabase
        .from('recipe_ingredients')
        .select("ingredient_id, amount, unit")
        .match({"recipe_id": recipes[i]['id']});

    for (int j = 0; j < ingredients.length; j++) {
      await supabase.from('shopping_cart').insert({
        //default user id to 0 for now.
        'user_id': userId,
        'ingredient_id': ingredients[j]['ingredient_id'],
        'unit': ingredients[j]['unit'],
        'amount': ingredients[j]['amount'],
        'done': false,
        'recipe_id': recipes[i]['id']
      });
    }
  }
}

Future<void> insertIngrsToShoppingCartFromMealPlan(int mealPlanID) async {
  //for now just delete all the ingredients in the shopping cart
  await supabase.from('shopping_cart').delete().match({"user_id": userId});

  final recipes = await supabase
      .from('meal_plans_recipes')
      .select("recipes(id)")
      .match({"meal_plan_id": mealPlanID});

  for (int i = 0; i < recipes.length; i++) {
    final ingredients = await supabase
        .from('recipe_ingredients')
        .select("ingredient_id, amount, unit")
        .match({"recipe_id": recipes[i]['recipes']['id']});

    for (int j = 0; j < ingredients.length; j++) {
      await supabase.from('shopping_cart').insert({
        //default user id to 0 for now.
        'user_id': userId,
        'ingredient_id': ingredients[j]['ingredient_id'],
        'unit': ingredients[j]['unit'],
        'amount': ingredients[j]['amount'],
        'done': false,
        'recipe_id': recipes[i]['recipes']['id']
      });
    }
  }
}

Future<List<dynamic>> fetchRecipes() async {
  final data =
      await supabase.from('recipes').select('id, title, image').limit(20);
  return data;
}

Future<List<dynamic>> fetchRecipesInOrder() async {
  final data = await supabase
      .from('random_recipes')
      .select('id, title, image')
      .limit(20);
  return data.reversed.toList();
}

Future<List<dynamic>> fetchRandomRecipes() async {
  final data = await supabase
      .from('random_recipes')
      .select('id, title, image')
      .limit(20);
  return data;
}

Future<void> updateMade(int id, bool made) async {
  await supabase
      .from('user_current_meal_plan')
      .update({'made': made}).match({'id': id});
}

//checkMade
Future<List<dynamic>> checkMade(int id) async {
  await Future.delayed(const Duration(milliseconds: 50), () {});
  final data = await supabase
      .from('user_current_meal_plan')
      .select('made')
      .match({'id': id});
  return data;
}

Future<List<dynamic>> fetchLiked() async {
  final data = await supabase
      .from('favorites')
      .select('recipes(id, title, image)')
      .match({'user_id': userId});
  return data;
}

Future<List<dynamic>> fetchCurrentMealPlan() async {
  final currentMealPlan = await supabase
      .from('meal_plans')
      .select(
          'carbs, cholesterol, fiber, protein, saturated_fat, sodium, sugar, fat, meal_plans_recipes(recipes(id, title, image))')
      .match({'user_id': userId, 'current': true});

  if (currentMealPlan.length == 0) {
    return [];
  }
  return currentMealPlan;
}

Future<List<dynamic>> fetchMealplans() async {
  final data = await supabase
      .from('meal_plans')
      .select('id, label')
      .match({'user_id': userId, 'temporary': false});
  return data;
}

Future<bool> makeMealPlanFromNew(List recipes) async {
  await supabase
      .from('meal_plans')
      .update({'current': false}).match({"user_id": userId, "current": true});

  await supabase
      .from('meal_plans')
      .delete()
      .match({"user_id": userId, "temporary": true});

  final data = await supabase.from('meal_plans').insert({
    "user_id": userId,
    "label": "Temporary Meal Plan",
    "current": true,
    "temporary": true
  }).select('id');

  num carbs = 0;
  num cholesterol = 0;
  num fiber = 0;
  num protein = 0;
  num saturatedFat = 0;
  num sodium = 0;
  num sugar = 0;
  num fat = 0;
  for (int i = 0; i < recipes.length; i++) {
    final nutrition = await supabase
        .from('recipes')
        .select(
            "carbs, cholesterol, fiber, protein, saturated_fat, sodium, sugar, fat")
        .match({"id": recipes[i]['id']});

    carbs += nutrition[0]['carbs'];
    cholesterol += nutrition[0]['cholesterol'];
    fiber += nutrition[0]['fiber'];
    protein += nutrition[0]['protein'];
    saturatedFat += nutrition[0]['saturated_fat'];
    sodium += nutrition[0]['sodium'];
    sugar += nutrition[0]['sugar'];
    fat += nutrition[0]['fat'];
  }

  await supabase.from('meal_plans').update({
    "carbs": carbs,
    "cholesterol": cholesterol,
    "fiber": fiber,
    "protein": protein,
    "saturated_fat": saturatedFat,
    "sodium": sodium,
    "sugar": sugar,
    "fat": fat
  }).match({"id": data[0]['id']});

  for (int i = 0; i < recipes.length; i++) {
    await supabase
        .from('meal_plans_recipes')
        .insert({"meal_plan_id": data[0]['id'], "recipe_id": recipes[i]['id']});
  }
  return true;
}

Future<void> updateMealPlanNameAndTemporary(String name) async {
  await supabase
      .from('meal_plans')
      .update({'temporary': false, "label": name}).match(
          {"user_id": userId, "current": true});
}

Future<List<dynamic>> fetchMealPlanRecipes(int id) async {
  final data = await supabase
      .from('meal_plans_recipes')
      .select('recipes(id, title, image)')
      .match({'meal_plan_id': id});
  return data;
}

Future<Map<String, dynamic>> getCurrentMealPlanNutrition() async {
  final data = await supabase
      .from('meal_plans')
      .select(
          "carbs, cholesterol, fiber, protein, saturated_fat, sodium, sugar, fat, unsaturated_fat")
      .match({"user_id": userId, "current": true});

  if (data.length == 0) {
    return {
      "carbs": 0,
      "cholesterol": 0,
      "fiber": 0,
      "protein": 0,
      "saturated_fat": 0,
      "sodium": 0,
      "sugar": 0,
      "fat": 0,
      "unsaturated_fat": 0
    };
  }

  return data[0];
}

Future<void> updateMealPlan(List recipes, int mealPlanID) async {
  final data = await supabase
      .from('meal_plans_recipes')
      .delete()
      .match({"meal_plan_id": mealPlanID});

  num carbs = 0;
  num cholesterol = 0;
  num fiber = 0;
  num protein = 0;
  num saturatedFat = 0;
  num sodium = 0;
  num sugar = 0;
  num fat = 0;
  for (int i = 0; i < recipes.length; i++) {
    final nutrition = await supabase
        .from('recipes')
        .select(
            "carbs, cholesterol, fiber, protein, saturated_fat, sodium, sugar, fat")
        .match({"id": recipes[i]['id']});

    carbs += nutrition[0]['carbs'];
    cholesterol += nutrition[0]['cholesterol'];
    fiber += nutrition[0]['fiber'];
    protein += nutrition[0]['protein'];
    saturatedFat += nutrition[0]['saturated_fat'];
    sodium += nutrition[0]['sodium'];
    sugar += nutrition[0]['sugar'];
    fat += nutrition[0]['fat'];
  }

  await supabase.from('meal_plans').update({
    "carbs": carbs,
    "cholesterol": cholesterol,
    "fiber": fiber,
    "protein": protein,
    "saturated_fat": saturatedFat,
    "sodium": sodium,
    "sugar": sugar,
    "fat": fat
  }).match({"id": mealPlanID});

  for (int i = 0; i < recipes.length; i++) {
    await supabase
        .from('meal_plans_recipes')
        .insert({"meal_plan_id": mealPlanID, "recipe_id": recipes[i]['id']});
  }
}

Future<void> deleteMealPlan(int mealPlanID) async {
  await supabase.from('meal_plans').delete().match({"id": mealPlanID});
}

Future<bool> updateCurrentMealPlanFromExistingMealPlan(int mealPlanID) async {
  await supabase
      .from('meal_plans')
      .update({'current': false}).match({"user_id": userId, "current": true});

  await supabase
      .from('meal_plans')
      .delete()
      .match({"user_id": userId, "temporary": true});

  await supabase
      .from('meal_plans')
      .update({"current": true}).match({"id": mealPlanID});

  return true;
}

Future<List<dynamic>> retreiveMealCalendar() async {
  return await supabase
      .from('meal_plans')
      .select('id, label, current')
      .match({'user_id': userId, 'temporary': false});
}

Future<void> insertMealIntoCalendar(int recipeID) async {
  await supabase.from('meal_calendar').insert(
      {"user_id": userId, "recipe_id": recipeID, "date": DateTime.now()});
}

Future<List<dynamic>> getEventsForUser() async {
  final data = await supabase
      .from('meal_calendar')
      .select('id, date, recipes(id, title, image)')
      .match({'user_id': userId});
  return data;
}

Future<void> deleteEvent(int eventID, int month, int year, int recipeID) async {
  await supabase.from('meal_calendar').delete().match({"id": eventID});

  //get monthly nutrtion and update it
  final data1 = await supabase
      .from('user_monthly_nutrition')
      .select(
          "carbs, cholesterol, fiber, protein, saturated_fat, sodium, sugar, fat, unsaturated_fat")
      .match({'user_id': userId, 'month': month, 'year': year});

  final nutrition = data1[0];
  final data2 = await supabase
      .from('recipes')
      .select(
          "carbs, cholesterol, fiber, protein, saturated_fat, sodium, sugar, fat, unsaturated_fat")
      .match({"id": recipeID});

  final recipeNutrition = data2[0];

  //subtract recipe nutrition from monthly nutrition
  await supabase.from('user_monthly_nutrition').update({
    "carbs": nutrition['carbs'] - recipeNutrition['carbs'],
    "cholesterol": nutrition['cholesterol'] - recipeNutrition['cholesterol'],
    "fiber": nutrition['fiber'] - recipeNutrition['fiber'],
    "protein": nutrition['protein'] - recipeNutrition['protein'],
    "saturated_fat":
        nutrition['saturated_fat'] - recipeNutrition['saturated_fat'],
    "sodium": nutrition['sodium'] - recipeNutrition['sodium'],
    "sugar": nutrition['sugar'] - recipeNutrition['sugar'],
    "fat": nutrition['fat'] - recipeNutrition['fat'],
    "unsaturated_fat":
        nutrition['unsaturated_fat'] - recipeNutrition['unsaturated_fat']
  }).match({"user_id": userId, "month": month, "year": year});
}

Future<Map<String, dynamic>> getMonthlyNutrition(int month, int year) async {
  final data = await supabase
      .from('user_monthly_nutrition')
      .select(
          "carbs, cholesterol, fiber, protein, saturated_fat, sodium, sugar, fat, unsaturated_fat")
      .match({'user_id': userId, 'month': month, 'year': year});

  if (data.length == 0) {
    return {
      "carbs": 0,
      "cholesterol": 0,
      "fiber": 0,
      "protein": 0,
      "saturated_fat": 0,
      "sodium": 0,
      "sugar": 0,
      "fat": 0,
      "unsaturated_fat": 0
    };
  }
  return data[0];
}

Future<void> addEvent(DateTime date, int recipeID) async {
  var f = NumberFormat("00", "en_US");
  String dateOnly =
      "${date.year}-${f.format(date.month)}-${f.format(date.day)}";

  await supabase
      .from('meal_calendar')
      .insert({"user_id": userId, "recipe_id": recipeID, "date": dateOnly});

  final data2 = await supabase
      .from('recipes')
      .select(
          "carbs, cholesterol, fiber, protein, saturated_fat, sodium, sugar, fat, unsaturated_fat")
      .match({"id": recipeID});

  final recipeNutrition = data2[0];

  //get monthly nutrtion and update it
  final data1 = await supabase
      .from('user_monthly_nutrition')
      .select(
          "carbs, cholesterol, fiber, protein, saturated_fat, sodium, sugar, fat, unsaturated_fat")
      .match({'user_id': userId, 'month': date.month, 'year': date.year});

  if (data1.length == 0) {
    await supabase.from('user_monthly_nutrition').insert({
      "user_id": userId,
      "month": date.month,
      "year": date.year,
      "carbs": recipeNutrition['carbs'],
      "cholesterol": recipeNutrition['cholesterol'],
      "fiber": recipeNutrition['fiber'],
      "protein": recipeNutrition['protein'],
      "saturated_fat": recipeNutrition['saturated_fat'],
      "sodium": recipeNutrition['sodium'],
      "sugar": recipeNutrition['sugar'],
      "fat": recipeNutrition['fat'],
      "unsaturated_fat": recipeNutrition['unsaturated_fat']
    });
    return;
  } else {
    final nutrition = data1[0];

    //subtract recipe nutrition from monthly nutrition
    await supabase.from('user_monthly_nutrition').update({
      "carbs": nutrition['carbs'] + recipeNutrition['carbs'],
      "cholesterol": nutrition['cholesterol'] + recipeNutrition['cholesterol'],
      "fiber": nutrition['fiber'] + recipeNutrition['fiber'],
      "protein": nutrition['protein'] + recipeNutrition['protein'],
      "saturated_fat":
          nutrition['saturated_fat'] + recipeNutrition['saturated_fat'],
      "sodium": nutrition['sodium'] + recipeNutrition['sodium'],
      "sugar": nutrition['sugar'] + recipeNutrition['sugar'],
      "fat": nutrition['fat'] + recipeNutrition['fat'],
      "unsaturated_fat":
          nutrition['unsaturated_fat'] + recipeNutrition['unsaturated_fat']
    }).match({"user_id": userId, "month": date.month, "year": date.year});
  }
}

Future<void> insertCartIntoPantry() async {
  final cart = await supabase
      .from('shopping_cart')
      .select('ingredient_id, amount, unit')
      .match({'user_id': userId});

  for (int i = 0; i < cart.length; i++) {
    try {
      await supabase //insert into pantry
          .from('pantry')
          .insert({
        'user_id': userId,
        'ingredient_id': cart[i]['ingredient_id'],
        'unit': cart[i]['unit'],
        'amount': cart[i]['amount']
      });
    } catch (e) {
      final data = await supabase.from('pantry').select('amount').match(
          {'user_id': userId, 'ingredient_id': cart[i]['ingredient_id']});
      await supabase //update pantry
          .from('pantry')
          .update({'amount': (cart[i]['amount'] + data[0]['amount'])}).match(
              {'user_id': userId, 'ingredient_id': cart[i]['ingredient_id']});
    }
  }

  await supabase.from('shopping_cart').delete().match({'user_id': userId});
}

Future<List<dynamic>> fetchRecipesThatUsePantryIngredients() async {
  final pantry = await supabase
      .from('pantry')
      .select('ingredient_id')
      .match({'user_id': userId});

  List<dynamic> recipes = [];

  for (int i = 0; i < pantry.length; i++) {
    final pantryRecipes = await supabase
        .from('recipe_ingredients')
        .select('recipes(id, title, image))')
        .match({'ingredient_id': pantry[i]['ingredient_id']}).limit(5);

    for (int j = 0; j < pantryRecipes.length; j++) {
      if (recipes
          .where((elem) =>
              (elem['recipes']['id']) == pantryRecipes[j]['recipes']['id'])
          .isEmpty) {
        recipes.add(pantryRecipes[j]);
      }
      if (recipes.length >= 20) {
        break;
      }
    }
    if (recipes.length >= 20) {
      break;
    }
  }

  return recipes;
}
