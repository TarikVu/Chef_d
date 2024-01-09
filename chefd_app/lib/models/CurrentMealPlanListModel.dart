import 'package:flutter/material.dart';

class CurrentMealPlanListModel extends ChangeNotifier {
  String _nutritionalInfo = "Carbs: 0g\n"
      "Cholesterol: 0mg\n"
      "Fiber: 0g\n"
      "Protein: 0g\n"
      "Saturated Fat: 0g\n"
      "Sodium: 0mg\n"
      "Sugar: 0g\n"
      "Fat: 0g\n";

  String get nutritionalInfo => _nutritionalInfo;

  void buildNutritionalInfoString(List<dynamic> data) {
    String nutrition = "Carbs: ${data[0]['carbs']}g\n";
    nutrition += "Cholesterol: ${data[0]['cholesterol']}mg\n";
    nutrition += "Fiber: ${data[0]['fiber']}g\n";
    nutrition += "Protein: ${data[0]['protein']}g\n";
    nutrition += "Saturated Fat: ${data[0]['saturated_fat']}g\n";
    nutrition += "Sodium: ${data[0]['sodium']}mg\n";
    nutrition += "Sugar: ${data[0]['sugar']}g\n";
    nutrition += "Fat: ${data[0]['fat']}g\n";
    _nutritionalInfo = nutrition;
  }
}
