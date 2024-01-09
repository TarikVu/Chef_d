import 'package:chefd_app/models/RecipeModel.dart';
import 'package:chefd_app/recipe.dart';
import 'package:chefd_app/theme/colors.dart';
import 'package:chefd_app/utils/constants.dart';
import 'package:chefd_app/utils/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:postgrest/src/types.dart';

class DiscoverWidget extends StatefulWidget {
  const DiscoverWidget({super.key});

  @override
  State<DiscoverWidget> createState() => _DiscoverWidgetState();
}

// The Widget for our discover page
class _DiscoverWidgetState extends State<DiscoverWidget> {
  List<dynamic>? recipesList = [];
  List<dynamic>? restrictedRecipesList = [];
  List<dynamic>? userRecipeList = [];
  List<dynamic>? userAllergyDiets = [];
  List<dynamic>? ignoreRecipeID = [];
  List<Recipe>? favoriteRecipeList = [];
  final _userId = supabase.auth.currentUser!.id;
  bool hasData = false;
  Size screenSize = const Size(100, 100);
  bool isPhone = false;

  bool searchActive = false;

  @override
  void initState() {
    super.initState();
    //https://stackoverflow.com/questions/56395081/unhandled-exception-inheritfromwidgetofexacttype-localizationsscope-or-inheri
    getRecipes();
  }

  Future<void> getRecipes() async {
    if (!mounted) return;

    final allData =
        await supabase.from(recipes).select("id, title, image, rating");

    if (userRecipeList!.isEmpty) {
      final userCreatedRecipes = await supabase
          .from(recipes)
          .select("id, title, image, rating")
          .eq('source', 'chefd');
      if (!mounted) return;
      setState(() {
        if (userCreatedRecipes.length != 0) {
          userRecipeList = userCreatedRecipes;
        }
      });
    }
    final allergyDiets = await supabase
        .from(userAllergiesDiets)
        .select('allergy_diet_id')
        .eq('user_id', userId);

    List<dynamic>? tempAllergyList = [];
    if (allergyDiets.length != 0) {
      for (var f in allergyDiets) {
        final data = await supabase
            .from(recipeAllergiesDiets)
            .select('recipe_id')
            .eq('allergy_diet_id', f['allergy_diet_id']);
        tempAllergyList.addAll(data);
      }
      ignoreRecipeID = tempAllergyList;
    }

    final favoriteRecipes = await supabase
        .from(favorites)
        .select('recipe_id, recipes(*)')
        .eq('user_id', _userId);

    setState(() {
      if (allData.length != 0 && !searchActive && recipesList!.isEmpty) {
        recipesList = allData;
        restrictedRecipesList?.addAll(allData);
      }
      if (ignoreRecipeID!.isNotEmpty) {
        List idsList =
            ignoreRecipeID!.map((entry) => entry['recipe_id']).toList();
        restrictedRecipesList!
            .removeWhere((recipe) => idsList.contains(recipe['id']));
      }

      for (var f in favoriteRecipes) {
        if (favoriteRecipeList!.contains(Recipe.setRecipe(f['recipes']))) {
          break;
        } else {
          favoriteRecipeList?.add(Recipe.setRecipe(f['recipes']));
        }
      }
    });
    if (recipesList != null) hasData = true;
    // return data;
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

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;
    if (screenSize.width > 500) {
      isPhone = false;
    } else {
      isPhone = true;
    }
    return FutureBuilder(
      future: getRecipes(),
      builder: (context, snapshot) {
        if (!hasData) {
          return _loadingScreen();
        } else {
          return discoverPage();
        }
      },
    );
  }

