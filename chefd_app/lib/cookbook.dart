import 'package:chefd_app/home.dart';
import 'package:chefd_app/models/MealPlanListModel.dart';
import 'package:chefd_app/utils/settings.dart';
import 'package:flutter/material.dart';
import 'package:chefd_app/theme/colors.dart';
import 'package:chefd_app/recipe.dart';
import 'package:provider/provider.dart';
import 'package:chefd_app/utils/DBFunctions.dart';
import 'package:chefd_app/utils/constants.dart';

import 'package:chefd_app/models/EditMealPlanListModel.dart';
import 'package:chefd_app/models/CurrentMealPlanListModel.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart';

/// A widget that represents a cookbook.
///
/// This widget displays a cookbook with options to navigate to the meal plan and meal calendar pages.
class CookbookWidget extends StatelessWidget {
  const CookbookWidget({super.key});

  refresh() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Recipe Book'),
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SettingsWidget(),
                    settings: RouteSettings(
                        arguments: supabase.auth.currentUser!.id)));
          },
        ),
        centerTitle: true,
        backgroundColor: primaryOrange,
        elevation: 0.0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MultiProvider(
                            providers: [
                              ChangeNotifierProvider<CurrentMealPlanListModel>(
                                  create: (context) =>
                                      CurrentMealPlanListModel()),
                            ],
                            child: const CurrentMealPlanPage(),
                          )),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange, // Background color
              ),
              child: const Text('Meal Plan'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MealCalendarPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange, // Background color
              ),
              child: const Text('Meal Calendar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Builds a pie chart based on the provided nutrition data.
///
/// The [nutrition] parameter is a map that contains the nutritional values
/// for various categories such as carbs, cholesterol, fiber, protein, etc.
/// The values in the map should be of type [double].
///
/// Returns a [PieChart] widget that visualizes the nutrition data in a pie chart.
PieChart buildPie(Map<String, dynamic> nutrition) {
  return PieChart(
    chartType: ChartType.disc,
    dataMap: {
      "Carbs (g)": nutrition['carbs']!.toDouble(),
      "Cholesterol (g)": nutrition['cholesterol']!.toDouble() / 1000,
      "Fiber (g)": nutrition['fiber']!.toDouble(),
      "Protein (g)": nutrition['protein']!.toDouble(),
      "Saturated Fat (g)": nutrition['saturated_fat']!.toDouble(),
      "Sodium (g)": nutrition['sodium']!.toDouble() / 1000,
      "Sugar (g)": nutrition['sugar']!.toDouble(),
      "Fat (g)": nutrition['fat']!.toDouble(),
      "Unsaturated Fat (g)": nutrition['unsaturated_fat']!.toDouble(),
    },
    colorList: const [
      grey,
      primaryOrange,
      red,
      yellow,
      secondaryOrange,
      Colors.blue,
      Colors.brown,
      Colors.black,
      Colors.white,
    ],
    chartValuesOptions: const ChartValuesOptions(
      showChartValueBackground: true,
      showChartValues: true,
      showChartValuesInPercentage: false,
      showChartValuesOutside: false,
      decimalPlaces: 1,
    ),
    legendOptions: const LegendOptions(
      showLegendsInRow: false,
      legendPosition: LegendPosition.right,
      showLegends: true,
      legendTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: white,
      ),
    ),
  );
}

/// A page that displays the meal calendar and nutritional information for a specific date.
///
/// This page is used to display the nutritional information for a specific date in the meal calendar.
/// It retrieves the monthly nutrition data using the [getMonthlyNutrition] function and displays it using a pie chart.
class MealCalendarNutritionPage extends StatefulWidget {
  final DateTime date;

  /// Constructs a [MealCalendarNutritionPage] with the given [date].
  // ignore: use_key_in_widget_constructors
  const MealCalendarNutritionPage({Key? key, required this.date});

