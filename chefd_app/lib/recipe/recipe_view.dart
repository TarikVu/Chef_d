import 'package:chefd_app/recipe/cooknow.dart';
import 'package:chefd_app/recipe/create_review.dart';
import 'package:chefd_app/models/recipe_review_model.dart';
import 'package:chefd_app/models/recipe_ingredients_model.dart';
import 'package:chefd_app/recipe/recipe_review.dart';
import 'package:chefd_app/shopping_list.dart';
import 'package:chefd_app/utils/db_functions.dart';
import 'package:flutter/material.dart';
import 'package:chefd_app/utils/constants.dart';
import 'dart:async';
import 'package:chefd_app/theme/colors.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/recipe_model.dart';
import 'package:pie_chart/pie_chart.dart';

class RecipeWidget extends StatefulWidget {
  const RecipeWidget({super.key});

  @override
  State<RecipeWidget> createState() => _RecipeWidgetState();
}

class _RecipeWidgetState extends State<RecipeWidget> {
  Recipe? r;
  List<RecipeIngredients>? ingrs;
  List<int> shoppingList = [];
  List<Recipe> relatedRecipes = [];
  List<RecipeReview>? reviews = [];
  int numRelatedRecipes = 20; // but only gets 11?
  int recipeID = 0;
  bool hasData = false;
  bool insertDone = false;
  bool isFavorited = false;
  Size screenSize = const Size(100, 100);
  bool isPhone = false;
  String currentUserName = "";

  /// The user that is currently logged in
  dynamic user;

  //SliverAppBar
  //https://stackoverflow.com/questions/58970477/make-sliverappbar-have-an-image-as-a-background-instead-of-a-color
  //Change color tab bar
  //https://stackoverflow.com/questions/50566868/how-to-change-background-color-of-tabbar-without-changing-the-appbar-in-flutter
  //Tab Bar
  //https://www.youtube.com/watch?v=s_3ak-4u43E&ab_channel=HeyFlutter%E2%80%A4com

  @override
  void initState() {
    super.initState();
    //https://stackoverflow.com/questions/56395081/unhandled-exception-inheritfromwidgetofexacttype-localizationsscope-or-inheri
    Future.delayed(Duration.zero, () {
      recipeID = ModalRoute.of(context)!.settings.arguments as int;
      getRecipe();
    });
  }

  Future<List> _processData() {
    return Future.wait([getRecipe()]);
  }

