import '../utils/constants.dart';

class Pantry {
  String userID;
  int ingrID;
  double amount;
  String unit;
  String label;

  Pantry(this.userID, this.ingrID, this.amount, this.unit, this.label);
}

Future<void> addIngrPantry(
    String amount, String unit, String name, String userID) async {
  int ingrID = 0;
  // Normalize to lowercase
  name.toLowerCase();
  name.trim();
  // Check if name exists in Ingredients Table, grab ID, else insert
  try {
    final ingrResponse =
        await supabase.from(ingredients).select().eq('label', name).single();
    ingrID = ingrResponse['id'];
  } catch (e) {
    final response =
        await supabase.from(ingredients).insert({'label': name}).select();
    ingrID = response[0]['id'];
  }

  // Check if exist in pantry
  try {
    final pantryIngrResponse = await supabase
        .from(pantry)
        .select()
        .eq('user_id', userID)
        .eq('ingredient_id', ingrID)
        .single();

    await supabase
        .from(pantry)
        .update({'amount': double.parse(amount), 'unit': unit})
        .eq('user_id', userID)
        .eq('ingredient_id', ingrID);
    // update by overrite or increment
  } catch (e) {
    final pantryInsResponse = await supabase.from(pantry).insert({
      'user_id': userID,
      'ingredient_id': ingrID,
      'amount': double.parse(amount),
      'unit': unit
    }).select();
  }
}

Future<void> removeAllPantry(String userID) async {
  await supabase.from(pantry).delete().eq('user_id', userID);
}

Future<void> deleteOnePantry(String userID, Pantry p) async {
  await supabase
      .from(pantry)
      .delete()
      .eq('user_id', userID)
      .eq('ingredient_id', p.ingrID)
      .eq('amount', p.amount)
      .eq('unit', p.unit);
}

Future<void> editPantryIngr(String mod, Pantry p, String userID) async {
  switch (mod) {
    case "Add":
      await supabase
          .from(pantry)
          .update({'amount': p.amount + 1.0})
          .eq('user_id', userID)
          .eq('ingredient_id', p.ingrID)
          .eq('amount', p.amount)
          .eq('unit', p.unit);
      break;
    case "Minus":
      await supabase
          .from(pantry)
          .update({'amount': p.amount - 1.0})
          .eq('user_id', userID)
          .eq('ingredient_id', p.ingrID)
          .eq('amount', p.amount)
          .eq('unit', p.unit);
      break;
  }
}