  @override
  State<MealCalendarNutritionPage> createState() =>
      _MealCalendarNutritionPage();
}

/// The state for the [MealCalendarNutritionPage] widget.
///
/// This state is responsible for initializing the page and building the UI.
class _MealCalendarNutritionPage extends State<MealCalendarNutritionPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title:
              Text('${widget.date.month}/${widget.date.year} Nutritional Info'),
          backgroundColor: primaryOrange,
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: getMonthlyNutrition(widget.date.month, widget.date.year),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final nutritionalInfo = snapshot.data!;
              return buildPie(nutritionalInfo);
            }
          },
        ));
  }
}

/// This class represents the page that displays the current meal plan's nutrition information.
/// It is a stateful widget that can be updated.
class CurrentMealPlanNutritionPage extends StatefulWidget {
  const CurrentMealPlanNutritionPage({super.key});

  @override
  State<CurrentMealPlanNutritionPage> createState() =>
      _CurrentMealPlanNutritionPage();
}

/// This class represents the state of the [CurrentMealPlanNutritionPage].
/// It handles the initialization and building of the page.
class _CurrentMealPlanNutritionPage
    extends State<CurrentMealPlanNutritionPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: const Text('Nutritional Info'),
          backgroundColor: primaryOrange,
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: getCurrentMealPlanNutrition(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final nutritionalInfo = snapshot.data!;
              return buildPie(nutritionalInfo);
            }
          },
        ));
  }
}

/// Calendar page for meals. Can add meals to the calendar from favorites.
/// Uses `retrieveMealCalendar()` to retrieve meals for the calendar.
class MealCalendarPage extends StatefulWidget {
  const MealCalendarPage({super.key});

  @override
  State<MealCalendarPage> createState() => _MealCalendarPage();
}

/// Calendar page for meals. Can add meals to the calendar from favorites.
/// Uses `retrieveMealCalendar()` to retrieve meals for the calendar.
class _MealCalendarPage extends State<MealCalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<dynamic> events = [];
  late final ValueNotifier<List<dynamic>> _selectedEvents;

  List<dynamic> _getEventsForDay(DateTime date) {
    var f = NumberFormat("00", "en_US");
    String dateOnly =
        "${date.year}-${f.format(date.month)}-${f.format(date.day)}";
    List<dynamic> eventsForDay =
        events.where((event) => event['date'] == dateOnly).toList();
    return eventsForDay;
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: const Text('Meal Calendar'),
          backgroundColor: primaryOrange,
          actions: [
            IconButton(
              icon: const Icon(Icons.food_bank_outlined),
              iconSize: 50.0,
              // On pressed, show nutritional info keeping in mind the provider.
              onPressed: () {
                // Navigate to MealCalendarNutritionalPage.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          MealCalendarNutritionPage(date: _focusedDay)),
                );
              },
            ),
          ],
        ),
        body: FutureBuilder<List<dynamic>>(
          future: getEventsForUser(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              events = snapshot.data!;
              _selectedEvents.value = _getEventsForDay(_selectedDay!);

              return Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime.utc(2023, 1, 1),
                    lastDay: DateTime.utc(2024, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    eventLoader: _getEventsForDay,
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(color: Colors.white),
                      weekendStyle: TextStyle(color: Colors.white),
                    ),
                    headerStyle: const HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      titleTextStyle: TextStyle(color: Colors.white),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                      ),
                    ),
                    calendarStyle: const CalendarStyle(
                        defaultTextStyle: TextStyle(color: Colors.white),
                        weekNumberTextStyle: TextStyle(color: Colors.white),
                        weekendTextStyle: TextStyle(color: Colors.white),
                        outsideTextStyle: TextStyle(color: Colors.white),
                        markerDecoration: BoxDecoration(
                          color: primaryOrange,
                          shape: BoxShape.circle,
                        )),
                    selectedDayPredicate: (day) {
                      // Use `selectedDayPredicate` to determine which day is currently selected.
                      // If this returns true, then `day` will be marked as selected.

                      // Using `isSameDay` is recommended to disregard
                      // the time-part of compared DateTime objects.
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!isSameDay(_selectedDay, selectedDay)) {
                        // Call `setState()` when updating the selected day.
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                          _selectedEvents.value = _getEventsForDay(selectedDay);
                        });
                      }
                    },
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        // Call `setState()` when updating calendar format.
                        setState(() {
                          _calendarFormat = format;
                        });
                      }
                    },
                    onPageChanged: (focusedDay) {
                      // No need to call `setState()` here.
                      _focusedDay = focusedDay;
                    },
                  ),
                  Expanded(
                    child: ValueListenableBuilder<List<dynamic>>(
                      valueListenable: _selectedEvents,
                      builder: (context, value, _) {
                        return ListView.builder(
                          itemCount: value.length,
                          itemBuilder: (context, index) {
                            final buttonData = value[index];
                            return ListTile(
                              leading: Image.network(
                                buttonData['recipes']['image'],
                                height: 44,
                                width: 44,
                              ),
                              title: Text(buttonData['recipes']['title'],
                                  style: const TextStyle(color: Colors.white)),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await deleteEvent(
                                      buttonData['id'],
                                      _selectedDay!.month,
                                      _selectedDay!.year,
                                      buttonData['recipes']['id']);

                                  setState(() {
                                    events.removeWhere((element) =>
                                        element['id'] == buttonData['id']);
                                    _selectedEvents.value =
                                        _getEventsForDay(_selectedDay!);
                                  });
                                },
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const RecipeWidget(),
                                      //settings: RouteSettings(arguments: index)),
                                      settings: RouteSettings(
                                          arguments: buttonData['recipes']
                                              ['id'])),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            }
          },
        ));
  }
}

