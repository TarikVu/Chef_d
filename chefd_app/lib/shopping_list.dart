import 'package:chefd_app/home_layout.dart';
import 'package:chefd_app/shopping_list/instore.dart';
import 'package:chefd_app/client_settings.dart';
import 'package:flutter/material.dart';
import 'package:chefd_app/theme/colors.dart';
import 'package:chefd_app/utils/constants.dart';
import 'package:flutter/services.dart';
import 'models/shopping_list_model.dart';
import 'package:chefd_app/shopping_list/checkout.dart';
import "package:collection/collection.dart";

class ShoppingList extends StatefulWidget {
  const ShoppingList({super.key});

  @override
  State<ShoppingList> createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList> {
  List<dynamic> ingrs = [];
  List<dynamic> locations = [];
  final locationInputController = TextEditingController();
  Map location = {};
  Map groupByRecipeId = {};
  late dynamic token;
  late Size screenSize;
  bool isPhone = false;
  bool isCostLoading = false;
  double totalCost = 0.0;
  String currentLocation = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;
    if (screenSize.width > 500) {
      isPhone = false;
    } else {
      isPhone = true;
    }
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('My Shopping List'),
        // leading: IconButton(
        //   icon: const Icon(Icons.settings),
        //   onPressed: () {
        //     Navigator.push(
        //         context,
        //         MaterialPageRoute(
        //             builder: (context) => const SettingsWidget(),
        //             settings: RouteSettings(
        //                 arguments: supabase.auth.currentUser!.id)));
        //   },
        // ),
        centerTitle: true,
        backgroundColor: primaryOrange,
        elevation: 0.0,
      ),
      body: FutureBuilder(
        future: getShoppingList(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else {
            if (ingrs.isEmpty) {
              ingrs = snapshot.data!;
              // ingrs.sort(((a, b) {
              //   return a.ingr.name
              //       .toLowerCase()
              //       .compareTo(b.ingr.name.toLowerCase());
              // }));
            }
            groupByRecipeId = groupBy(ingrs, (p0) => p0.recipeTitle);
          }
          return _shoppingListScreen(context);
        },
      ),
    );
  }

  Widget _shoppingListScreen(BuildContext context) {
    if (ingrs.isEmpty) {
      return emptyList(context);
    } else {
      return buildList(context);
    }
  }

  Widget buildList(BuildContext context) {
    //locationInputController.text = "84120";
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(basePadding),
        children: listComponents(context),
      ),
    );
  }

  List<Widget> listComponents(BuildContext context) {
    List<Widget> l = [];
    l.add(const SizedBox(
      height: divHeight,
    ));
    l.add(const Text(
      "Zip Code:",
      style: TextStyle(color: white),
    ));
    l.add(Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: TextField(
            style: const TextStyle(color: white),
            keyboardType: const TextInputType.numberWithOptions(
                decimal: false, signed: false),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[0-9]"))
            ],
            controller: locationInputController,
          ),
        ),
        Expanded(
            flex: 4,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (locationInputController.text.isEmpty) {
                  showAlertDialog(context,
                      "Location can't be empty. Please enter a 5 digit ZIP code.");
                } else if (locationInputController.text.length != 5) {
                  showAlertDialog(context, "Please enter a 5 digit ZIP code.");
                } else {
                  setState(() {
                    isCostLoading = true;
                  });
                  String token = await getKrogerToken();
                  List<dynamic> locations =
                      await getLocation(locationInputController.text, token);
                  selectStoreLocation(locations);
                }
              },
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(basePadding),
                  elevation: 10.0,
                  textStyle: const TextStyle(color: Colors.white)),
              icon: isCostLoading
                  ? Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(2.0),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(Icons.location_city),
              label: const Text('Set Location'),
            ))
      ],
    ));
    if (location.isNotEmpty) {
      l.add(Text(
        "${location['name']}",
        style: const TextStyle(
            color: white, fontSize: 18, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ));
      l.add(Text(
        "${location['address']['addressLine1']}",
        style: const TextStyle(
            color: white, fontSize: 18, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ));
      l.add(ElevatedButton.icon(
        onPressed: () async {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const InStore(),
                  settings: RouteSettings(
                      arguments: {'ingrs': ingrs, 'location': location})));
        },
        style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(basePadding),
            elevation: 10.0,
            textStyle: const TextStyle(color: Colors.white)),
        icon: isCostLoading
            ? Container(
                width: 24,
                height: 24,
                padding: const EdgeInsets.all(2.0),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Icon(Icons.local_convenience_store_rounded),
        label: const Text('I\'m here at the store'),
      ));
    } else {
      l.add(const SizedBox(
        height: divHeight,
      ));
      l.add(const Text(
        "Set a 5 digit ZIP code to get estimated prices, nearest store, and aisle information.",
        style:
            TextStyle(color: white, fontSize: 18, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ));
    }
    l.addAll(ingrListView());
    l.add(Center(
        child: Text(
      "Estimated Total Cost: \$${getTotalCost(ingrs).toStringAsFixed(2)}",
      style: const TextStyle(
          color: white, fontSize: 20, fontWeight: FontWeight.bold),
    )));
    l.add(Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              deleteAllShoppingList(ingrs.first);
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HomeWidget()));
              }
            },
            icon: const Icon(Icons.delete),
            label: const Text('Remove All'),
          ),
        ),
        const SizedBox(
          width: buttonWidthSpacing,
        ),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CheckoutPage(
                          shoppingList: ingrs,
                        )),
              );
            },
            icon: const Icon(Icons.shopping_cart_checkout_rounded),
            label: const Text('Checkout'),
          ),
        ),
      ],
    ));
    if (Navigator.canPop(context)) {
      l.add(doneButton(context));
    }
    return l;
  }

  Widget buildLocationButton(Map<dynamic, dynamic> s) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          onTap: () async {
            Navigator.of(context, rootNavigator: true).pop();
            List<dynamic> list = await getIngrCosts(ingrs, s['locationId']);
            setState(() {
              ingrs = list;
              location = s;
              isCostLoading = false;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(),
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: ListTile(
              title: Text("Name: ${s['name']}"),
              subtitle: Text("Address: ${s['address']['addressLine1']}"),
            ),
          ),
        ));
  }

  void selectStoreLocation(List<dynamic> stores) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Please select your store."),
              content: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [for (var s in stores) buildLocationButton(s)],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                    setState(() {
                      isCostLoading = false;
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(1),
                    child: Text('Cancel'),
                  ),
                ),
              ],
            ));
  }

  List<Widget> ingrListView() {
    List<Widget> view = [];
    int counter = 0; // for ListTile to track elements
    groupByRecipeId.forEach((rId, igrs) {
      if (igrs[0].recipeImg == "" || igrs[0].recipeImg == null) {
      } else {
        view.add(Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              igrs[0].recipeImg,
              height: screenSize.height * 0.2,
              width: screenSize.width * 0.30,
            ),
            Flexible(
                child: Padding(
                    padding: const EdgeInsets.all(basePadding),
                    child: Text(
                      igrs[0].recipeTitle,
                      style: const TextStyle(
                          color: white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    )))
          ],
        ));
      }

      for (int j = 0; j < igrs.length; j++) {
        Shopping_List cur = igrs[j];
        view.add(buildIngr(counter, cur));
        counter++;
      }
    });
    return view;
  }

  Widget buildIngr(int i, Shopping_List s) {
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
          title: s.done
              ? s.amount != 0.0
                  ? Text(
                      "${s.amount} ${s.unit} ${s.ingr.name}",
                      style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey),
                    )
                  : Text(
                      "${s.unit} ${s.ingr.name}",
                      style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey),
                    )
              : s.amount != 0.0
                  ? Text(
                      "${s.amount} ${s.unit} ${s.ingr.name}",
                      style: const TextStyle(color: Colors.black),
                    )
                  : Text(
                      "${s.unit} ${s.ingr.name}",
                      style: const TextStyle(color: Colors.black),
                    ),
          subtitle: s.cost != 0.0 && s.aisle != ""
              ? Text(
                  "\$${s.cost.toStringAsFixed(2)} - ${s.aisle}",
                  style:
                      const TextStyle(color: Color.fromARGB(255, 102, 150, 47)),
                )
              : const Text(""),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              s.done
                  ? IconButton(
                      icon: const Icon(Icons.check_box, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          s.done = false;
                          modifyShoppingList("Undone", s);
                        });
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.check_box_outline_blank,
                          color: Colors.white),
                      onPressed: () {
                        setState(() {
                          s.done = true;
                          modifyShoppingList("Done", s);
                          // ingrs.removeAt(i);
                          // ingrs.add(s);
                        });
                      },
                    ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  setState(() {
                    modifyShoppingList("Add", s);
                    s.amount += 1;
                    ingrs[i] = s;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white),
                onPressed: () {
                  setState(() {
                    if (s.amount - 1 <= 0) {
                      ingrs.removeAt(i);
                      deleteOneShoppingList(s);
                    } else {
                      //decrement by one
                      modifyShoppingList("Minus", s);
                      s.amount -= 1;
                      ingrs[i] = s;
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.blueGrey),
                onPressed: () {
                  setState(() {
                    ingrs.removeAt(i);
                    deleteOneShoppingList(s);
                  });
                },
              )
            ],
          ),
        ));
  }

  Widget emptyList(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // header label
          const Text(
            "Find recipes from the Discover tab now to add ingredients!",
            style: TextStyle(
              color: white,
              letterSpacing: 2.0,
              fontSize: 40,
            ),
            textAlign: TextAlign.center,
          ),
          // the ingredients from the recipe.
          const SizedBox(
            height: 10,
          ), // Used as spacer between buttons.
          if (Navigator.canPop(context)) doneButton(context),
        ],
      ),
    );
  }

  Center doneButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(basePadding),
            elevation: 10.0,
            textStyle: const TextStyle(color: Colors.white)),
        icon: const Icon(Icons.done),
        label: const Text('Done'),
      ),
    );
  }

  showAlertDialog(BuildContext context, String msg) {
    // set up the button
    Widget okButton = TextButton(
      child: const Text("OK"),
      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      content: Text(
        msg,
        style: const TextStyle(color: Colors.white),
      ),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (context, setState) => Theme(
                data: Theme.of(context)
                    .copyWith(dialogBackgroundColor: primaryGray),
                child: alert));
      },
    );
  }
}