  Future<void> getRecipe() async {
    final recipeResponse =
        await supabase.from(recipes).select("*").eq('id', recipeID);

    final recIngrResponse = await supabase
        .from(recipeIngredients)
        .select('ingredient_id, amount, unit, full_text, ingredients(label)')
        .eq('recipe_id', recipeID);

    user = supabase.auth.currentUser;

    isRecipeFavorited(); // Check to determine button state.

    final shoppingListResponse =
        await supabase.from(shoppingCart).select().eq("user_id", user.id);

    //Grabs specified amount of recipes from random_recipes views table.
    getRecipes();

    final reviewResponse = await supabase
        .from(recipeReviews)
        .select('*, userinfo(username)')
        .eq('recipe_id', recipeID);

    final userResponse = await supabase
        .from('userinfo')
        .select('username')
        .eq('user_id', userId);

    if (reviewResponse.length != 0) {
      reviews = RecipeReview.setReviews(reviewResponse);
    }

    // Ensure that widget is mounted before setting state.
    if (!mounted) return;

    setState(() {
      // the recipe doesn't exist.
      if (recipeResponse.length != 0) {
        r = Recipe.setRecipe(recipeResponse[0]);
      }
      // if ingredients can't be found.
      if (recIngrResponse.length != 0) {
        ingrs = RecipeIngredients.getIngrList(recIngrResponse, recipeID);
      }
      if (shoppingListResponse.length != 0) {
        for (var ingr in shoppingListResponse) {
          if (!shoppingList.contains(ingr['ingredient_id'])) {
            shoppingList.add(ingr['ingredient_id']);
          }
        }
      }
      if (userResponse.length != 0) {
        currentUserName = userResponse[0]['username'].toString();
      }

      if (r != null &&
          ingrs != null &&
          user != null &&
          relatedRecipes.isNotEmpty) {
        hasData = true;
      }
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
            return _recipeScreen();
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

  Widget _recipeScreen() {
    return DefaultTabController(
        length: 3,
        child: Scaffold(
          body: NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                      flexibleSpace: FlexibleSpaceBar(
                        collapseMode: CollapseMode.parallax,
                        centerTitle: true,
                        // title: Text(r!.title,
                        //     style: const TextStyle(
                        //       color: Colors.blue,
                        //       fontSize: 30.0,
                        //     )),
                        background: Image.network(r!.image, fit: BoxFit.cover),
                      ),
                      expandedHeight: MediaQuery.of(context).size.height * 0.35,
                      backgroundColor: background,
                      bottom: PreferredSize(
                          preferredSize: _tabBar.preferredSize,
                          child:
                              ColoredBox(color: background, child: _tabBar))),
                ];
              },
              body: TabBarView(children: [
                buildRecipeHomeTab(),
                buildIngredientsTab(),
                buildReviewsTab()
              ])),
        ));
  }

  Widget buildRecipeHomeTab() {
    return Container(
      decoration: const BoxDecoration(color: background),
      child: ListView(
        //padding: const EdgeInsets.all(basePadding),
        children: [
          r?.title == null
              ? TextLabel("loading", primaryOrange, 25.0, true)
              : TextLabel(r!.title, primaryOrange, 25.0, true),
          r?.author == null
              ? TextLabel("", secondaryOrange, 17.0, false)
              : TextLabel("By: ${r!.author}", grey, 17.0, false),
          r?.rating == null
              ? TextLabel("", secondaryOrange, 17.0, false)
              : Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          TextLabel('${r!.rating} stars', yellow, 17.0, false),
                          RatingBar.builder(
                            initialRating: r!.rating,
                            direction: Axis.horizontal,
                            allowHalfRating: true,
                            itemSize: 20,
                            itemCount: 5,
                            maxRating: 5,
                            ignoreGestures: true,
                            itemBuilder: (context, _) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            onRatingUpdate: (value) => r!.rating,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                        flex: 2,
                        child: IconButton(
                          icon: isFavorited == true
                              ? const Icon(color: Colors.red, Icons.favorite)
                              : const Icon(
                                  color: Colors.red, Icons.favorite_outline),
                          onPressed: addRecipeToFavoritesDB,
                        )),
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: ElevatedButton.icon(
                          onPressed: cookNow,
                          icon: const Icon(
                            Icons.food_bank_rounded,
                            size: 30,
                          ),
                          label: const Text('Cook Now'),
                        ),
                      ),
                    ),
                  ],
                ),
          // Gray Bar divider
          const Divider(
            color: grey,
            height: divHeight / 2,
          ),
          Row(
            children: [
              Expanded(
                  child: Column(
                children: [
                  TextLabel("Servings:", grey, 10.0, false),
                  r?.rating == null
                      ? TextLabel("N/A", secondaryOrange, 13.0, true)
                      : TextLabel(
                          r!.servings.toString(), secondaryOrange, 13.0, true),
                ],
              )),
              Expanded(
                  child: Column(
                children: [
                  TextLabel("Calories:", grey, 10.0, false),
                  r?.totalTime == null
                      ? TextLabel("N/A", secondaryOrange, 13.0, true)
                      : TextLabel(
                          r!.calories.toString(), secondaryOrange, 13.0, true),
                ],
              )),
              Expanded(
                  child: Column(
                children: [
                  TextLabel("Total Time:", grey, 10.0, false),
                  r?.totalTime == null
                      ? TextLabel("N/A", secondaryOrange, 13.0, true)
                      : TextLabel("${r!.totalTime.toString()} mins",
                          secondaryOrange, 13.0, true),
                ],
              )),
            ],
          ),
          // Gray Bar divider
          const Divider(
            color: grey,
            height: divHeight / 2,
          ),

          Row(
            children: [
              Expanded(
                  child: Column(
                children: [
                  TextLabel("Prep Time:", grey, 10.0, false),
                  r?.totalTime == null
                      ? TextLabel("N/A", secondaryOrange, 13.0, true)
                      : TextLabel("${r!.prepTime.toString()} mins",
                          secondaryOrange, 13.0, true),
                ],
              )),
              Expanded(
                  child: Column(
                children: [
                  TextLabel("Cook Time:", grey, 10.0, false),
                  r?.totalTime == null
                      ? TextLabel("N/A", secondaryOrange, 13.0, true)
                      : TextLabel("${r!.cookTime.toString()} mins",
                          secondaryOrange, 13.0, true),
                ],
              )),
            ],
          ),
          headerLabel("Nutrition"),
          buildPie(),
          Center(
            child: TextLabel(
                "Check out these other Recipes", primaryOrange, 20, true),
          ),
          const SizedBox(
            height: divHeight / 2,
          ),
          buildOtherRecipes(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.all(basePadding),
                child: ElevatedButton(
                  onPressed: madeRecipe,
                  child: const Padding(
                    padding: EdgeInsets.all(basePadding - 5),
                    child: Text('Recipe Made'),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(basePadding),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.done),
                  label: const Text('Done'),
                ),
              ),
            ],
          ),
          Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                r?.author == currentUserName
                    ? Padding(
                        padding: EdgeInsets.all(basePadding),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            deleteRecipe(r, currentUserName);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete Recipe'),
                        ),
                      )
                    : const Text(""),
              ]),
        ],
      ),
    );
  }

  Widget buildIngredientsTab() {
    return Container(
        decoration: const BoxDecoration(color: background),
        child: ListView(
          children: [
            Center(
                child: TextLabel("Total number of items: ${ingrs?.length}",
                    white, 20, true)),
            const SizedBox(
              height: divHeight / 2,
            ),
            buildIngredientsView(),
            const SizedBox(
              height: divHeight / 2,
            ),
            Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          //https://www.reddit.com/r/flutterhelp/comments/10aujar/how_to_use_futurebuilder_with_navigator_and/
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      FutureBuilder(
                                          future: insertIngrsToDB(),
                                          builder:
                                              (BuildContext context, snapshot) {
                                            if (!insertDone) {
                                              return _loadingScreen();
                                            } else {
                                              return const ShoppingList();
                                            }
                                          })));
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(basePadding),
                          child: Text('Add all to Shopping List'),
                        ),
                      ),
                    )),
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.done),
                    label: const Text('Done'),
                  ),
                )
              ],
            )
          ],
        ));
  }

  Widget buildReviewsTab() {
    //return const RecipeReviewWidget();
    return Container(
        height: screenSize.height * 0.45,
        decoration: const BoxDecoration(color: background),
        child: ListView(
          children: [
            Center(
              child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateReviewWidget(),
                          settings: RouteSettings(arguments: r),
                        ));
                  },
                  //createReview,
                  child: const Padding(
                      padding: EdgeInsets.all(basePadding),
                      child: Text('Create a review'))),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [buildReviewsColumn()],
            ),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.done),
                label: const Text('Done'),
              ),
            ),
          ],
        ));
  }

  Widget buildIngredientsView() {
    return Container(
      height: screenSize.height * 0.45,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
          color: white, borderRadius: BorderRadius.all(Radius.circular(4))),
      child: ListView.builder(
          itemCount: ingrs?.length,
          itemBuilder: (context, index) {
            return buildIngr(index, ingrs![index]);
          }),
    );
  }

  Widget buildIngr(int i, RecipeIngredients ingr) {
    bool isAdded = false;
    if (shoppingList.contains(ingr.ingrID)) {
      isAdded = true;
    }
    return Container(
        decoration: const BoxDecoration(
            color: background,
            borderRadius: BorderRadius.all(Radius.circular(4))),
        margin: const EdgeInsets.all(4.0),
        key: ValueKey(i),
        child: ListTile(
          key: Key('$i'),
          title: ingr.amount == 0.0
              ? Text("${ingr.ingr.name}",
                  style: const TextStyle(color: Colors.white, fontSize: 15))
              : Text("${ingr.amount} ${ingr.unit} ${ingr.ingr.name}",
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              icon: isAdded
                  ? const Icon(Icons.check, color: Colors.blue)
                  : const Icon(Icons.add, color: Colors.blue),
              onPressed: () {
                if (!isAdded) {
                  ingrToShoppingList("Add", ingr);
                }
              },
            ),
          ]),
        ));
  }

  Widget buildOtherRecipes() {
    List<Widget> cards = buildRecipeCards();
    return Container(
      height: screenSize.height * 0.30,
      child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: relatedRecipes.length,
          separatorBuilder: (context, _) => const SizedBox(
                width: basePadding,
              ),
          itemBuilder: ((context, index) => cards[index])),
    );
  }

  List<Widget> buildRecipeCards() {
    List<Widget> list = [];
    for (var r in relatedRecipes) {
      list.add(Container(
          width: screenSize.width * 0.20,
          height: screenSize.height * 0.20,
          child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RecipeWidget(),
                      settings: RouteSettings(arguments: r.id)),
                );
              },
              child: Column(
                children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        r.image,
                        height: screenSize.height * 0.20,
                        width: screenSize.width * 0.20,
                        fit: BoxFit.cover,
                      )),
                  Flexible(child: TextLabel(r.title, white, 12, false)),
                ],
              ))));
      list.add(const SizedBox(
        width: basePadding,
      ));
    }
    return list;
  }

  Widget buildReviewsColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: buildReviewRows(),
    );
  }

  List<Widget> buildReviewRows() {
    List<Widget> list = [];
    reviews?.sort(((a, b) {
      return a.body.toLowerCase().compareTo(b.body.toLowerCase());
    }));
    for (RecipeReview r in reviews!) {
      if (r.userID == userId) {
        list.insert(
            0,
            Padding(
                padding: const EdgeInsets.all(basePadding),
                child: Column(
                  children: [
                    const Center(
                      child: Text(
                        "My Review",
                        style: TextStyle(color: primaryOrange, fontSize: 20),
                      ),
                    ),
                    Row(
                      children: [
                        RatingBar.builder(
                          initialRating: r.rating,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          maxRating: 5,
                          ignoreGestures: true,
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (value) => value,
                        ),
                        Flexible(
                            child: TextLabel("${r.rating} stars",
                                secondaryOrange, 10, false))
                      ],
                    ),
                    Row(
                      children: [
                        Flexible(child: TextLabel(r.body, white, 14, false)),
                        const SizedBox(
                          height: divHeight,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Flexible(
                            child: TextLabel("By: ${r.username}",
                                secondaryOrange, 14, false)),
                        const SizedBox(
                          height: divHeight,
                        ),
                      ],
                    ),
                    r.picture != ""
                        ? Image.network(
                            r.picture,
                            width: screenSize.width * 0.3,
                            height: screenSize.height * 0.15,
                          )
                        : const Text(""),
                  ],
                )));
      } else {
        list.add(Padding(
            padding: const EdgeInsets.all(basePadding),
            child: Column(
              children: [
                Row(
                  children: [
                    RatingBar.builder(
                      initialRating: r.rating,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      maxRating: 5,
                      ignoreGestures: true,
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (value) => value,
                    ),
                    Flexible(
                        child: TextLabel(
                            "${r.rating} stars", secondaryOrange, 10, false))
                  ],
                ),
                Row(
                  children: [
                    Flexible(child: TextLabel(r.body, white, 14, false)),
                    const SizedBox(
                      height: divHeight,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Flexible(
                        child: TextLabel(
                            "By: ${r.username}", secondaryOrange, 14, false)),
                    const SizedBox(
                      height: divHeight,
                    ),
                  ],
                ),
                r.picture != ""
                    ? Image.network(
                        r.picture,
                        width: screenSize.width * 0.3,
                        height: screenSize.height * 0.15,
                      )
                    : const Text(""),
              ],
            )));
      }
    }
    return list;
  }

  // Check the DB to see if recipe is already favorited or not.
  // Update the global isFavorited accordingly.
  void isRecipeFavorited() async {
    // Check to see if recipe exists
    List<dynamic> favResponse = await supabase
        .from(favorites)
        .select()
        .eq('user_id', user.id)
        .eq('recipe_id', recipeID);
    if (favResponse.isEmpty) {
      isFavorited = false;
    } else {
      isFavorited = true;
    }
  }

  void addRecipeToFavoritesDB() async {
    if (isFavorited) {
      await supabase
          .from(favorites)
          .delete()
          .eq('user_id', user.id)
          .eq('recipe_id', recipeID);
      isFavorited = false;
    } else {
      await supabase
          .from(favorites)
          .insert({'user_id': user.id, 'recipe_id': recipeID});
      isFavorited = true;
    }
  }

  void cookNow() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const CookNowWidget(),
            settings: RouteSettings(arguments: recipeID)));
  }

  void showReviews() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const RecipeReviewWidget(),
            settings: RouteSettings(arguments: recipeID)));
  }

  Future<void> insertIngrsToDB() async {
    if (ingrs != null) {
      for (int i = 0; i < ingrs!.length; i++) {
        try {
          await supabase
              .from(shoppingCart)
              .select('*')
              .eq('user_id', user.id)
              .eq('ingredient_id', ingrs![i].ingrID)
              .eq('recipe_id', recipeID)
              .single();
        } catch (e) {
          await supabase.from(shoppingCart).insert({
            //default user id to 0 for now.
            'user_id': user.id,
            'amount': ingrs![i].amount,
            'unit': ingrs![i].unit,
            'ingredient_id': ingrs![i].ingrID,
            'done': false,
            'recipe_id': r!.id
          });
        }
      }
      insertDone = true;
    }
  }

  Column headerLabel(String name) {
    return Column(
      children: [
        const SizedBox(
          height: divHeight,
        ),
        Center(
          child: TextLabel(name, primaryOrange, 25.0, true),
        ),
        const SizedBox(
          height: divHeight,
        ),
      ],
    );
  }

  /// Add, Remove, or Mark ingredient as done. Update accordingly with DB and UI.
  void ingrToShoppingList(String mod, RecipeIngredients ingr) async {
    switch (mod) {
      case "Add":
        //Check if ingredient already exists in Shopping
        try {
          final response = await supabase
              .from(shoppingCart)
              .select('*')
              .eq('user_id', user.id)
              .eq('ingredient_id', ingr.ingrID)
              .single();
        } catch (e) {
          // Ingredient already in Shopping
          await supabase.from(shoppingCart).insert({
            'user_id': user.id,
            'ingredient_id': ingr.ingrID,
            'amount': ingr.amount,
            'unit': ingr.unit,
            'recipe_id': r!.id
          });
        }
        break;
      case "Remove":
        try {
          final response = await supabase
              .from(shoppingCart)
              .select('*')
              .eq('user_id', user.id)
              .eq('ingredient_id', ingr.ingrID)
              .single();

          await supabase
              .from(shoppingCart)
              .delete()
              .eq('user_id', user.id)
              .eq('ingredient_id', ingr.ingrID);
          setState(() {});
        } catch (e) {}
        break;
    }
  }

  /// https://pub.dev/packages/pie_chart
  PieChart buildPie() {
    return PieChart(
      chartType: ChartType.disc,
      dataMap: {
        "Carbs (g)": r!.carbs!.toDouble(),
        "Cholesterol (g)": r!.cholesterol!.toDouble() / 1000,
        "Fiber (g)": r!.fiber!.toDouble(),
        "Protein (g)": r!.protein!.toDouble(),
        "Saturated Fat (g)": r!.satFat!.toDouble(),
        "Sodiumn (g)": r!.sodium!.toDouble() / 1000,
        "Sugar (g)": r!.sugar!.toDouble(),
        "Fat (g)": r!.fat!.toDouble(),
        "Unsaturated Fat (g)": r!.unFat!.toDouble(),
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

  // // Returns that a column that includes the important Recipe Page buttons.
  // // Accounts for screen size.
  // Column buildButtons() {
  //   List<Row> list = [];
  //   if (isPhone) {
  //     list.add(Row(
  //       children: [
  //         Expanded(
  //           flex: 3,
  //           child: Center(
  //             child: ElevatedButton(
  //               onPressed: () {
  //                 Navigator.pop(context);
  //                 //https://www.reddit.com/r/flutterhelp/comments/10aujar/how_to_use_futurebuilder_with_navigator_and/
  //                 Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                         builder: (BuildContext context) => FutureBuilder(
  //                             future: insertIngrsToDB(),
  //                             builder: (BuildContext context, snapshot) {
  //                               if (!insertDone) {
  //                                 return _loadingScreen();
  //                               } else {
  //                                 return const ShoppingList();
  //                               }
  //                             })));
  //               },
  //               child: const Padding(
  //                 padding: EdgeInsets.all(basePadding - 5),
  //                 child: Text('Add to Shopping List'),
  //               ),
  //             ),
  //           ),
  //         ),
  //         Expanded(
  //           flex: 3,
  //           child: Center(
  //             child: ElevatedButton(
  //               onPressed: addRecipeToFavoritesDB,
  //               child: Padding(
  //                   padding: const EdgeInsets.all(basePadding - 5),
  //                   child: Text(isFavorited == false
  //                       ? "Add to Favorites"
  //                       : "Remove from Favorites")),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ));
  //     list.add(const Row(
  //       children: [
  //         SizedBox(
  //           height: divHeight,
  //         ),
  //       ],
  //     ));
  //     list.add(Row(
  //       children: <Widget>[
  //         Expanded(
  //           flex: 3,
  //           child: Center(
  //             child: ElevatedButton(
  //               onPressed: cookNow,
  //               child: const Padding(
  //                 padding: EdgeInsets.all(basePadding - 5),
  //                 child: Text('Start Cooking Now'),
  //               ),
  //             ),
  //           ),
  //         ),
  //         Expanded(
  //           flex: 3,
  //           child: Center(
  //             child: ElevatedButton(
  //               onPressed: madeRecipe,
  //               child: const Padding(
  //                 padding: EdgeInsets.all(basePadding - 5),
  //                 child: Text('Recipe Made'),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ));
  //   } else {
  //     list.add(Row(
  //       // Code section of the buttons found on the recipe page.
  //       children: <Widget>[
  //         //const Spacer(),
  //         Expanded(
  //           child: Center(
  //             child: ElevatedButton(
  //               onPressed: () {
  //                 //https://www.reddit.com/r/flutterhelp/comments/10aujar/how_to_use_futurebuilder_with_navigator_and/
  //                 Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                         builder: (BuildContext context) => FutureBuilder(
  //                             future: insertIngrsToDB(),
  //                             builder: (BuildContext context, snapshot) {
  //                               if (!insertDone) {
  //                                 return _loadingScreen();
  //                               } else {
  //                                 return const ShoppingList();
  //                               }
  //                             })));
  //               },
  //               child: const Padding(
  //                 padding: EdgeInsets.all(basePadding),
  //                 child: Text('Add to Shopping List'),
  //               ),
  //             ),
  //           ),
  //         ),
  //         Expanded(
  //           flex: 3,
  //           child: Center(
  //             child: ElevatedButton(
  //               onPressed: addRecipeToFavoritesDB,
  //               child: Padding(
  //                   padding: const EdgeInsets.all(basePadding),
  //                   child: Text(isFavorited == false
  //                       ? "Add to Favorites"
  //                       : "Remove from Favorites")),
  //             ),
  //           ),
  //         ),
  //         Expanded(
  //           child: Center(
  //             child: ElevatedButton(
  //               onPressed: cookNow,
  //               child: const Padding(
  //                 padding: EdgeInsets.all(basePadding),
  //                 child: Text('Start Cooking Now'),
  //               ),
  //             ),
  //           ),
  //         ),
  //         Expanded(
  //           child: Center(
  //             child: ElevatedButton(
  //               onPressed: madeRecipe,
  //               child: const Padding(
  //                 padding: EdgeInsets.all(basePadding),
  //                 child: Text('Recipe Made'),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ));
  //   }
  //   return Column(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     crossAxisAlignment: CrossAxisAlignment.center,
  //     children: list,
  //   );
  // }

  void madeRecipe() {
    addEvent(DateTime.now(), recipeID);
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Recipe inserted into your meal calendar!"),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    //reviewInputController.text = "";
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(1),
                    child: Text('OK'),
                  ),
                ),
              ],
            ));
  }

  Future<void> getRecipes() async {
    final otherRecipeResponse = await supabase
        .from('random_recipes')
        .select('*')
        .limit(numRelatedRecipes);
    for (var r in otherRecipeResponse) {
      Recipe recipe = Recipe.setRecipe(r);
      if (relatedRecipes.length <= numRelatedRecipes) {
        if (recipe.id != recipeID) relatedRecipes.add(recipe);
      }
    }
  }
}

Future<void> deleteRecipe(Recipe? r, String currentUserName) async {
  try {
    await supabase
        .from(recipes)
        .delete()
        .eq('title', r!.title)
        .eq('id', r.id)
        .eq('author', currentUserName)
        .eq('source', 'chefd');
  } catch (e) {}
}

TabBar get _tabBar => const TabBar(
        padding: EdgeInsets.all(basePadding / 2),
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        tabs: [
          Tab(icon: Icon(Icons.home_rounded), text: "Overview"),
          Tab(icon: Icon(Icons.format_list_bulleted), text: "Ingredients"),
          Tab(icon: Icon(Icons.reviews_outlined), text: "Reviews"),
        ]);