//not in use anymore
// class LikedListPage extends StatelessWidget {
//   const LikedListPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: background,
//       appBar: AppBar(
//         title: const Text('Liked Recipes'),
//         backgroundColor: primaryOrange,
//       ),
//       body: FutureBuilder<List<dynamic>>(
//         future: fetchLiked(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           } else {
//             final buttonDataList = snapshot.data;

//             return ListView.builder(
//               itemCount: buttonDataList!.length,
//               itemBuilder: (context, index) {
//                 final buttonData = buttonDataList[index]['recipes'];
//                 int ind = buttonData['id'];
//                 return SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => const RecipeWidget(),
//                             //settings: RouteSettings(arguments: index)),
//                             settings: RouteSettings(arguments: ind)),
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: secondaryOrange,
//                       foregroundColor: white,
//                       textStyle: const TextStyle(fontSize: 15),
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       children: [
//                         Padding(
//                           padding:
//                               const EdgeInsets.only(right: 16.0, left: 16.0),
//                           child: Image.network(
//                             buttonData['image'],
//                             height: 44,
//                             width: 44,
//                           ),
//                         ),
//                         Text(buttonData['title']),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             );
//           }
//         },
//       ),
//     );
//   }
// }

/// Represents a page for displaying a meal plan.
///
/// This page displays options for creating a new meal plan or accessing an existing one.
/// It includes buttons for navigating to the respective pages.
class MealPlanPage extends StatelessWidget {
  const MealPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Meal Plan'),
        centerTitle: true,
        backgroundColor: primaryOrange,
        elevation: 0.0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MultiProvider(
                            providers: [
                              ChangeNotifierProvider<MealPlanListModel>(
                                  create: (context) => MealPlanListModel()),
                            ],
                            child: const NewMealPlanPage(),
                          )),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange, // Background color
              ),
              child: const Text('New Meal Plan'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ExistingMealPlanPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange, // Background color
              ),
              child: const Text('Existing Meal Plan'),
            ),
          ],
        ),
      ),
    );
  }
}

