import 'package:flutter/material.dart';

class MealPlanListModel extends ChangeNotifier {
  final List<dynamic> _mealPlanList = [];
  bool _toggle = false;

  List<dynamic> get mealPlanList => _mealPlanList;

  //_mealPlanList setter
  set mealPlanList(List<dynamic> mealPlanList) {
    _mealPlanList.clear();
    _mealPlanList.addAll(mealPlanList);
    notifyListeners();
  }

  bool get toggle => _toggle;

  void addMealPlan(Map mealPlan) {
    _mealPlanList.add(mealPlan);
    notifyListeners();
  }

  void removeMealPlan(Map mealPlan) {
    _mealPlanList.remove(mealPlan);
    notifyListeners();
  }

  void toggleCheck() {
    _toggle = !_toggle;
    notifyListeners();
  }
}
