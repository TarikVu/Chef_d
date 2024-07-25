import 'package:chefd_app/models/pantry_model.dart';
import 'package:chefd_app/utils/constants.dart';
import 'package:chefd_app/utils/suggestions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:chefd_app/models/ingredient_model.dart';
import 'theme/colors.dart';

class PantryWidget extends StatefulWidget {
  const PantryWidget({super.key});

  @override
  State<PantryWidget> createState() => _PantryWidgetState();
}

class _PantryWidgetState extends State<PantryWidget> {
  late Size screenSize;
  bool isPhone = false;
  bool hasData = false;
  List<Pantry> userPantry = [];
  List<String> ingrSuggestions = [];
  final amountController = TextEditingController();
  final unitController = TextEditingController();
  final ingrNameController = TextEditingController();
  bool amountEmpty = false;
  bool nameEmpty = false;

  Future<List> _processData() {
    return Future.wait([getPantry()]);
  }

  Future<void> getPantry() async {
    final pantryResponse = await supabase
        .from(pantry)
        .select('ingredient_id, amount, unit, ingredients(label)')
        .eq('user_id', userId)
        .order('ingredients(label)', ascending: true);

    final allIngrsResponse = await supabase.from(ingredients).select('label');

    // Ensure that widget is mounted before setting state.
    if (!mounted) return;

    setState(() {
      userPantry = [];
      for (var i in pantryResponse) {
        int id = i['ingredient_id'];
        double amount = double.parse(i['amount'].toString());
        String unit = i['unit'];
        String label = i['ingredients']['label'];
        userPantry.add(Pantry(userId, id, amount, unit, label));
      }
      // userPantry.sort(((a, b) {
      //   return a.label.toLowerCase().compareTo(b.label.toLowerCase());
      // }));
      ingrSuggestions = getListofIngrs(allIngrsResponse);
      // ingrSuggestions.sort(
      //   (a, b) {
      //     return a.toLowerCase().compareTo(b.toLowerCase());
      //   },
      // );
      hasData = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;
    if (screenSize.width > 500) {
      isPhone = false;
    } else {
      isPhone = true;
    }
    return FutureBuilder(
        future: _processData(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (!hasData) {
            return _loadingScreen();
          } else {
            return _pantryScreen();
          }
        });
  }

  Widget _loadingScreen() {
    return const SafeArea(
      child: Center(
        child: SizedBox(
          width: 400,
          height: 200,
          child: Image(
            fit: BoxFit.fill,
            image: AssetImage('assets/logo.jpg'),
          ),
        ),
      ),
    );
  }

  Widget _pantryScreen() {
    return Scaffold(
        backgroundColor: background, // Main background color for page
        appBar: AppBar(
            title: const Text("My Pantry"),
            centerTitle: true,
            backgroundColor: primaryOrange,
            elevation: 0.0),
        body: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView(
              padding: const EdgeInsets.all(basePadding),
              children: [
                //buildSearchBar(),
                const SizedBox(
                  height: divHeight,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: 4,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          addIngredient();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Ingredient'),
                      ),
                    ),
                    const SizedBox(
                      width: buttonWidthSpacing,
                    ),
                    Flexible(
                      flex: 4,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          removeAllAsk();
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Clear Inventory'),
                      ),
                    ),
                    const SizedBox(
                      width: buttonWidthSpacing,
                    ),
                  ],
                ),
                ingrListView(),
                const SizedBox(
                  height: divHeight,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 10,
                      fit: FlexFit.loose,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.done),
                        label: const Text('Done'),
                      ),
                    ),
                  ],
                )
              ],
            )));
  }

  Widget buildSearchBar() {
    return SearchAnchor(
      builder: ((context, controller) {
        return SearchBar();
      }),
      suggestionsBuilder: (context, controller) {
        List<ListTile> list = [];
        return list;
      },
    );
  }

  Widget ingrListView() {
    return Container(
      height: screenSize.height * 0.65,
      alignment: Alignment.center,
      child: ListView.builder(
          itemCount: userPantry.length,
          itemBuilder: (context, index) {
            return buildIngr(index, userPantry[index]);
          }),
    );
  }

  Widget buildIngr(int i, Pantry ing) {
    return Container(
        decoration: const BoxDecoration(
            color: secondaryOrange,
            borderRadius: BorderRadius.all(Radius.circular(4))),
        margin: const EdgeInsets.all(4.0),
        key: ValueKey(i),
        child: ListTile(
          key: Key('$i'),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          title: ing.amount != 0.0
              ? Text(
                  "${ing.amount} ${ing.unit} ${ing.label}",
                  style: const TextStyle(color: Colors.black),
                )
              : Text(
                  ing.label,
                  style: const TextStyle(color: Colors.black),
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  //add by one
                  editPantryIngr("Add", ing, userId);
                },
              ),
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white),
                onPressed: () {
                  if (ing.amount - 1 <= 0) {
                    removeAsk(ing);
                  } else {
                    //decrement by one
                    editPantryIngr("Minus", ing, userId);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.blueGrey),
                onPressed: () {
                  deleteOnePantry(userId, ing);
                },
              )
            ],
          ),
        ));
  }

  removeAllAsk() {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) => Theme(
              data: Theme.of(context)
                  .copyWith(dialogBackgroundColor: primaryGray),
              child: AlertDialog(
                content: const Text("Are you sure?",
                    style: TextStyle(color: Colors.white)),
                actions: [
                  ElevatedButton(
                      child: const Text("Yes"),
                      onPressed: () {
                        removeAllPantry(userId);
                        Navigator.of(context).pop(); // pops the page
                      }),
                  ElevatedButton(
                      child: const Text("No"),
                      onPressed: () {
                        Navigator.of(context).pop(); // pops the popup
                      }),
                ],
              ),
            ),
          );
        });
  }

  removeAsk(Pantry ing) {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) => Theme(
              data: Theme.of(context)
                  .copyWith(dialogBackgroundColor: primaryGray),
              child: AlertDialog(
                content: const Text("Do you want to remove this ingredient?",
                    style: TextStyle(color: Colors.white)),
                actions: [
                  ElevatedButton(
                      child: const Text("Yes"),
                      onPressed: () {
                        deleteOnePantry(userId, ing);
                        Navigator.of(context).pop(); // pops the page
                      }),
                  ElevatedButton(
                      child: const Text("No"),
                      onPressed: () {
                        Navigator.of(context).pop(); // pops the popup
                      }),
                ],
              ),
            ),
          );
        });
  }

  Future<void> addIngredient() async {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Please fill out all the text boxes."),
              content: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextLabel("Ex: 1.5 tablespoons white sugar", background, 12,
                        false),
                    const SizedBox(
                      height: basePadding,
                    ),
                    Row(
                      children: [
                        TextLabel("Amount:", primaryOrange, 13, true),
                        Flexible(
                          flex: 3,
                          child: TextField(
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true, signed: false),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r"[0-9.]"))
                            ],
                            decoration: InputDecoration(
                              errorText: amountEmpty ? "Can't be empty." : null,
                              border: OutlineInputBorder(),
                            ),
                            controller: amountController,
                          ),
                        ),
                        const SizedBox(
                          width: buttonWidthSpacing,
                        ),
                        TextLabel("Unit:", primaryOrange, 13, true),
                        Flexible(
                          flex: 7,
                          child: TypeAheadField(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: unitController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                            ),
                            suggestionsCallback: (pattern) {
                              return unitOptionsList.where(
                                (suggestion) =>
                                    suggestion.toLowerCase().contains(
                                          pattern.toLowerCase(),
                                        ),
                              );
                            },
                            itemBuilder: (context, suggestion) {
                              return ListTile(
                                title: Text(suggestion),
                              );
                            },
                            onSuggestionSelected: (suggestion) {
                              setState(
                                () {
                                  unitController.text = suggestion;
                                },
                              );
                            },
                          ),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: basePadding,
                    ),
                    TextLabel("Ingredient Name:", primaryOrange, 14, true),
                    const SizedBox(
                      height: basePadding,
                    ),
                    TypeAheadField(
                      textFieldConfiguration: TextFieldConfiguration(
                        controller: ingrNameController,
                        decoration: InputDecoration(
                          errorText: nameEmpty
                              ? "Ingredient name can't be empty."
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      suggestionsCallback: (pattern) {
                        return ingrSuggestions.where(
                          (suggestion) => suggestion.toLowerCase().contains(
                                pattern.toLowerCase(),
                              ),
                        );
                      },
                      itemBuilder: (context, suggestion) {
                        return ListTile(
                          title: Text(suggestion),
                        );
                      },
                      onSuggestionSelected: (suggestion) {
                        setState(
                          () {
                            ingrNameController.text = suggestion;
                          },
                        );
                      },
                    ),
                  ]),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      amountEmpty = amountController.text.isEmpty;
                      nameEmpty = ingrNameController.text.isEmpty;
                      Navigator.pop(context);
                      addIngredient();
                    });

                    if (!amountEmpty && !nameEmpty) {
                      addIngrPantry(amountController.text, unitController.text,
                          ingrNameController.text, userId);
                      resetAddIngredientState();
                      Navigator.pop(context);
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(1),
                    child: Text('Add'),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    resetAddIngredientState();
                    Navigator.pop(context);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(1),
                    child: Text('Cancel'),
                  ),
                ),
              ],
            ));
  }

  // Clear text fields and reset empty boolean checks.
  void resetAddIngredientState() {
    ingrNameController.clear();
    amountController.clear();
    unitController.clear();
    amountEmpty = false;
    nameEmpty = false;
  }
}