/// This class represents the page for creating a new meal plan.
class NewMealPlanPage extends StatefulWidget {
  const NewMealPlanPage({super.key});

  @override
  State<NewMealPlanPage> createState() => _NewMealPlanPage();
}

/// This class represents the state of the NewMealPlanPage widget.
class _NewMealPlanPage extends State<NewMealPlanPage> {
  Size screenSize = const Size(0, 0);

  /// Fetches the list of meal plans.
  Future<List<dynamic>> fetchMealPlanList(value) async {
    return value.mealPlanList;
  }

  /// Builds the horizontal list for adding recipes based on the function type.
  Widget _buildAddHorizontalList(int funcType) {
    return SizedBox(
        height: screenSize.height * 0.3,
        child: FutureBuilder<List<dynamic>>(
          future: funcType == 0
              ? fetchRecipesThatUsePantryIngredients()
              : funcType == 1
                  ? fetchLiked()
                  : fetchRandomRecipes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final buttonDataList = snapshot.data;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: buttonDataList!.length,
                itemBuilder: (context, index) {
                  // ignore: prefer_typing_uninitialized_variables
                  final buttonData;
                  funcType == 2
                      ? buttonData = buttonDataList[index]
                      : buttonData = buttonDataList[index]['recipes'];

                  int ind = buttonData['id'];
                  return Padding(
                      padding: const EdgeInsets.only(
                          left: basePadding, right: basePadding),
                      child: SizedBox(
                          width: screenSize.width * 0.30,
                          height: screenSize.height * 0.30,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const RecipeWidget(),
                                    settings: RouteSettings(arguments: ind)),
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.network(
                                          buttonData['image'],
                                          height: screenSize.height * 0.20,
                                          width: screenSize.width * 0.30,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      IconButton(
                                          onPressed: () {
                                            context
                                                .read<MealPlanListModel>()
                                                .addMealPlan(buttonData);
                                          },
                                          splashColor: primaryOrange,
                                          color: Colors.white,
                                          icon: const Icon(Icons.add)),
                                    ]),
                                Flexible(
                                    child: TextLabel(
                                        buttonData['title'], white, 12, false)),
                              ],
                            ),
                          )));
                },
              );
            }
          },
        ));
  }

  /// Builds the horizontal list for removing recipes from the meal plan.
  Widget _buildSubHorizontalList() {
    return Consumer<MealPlanListModel>(
        builder: (context, value, child) => SizedBox(
            height: screenSize.height * 0.3,
            child: FutureBuilder<List<dynamic>>(
              future: fetchMealPlanList(value),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  final buttonDataList = snapshot.data;

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: buttonDataList!.length,
                    itemBuilder: (context, index) {
                      final buttonData = buttonDataList[index];

                      int ind = buttonData['id'];
                      return Padding(
                          padding: const EdgeInsets.only(
                              left: basePadding, right: basePadding),
                          child: SizedBox(
                              width: screenSize.width * 0.30,
                              height: screenSize.height * 0.30,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const RecipeWidget(),
                                        settings:
                                            RouteSettings(arguments: ind)),
                                  );
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Stack(
                                        alignment: Alignment.bottomRight,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: Image.network(
                                              buttonData['image'],
                                              height: screenSize.height * 0.20,
                                              width: screenSize.width * 0.30,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          IconButton(
                                              onPressed: () {
                                                context
                                                    .read<MealPlanListModel>()
                                                    .removeMealPlan(buttonData);
                                              },
                                              splashColor: primaryOrange,
                                              color: white,
                                              icon: const Icon(Icons.remove)),
                                        ]),
                                    Flexible(
                                        child: TextLabel(buttonData['title'],
                                            white, 12, false)),
                                  ],
                                ),
                              )));
                    },
                  );
                }
              },
            )));
  }

  /// Creates a new meal plan and navigates to the current meal plan page.
  void createMealPlan(BuildContext context) async {
    List<dynamic> recs = context.read<MealPlanListModel>().mealPlanList;
    await makeMealPlanFromNew(recs);
    await insertIngrsToShoppingCartFromRecipes(recs);
    // ignore: use_build_context_synchronously
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => MultiProvider(
                providers: [
                  ChangeNotifierProvider<CurrentMealPlanListModel>(
                      create: (context) => CurrentMealPlanListModel()),
                ],
                child: const CurrentMealPlanPage(),
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    var pressed = false;
    screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Create Meal Plan'),
        backgroundColor: primaryOrange,
      ),
      body: ListView(
        children: [
          const Padding(
              padding: EdgeInsets.only(top: basePadding, bottom: basePadding),
              child: Text("Use what's in your pantry",
                  style: TextStyle(
                      color: Colors.white, fontSize: 15, letterSpacing: 2))),
          _buildAddHorizontalList(0),
          const Padding(
              padding: EdgeInsets.only(top: basePadding, bottom: basePadding),
              child: Text("Discover new recipes",
                  style: TextStyle(
                      color: Colors.white, fontSize: 15, letterSpacing: 2))),
          _buildAddHorizontalList(2),
          const Padding(
              padding: EdgeInsets.only(top: basePadding, bottom: basePadding),
              child: Text("Favorites",
                  style: TextStyle(
                      color: Colors.white, fontSize: 15, letterSpacing: 2))),
          _buildAddHorizontalList(1),
          const Padding(
              padding: EdgeInsets.only(top: basePadding, bottom: basePadding),
              child: Text("Selected",
                  style: TextStyle(
                      color: Colors.white, fontSize: 15, letterSpacing: 2))),
          _buildSubHorizontalList(),
          ElevatedButton(
            onPressed: () {
              pressed ? null : createMealPlan(context);
              pressed = true;
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange, // Background color
            ),
            child: const Text('Create'),
          )
        ],
      ),
    );
  }
}

