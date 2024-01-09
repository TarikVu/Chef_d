import 'package:flutter/material.dart';

class EditMealPlanListModel extends ChangeNotifier {
  final List<dynamic> _mealPlanList = [];
  bool _toggle = false;

  List<dynamic> get mealPlanList => _mealPlanList;

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

  //add meal plans
  void addMealPlans(List<dynamic> mealPlans) {
    for (int i = 0; i < mealPlans.length; i++) {
      _mealPlanList.add(mealPlans[i]['recipes']);
    }
  }
}