  Widget discoverPage() {
    return Scaffold(
        appBar: AppBar(
          title: Image.asset(
            'assets/logo.jpg',
            width: 250,
            height: 60,
          ),
          leading: IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SettingsWidget(),
                    settings: RouteSettings(
                        arguments: supabase.auth.currentUser!.id)),
              );
            },
          ),
          backgroundColor: primaryOrange,
          centerTitle: true,
        ),
        backgroundColor: background,
        body: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: ListView(
                //padding: const EdgeInsets.all(basePadding),
                children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      child: TextField(
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: white),
                        decoration: InputDecoration(
                            hintStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: white),
                            suffixIcon: const Icon(
                              Icons.search,
                              color: white,
                            ),
                            fillColor: white,
                            hintText: 'Search',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                            )),
                        onChanged: searchList,
                      )),
                  const Center(
                    child: Text(
                      "All Recipes",
                      style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: white),
                    ),
                  ),
                  const SizedBox(
                    height: divHeight,
                  ),
                  buildAllRecipes(recipesList!, 0.38, 0.27, 0.25),
                  const Center(
                    child: Text(
                      "Your Favorites",
                      style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: white),
                    ),
                  ),
                  const SizedBox(
                    height: divHeight,
                  ),
                  buildAllRecipes(favoriteRecipeList!, 0.3, 0.19, 0.19),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      "Chef'd Created Recipes",
                      style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: white),
                    ),
                  ),
                  const SizedBox(
                    height: divHeight,
                  ),
                  buildAllRecipes(userRecipeList!, 0.3, 0.19, 0.19),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      "Dietary Restricted Recipes",
                      style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: white),
                    ),
                  ),
                  const SizedBox(
                    height: divHeight,
                  ),
                  buildAllRecipes(restrictedRecipesList!, 0.3, 0.19, 0.19),
                  const SizedBox(height: 20),
                ])));
  }

  Widget buildAllRecipes(List<dynamic> list, double containerHeight,
      double imageHeight, double imageWidth) {
    List<Widget> cards = [];
    if (list == favoriteRecipeList) {
      cards = buildFavCards(list);
    } else {
      cards = buildRecipeCards(list, imageHeight, imageWidth);
    }
    return Container(
      height: screenSize.height * containerHeight,
      child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          separatorBuilder: (context, _) => const SizedBox(
                width: basePadding,
              ),
          itemBuilder: ((context, index) => cards[index])),
    );
  }

  List<Widget> buildFavCards(List<dynamic> cardList) {
    List<Widget> list = [];
    if (cardList.isEmpty) {
      list.add(const Center(
        child: Text(
          "Add some recipes to favorites",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 19, fontWeight: FontWeight.bold, color: white),
        ),
      ));
    } else {
      for (var r in cardList) {
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
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                RatingBar.builder(
                                  initialRating: r!.rating,
                                  direction: Axis.horizontal,
                                  allowHalfRating: true,
                                  itemSize: 10,
                                  itemCount: 5,
                                  maxRating: 5,
                                  ignoreGestures: true,
                                  itemBuilder: (context, _) => const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  onRatingUpdate: (value) => r!.rating,
                                ),
                                TextLabel(': ${r!.rating}', yellow, 8.0, false),
                              ]),
                          Flexible(child: TextLabel(r.title, white, 12, false)),
                        ],
                      ),
                    ),
                  ],
                ))));
        list.add(const SizedBox(
          width: basePadding,
        ));
      }
    }
    return list;
  }

  List<Widget> buildRecipeCards(
      List<dynamic> cardList, double imageHeight, double imageWidth) {
    List<Widget> list = [];
    if (cardList.isEmpty) {
      list.add(const Center(
        child: Text(
          "No recipes can be found",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 19, fontWeight: FontWeight.bold, color: white),
        ),
      ));
    } else {
      for (var r in cardList) {
        list.add(Container(
            width: screenSize.width * 0.20,
            height: screenSize.height * 0.20,
            child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RecipeWidget(),
                        settings: RouteSettings(arguments: r['id'])),
                  );
                },
                child: Column(
                  children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          r['image'],
                          height: screenSize.height * imageHeight,
                          width: screenSize.width * 0.20,
                          fit: BoxFit.cover,
                        )),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                RatingBar.builder(
                                  initialRating:
                                      double.parse(r['rating'].toString()),
                                  direction: Axis.horizontal,
                                  allowHalfRating: true,
                                  itemSize: 10,
                                  itemCount: 5,
                                  maxRating: 5,
                                  ignoreGestures: true,
                                  itemBuilder: (context, _) => const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  onRatingUpdate: (value) =>
                                      double.tryParse(r['rating']),
                                ),
                                TextLabel(
                                    ': ${r['rating']}', yellow, 8.0, false),
                              ]),
                          Flexible(
                              child: TextLabel(r['title'], white, 12, false)),
                        ],
                      ),
                    )
                  ],
                ))));
        list.add(const SizedBox(
          width: basePadding,
        ));
      }
    }
    return list;
  }

  void searchList(String q) {
    if (q.isEmpty) {
      searchActive = false;
    } else {
      searchActive = true;
    }
    final suggestions = recipesList?.where((element) {
      final label = element['title'].toString().toLowerCase();
      final input = q;
      return label.contains(input);
    }).toList();

    setState(() {
      recipesList = suggestions;
    });
  }
}