/// This class represents the page for existing meal plans.
/// It is a stateful widget that displays a list of meal plans.
class ExistingMealPlanPage extends StatefulWidget {
  const ExistingMealPlanPage({super.key});

  @override
  State<ExistingMealPlanPage> createState() => _ExistingMealPlanPage();
}

/// Inserts a meal plan into the shopping cart and navigates to the current meal plan page.
///
/// This function takes the [BuildContext] and the index of the meal plan as parameters.
/// It updates the current meal plan from the existing meal plan at the given index,
/// inserts the ingredients of the meal plan into the shopping cart,
/// and navigates to the current meal plan page.
void insertMealPlan(BuildContext context, int ind) async {
  await updateCurrentMealPlanFromExistingMealPlan(ind);
  await insertIngrsToShoppingCartFromMealPlan(ind);
  // ignore: use_build_context_synchronously
  Navigator.push(
    context,
    MaterialPageRoute(
        builder: (context) => MultiProvider(
              providers: [
                ChangeNotifierProvider<CurrentMealPlanListModel>(
                    create: (context) => CurrentMealPlanListModel()),
              ],
              child: const CurrentMealPlanPage(),
            )),
  );
}

/// This class represents the state of the existing meal plan page.
/// It is a private class that is only used within the [ExistingMealPlanPage] class.
class _ExistingMealPlanPage extends State<ExistingMealPlanPage> {
  @override
  Widget build(BuildContext context) {
    var pressed = false;
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Exsting Meal Plans'),
        backgroundColor: primaryOrange,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchMealplans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final buttonDataList = snapshot.data;

            return ListView.builder(
              itemCount: buttonDataList!.length,
              itemBuilder: (context, index) {
                final buttonData = buttonDataList[index];
                final int ind = buttonData['id'];
                return SizedBox(
                  width: double.infinity,
                  child: ListTile(
                    onTap: () async {
                      pressed ? null : insertMealPlan(context, ind);
                      pressed = true;
                    },
                    tileColor: secondaryOrange,
                    title: Text(buttonData['label'],
                        style: const TextStyle(color: Colors.white)),
                    trailing: PopupMenuButton<int>(
                      onSelected: (int? value) async {
                        if (value == 1) {
                          await deleteMealPlan(ind);
                          setState(() {});
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MultiProvider(
                                providers: [
                                  ChangeNotifierProvider<EditMealPlanListModel>(
                                      create: (context) =>
                                          EditMealPlanListModel()),
                                ],
                                child: EditMealPlanPage(mealPlanID: ind),
                              ),
                              //settings: RouteSettings(arguments: index)),
                            ),
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<int>>[
                        const PopupMenuItem<int>(
                          value: 0,
                          child: Text('edit'),
                        ),
                        const PopupMenuItem<int>(
                          value: 1,
                          child: Text('delete'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
// Widget checkmark(Map buttonData) {
//   return StatefulBuilder(
//       builder: (BuildContext context, StateSetter setState) {
//     return FutureBuilder<List<dynamic>>(
//       future: checkMade(buttonData['id']),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         } else {
//           final buttonDataList = snapshot.data;
//           bool toggle = buttonDataList![0]['made'];

//           return IconButton(
//               onPressed: () async {
//                 setState(() {
//                   updateMade(buttonData['id'], !toggle);
//                 });
//               },
//               splashColor: Colors.black,
//               icon: Icon(
//                   toggle ? Icons.check_box : Icons.check_box_outline_blank));
//         }
//       },
//     );
//   });
// }
/// This class represents the page that displays the current meal plan.
/// It is a stateful widget that manages the state of the page.
class CurrentMealPlanPage extends StatefulWidget {
  const CurrentMealPlanPage({super.key});

  @override
  State<CurrentMealPlanPage> createState() => _CurrentMealPlanPage();
}

/// This class represents the state of the [CurrentMealPlanPage].
/// It contains the logic and UI for displaying the current meal plan.
class _CurrentMealPlanPage extends State<CurrentMealPlanPage> {
  Size screenSize = const Size(0, 0);

  /// Builds the list of meals for the current meal plan.
  /// It uses a [FutureBuilder] to fetch the current meal plan data asynchronously.
  /// Displays a loading indicator while waiting for the data.
  /// If there is an error, displays an error message.
  /// Once the data is available, it builds a [ListView] to display the meals.
  Widget mealList(context) {
    return FutureBuilder<List<dynamic>>(
      future: fetchCurrentMealPlan(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final buttonDataList = snapshot.data;

          return ListView.builder(
              itemCount: buttonDataList!.isNotEmpty
                  ? buttonDataList[0]['meal_plans_recipes'].length
                  : 0,
              itemBuilder: (context, index) {
                final buttonData =
                    buttonDataList[0]['meal_plans_recipes'][index];
                context
                    .read<CurrentMealPlanListModel>()
                    .buildNutritionalInfoString(buttonDataList);
                int ind = buttonData['recipes']['id'];
                return Padding(
                    padding: const EdgeInsets.only(top: 1, bottom: 1),
                    child: Card(
                        color: secondaryOrange,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const RecipeWidget(),
                                  //settings: RouteSettings(arguments: index)),
                                  settings: RouteSettings(arguments: ind)),
                            );
                          },
                          child: Row(
                            children: [
                              ClipRect(
                                  child: Image.network(
                                      buttonData['recipes']['image'],
                                      height: screenSize.height * 0.15,
                                      width: screenSize.width * 0.25,
                                      fit: BoxFit.cover)),
                              Padding(
                                  padding: EdgeInsets.only(
                                      left: screenSize.width * 0.05),
                                  child: Text(
                                    buttonData['recipes']['title'],
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 15),
                                  ))
                            ],
                          ),
                        )));
              });
        }
      },
    );
  }

  final nameController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;
    return WillPopScope(
        onWillPop: () async {
          // Intercept the back button press and navigate to DifferentPage.
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const BotNavBar()),
            (Route<dynamic> route) => false,
          );
          return false; // Prevent default back button behavior
        },
        child: Scaffold(
            backgroundColor: Colors.grey[900],
            appBar: AppBar(
                title: const Text('Current Meal Plan'),
                centerTitle: true,
                backgroundColor: primaryOrange,
                elevation: 0.0,
                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.save),
                    iconSize: 50.0,
                    onPressed: () => showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text('Save Meal Plan'),
                        //textbox to enter meal plan name
                        content: TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Meal Plan Name',
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              updateMealPlanNameAndTemporary(
                                  nameController.text);
                              Navigator.of(context).pop();
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.food_bank_outlined),
                    iconSize: 50.0,
                    //onpressed show nutritional info keeping in mind the provider
                    onPressed: () {
                      //navigate to CurrentMealPLanNutritionalPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const CurrentMealPlanNutritionPage()),
                      );
                    },
                  ),
                ]),
            body: mealList(context),
            bottomNavigationBar: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MealPlanPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange, // Background color
              ),
              child: const Text('New Meal Plan'),
            )));
  }
}

