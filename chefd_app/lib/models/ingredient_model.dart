class Ingredient {
  /// The name of the ingredient.
  String name;

  Ingredient(this.name);
}

List<String> getListofIngrs(List<dynamic> ingrs) {
  List<String> l = [];
  for (int i = 0; i < ingrs.length; i++) {
    dynamic curIngr = ingrs[i];
    l.add(curIngr['label']);
  }
  return l;
}