/// This class represents the page for editing a meal plan.
/// It is a stateful widget that takes a [mealPlanID] as a required parameter.
class EditMealPlanPage extends StatefulWidget {
  final int mealPlanID;

  const EditMealPlanPage({super.key, required this.mealPlanID});

  @override
  State<EditMealPlanPage> createState() => _EditMealPlanPage();
}

/// The state class for [EditMealPlanPage].
class _EditMealPlanPage extends State<EditMealPlanPage> {
  Size screenSize = const Size(0, 0);

  /// Fetches the meal plan list based on the [value] and [first] parameters.
  /// If [first] is true, it fetches the meal plan recipes using [fetchMealPlanRecipes]
  /// and adds them to the [EditMealPlanListModel] using [addMealPlans].
  /// Returns the meal plan list.
  Future<List<dynamic>> fetchMealPlanList(context, value, bool first) async {
    if (first) {
      await fetchMealPlanRecipes(widget.mealPlanID).then((recipes) =>
          Provider.of<EditMealPlanListModel>(context, listen: false)
              .addMealPlans(recipes));
    }
    return value.mealPlanList;
  }

  /// Builds a horizontal list of buttons based on the [funcType] parameter.
  /// The buttons are fetched using different functions based on the [funcType].
  /// Returns the built widget.
  Widget _buildAddHorizontalList(int funcType) {
    return SizedBox(
        height: screenSize.height * 0.3,
        child: FutureBuilder<List<dynamic>>(
          future: funcType == 0
              ? fetchRecipesThatUsePantryIngredients()
              : funcType == 1
                  ? fetchLiked()
                  : fetchRandomRecipes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final buttonDataList = snapshot.data;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: buttonDataList!.length,
                itemBuilder: (context, index) {
                  // ignore: prefer_typing_uninitialized_variables
                  final buttonData;
                  funcType == 2
                      ? buttonData = buttonDataList[index]
                      : buttonData = buttonDataList[index]['recipes'];

                  int ind = buttonData['id'];
                  return Padding(
                      padding: const EdgeInsets.only(
                          left: basePadding, right: basePadding),
                      child: SizedBox(
                          width: screenSize.width * 0.30,
                          height: screenSize.height * 0.30,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const RecipeWidget(),
                                    //settings: RouteSettings(arguments: index)),
                                    settings: RouteSettings(arguments: ind)),
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.network(
                                          buttonData['image'],
                                          height: screenSize.height * 0.20,
                                          width: screenSize.width * 0.30,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      IconButton(
                                          onPressed: () {
                                            context
                                                .read<EditMealPlanListModel>()
                                                .addMealPlan(buttonData);
                                          },
                                          splashColor: primaryOrange,
                                          color: Colors.white,
                                          icon: const Icon(Icons.add)),
                                    ]),
                                Flexible(
                                    child: TextLabel(
                                        buttonData['title'], white, 12, false)),
                              ],
                            ),
                          )));
                },
              );
            }
          },
        ));
  }

  /// Builds a horizontal list of buttons for the selected meal plan.
  /// The meal plan list is fetched using [fetchMealPlanList].
  /// Returns the built widget.
  Widget _buildSubHorizontalList() {
    bool first = true;
    return Consumer<EditMealPlanListModel>(
        builder: (context, value, child) => SizedBox(
            height: screenSize.height * 0.3,
            child: FutureBuilder<List<dynamic>>(
              future: fetchMealPlanList(context, value, first),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  final buttonDataList = snapshot.data;
                  first = false;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: buttonDataList!.length,
                    itemBuilder: (context, index) {
                      final buttonData = buttonDataList[index];

                      int ind = buttonData['id'];
                      return Padding(
                          padding: const EdgeInsets.only(
                              left: basePadding, right: basePadding),
                          child: SizedBox(
                              width: screenSize.width * 0.30,
                              height: screenSize.height * 0.30,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const RecipeWidget(),
                                        //settings: RouteSettings(arguments: index)),
                                        settings:
                                            RouteSettings(arguments: ind)),
                                  );
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Stack(
                                        alignment: Alignment.bottomRight,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: Image.network(
                                              buttonData['image'],
                                              height: screenSize.height * 0.20,
                                              width: screenSize.width * 0.30,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          IconButton(
                                              onPressed: () {
                                                context
                                                    .read<
                                                        EditMealPlanListModel>()
                                                    .removeMealPlan(buttonData);
                                              },
                                              splashColor: primaryOrange,
                                              color: white,
                                              icon: const Icon(Icons.remove)),
                                        ]),
                                    Flexible(
                                        child: TextLabel(buttonData['title'],
                                            white, 12, false)),
                                  ],
                                ),
                              )));
                    },
                  );
                }
              },
            )));
  }

  /// Updates the meal plan using [updateMealPlan] and the meal plan list from [EditMealPlanListModel].
  void editMealPlan(BuildContext context) async {
    await updateMealPlan(
        context.read<EditMealPlanListModel>().mealPlanList, widget.mealPlanID);
    // ignore: use_build_context_synchronously
  }

  @override
  Widget build(BuildContext context) {
    var pressed = false;
    screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Edit Meal Plan'),
        backgroundColor: primaryOrange,
      ),
      body: ListView(
        children: [
          const Padding(
              padding: EdgeInsets.only(top: basePadding, bottom: basePadding),
              child: Text("Use what's in your pantry",
                  style: TextStyle(
                      color: Colors.white, fontSize: 15, letterSpacing: 2))),
          _buildAddHorizontalList(0),
          const Padding(
              padding: EdgeInsets.only(top: basePadding, bottom: basePadding),
              child: Text("Discover new recipes",
                  style: TextStyle(
                      color: Colors.white, fontSize: 15, letterSpacing: 2))),
          _buildAddHorizontalList(2),
          const Padding(
              padding: EdgeInsets.only(top: basePadding, bottom: basePadding),
              child: Text("Favorites",
                  style: TextStyle(
                      color: Colors.white, fontSize: 15, letterSpacing: 2))),
          _buildAddHorizontalList(1),
          const Padding(
              padding: EdgeInsets.only(top: basePadding, bottom: basePadding),
              child: Text("Selected",
                  style: TextStyle(
                      color: Colors.white, fontSize: 15, letterSpacing: 2))),
          _buildSubHorizontalList(),
          ElevatedButton(
            onPressed: () {
              pressed ? null : editMealPlan(context);
              pressed = true;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange, // Background color
            ),
            child: const Text('Update'),
          )
        ],
      ),
    );
  }
}
