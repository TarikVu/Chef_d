import 'package:chefd_app/recipe/create_recipe.dart';
import 'package:chefd_app/models/profile_post_model.dart';
import 'package:chefd_app/models/user_info_model.dart';
import 'package:chefd_app/pantry.dart';
import 'package:chefd_app/recipe/recipe_view.dart';
import 'package:chefd_app/theme/colors.dart';
import 'package:chefd_app/client_settings.dart';
import 'package:flutter/material.dart';
import 'package:chefd_app/social/post_details.dart';
import 'package:chefd_app/utils/constants.dart';
import 'package:chefd_app/social/create_post.dart';
import '../models/recipe_model.dart';

class MyProfileWidget extends StatefulWidget {
  const MyProfileWidget({super.key});

  @override
  State<MyProfileWidget> createState() => _MyProfileWidgetState();
}

class _MyProfileWidgetState extends State<MyProfileWidget> {
  // UserInfo
  final _userId = supabase.auth.currentUser!.id;
  UserInfo? _userInfo;
  String? _profilePicture = "";
  String _userName = "";

  final String _defaultProfilePicture =
      "https://zwokvovrkprpsdjozoqa.supabase.co/storage/v1/object/public/misc/blank-profile-picture.png";

  // Static posts to be displayed 3x3
  List<Widget> myPostTiles = [];
  List<Widget> myRecipeTiles = [];

  List<dynamic>? recipesList;
  List<Widget> favoriteRecipeCards = [];

  // Margins:
  static EdgeInsets textMargin = const EdgeInsets.fromLTRB(8.0, 0, 0, 0);
  final double _avatarDiameter = 100;
  Size screenSize = const Size(100, 100);

  // After initializing per usual we add our posts
  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      fetchFromDB();
    });
  }

  Future<void> fetchFromDB() async {
    // Fetch User's posts
    final userPostsData = await supabase
        .from('posts')
        .select('*')
        .eq('user_id', _userId)
        .order('created');

    // User info
    final userInfoData =
        await supabase.from(userInfo).select('*').eq('user_id', _userId);
    // Set User's info
    List<dynamic>? infoAsList = userInfoData;
    _userInfo = UserInfo.fromJson(infoAsList![0]);

    // Fetch User's favorited recipes.
    final favoriteRecipeResponse = await supabase
        .from(favorites)
        .select('recipe_id, recipes(*)')
        .eq('user_id', _userId);

    // Fetch User's Created Recipes.
    final userCreatedRecipes = await supabase
        .from(recipes)
        .select("id, title, image, rating")
        .eq('author', _userInfo!.username);

    if (!mounted) return;
    setState(() {
      _userName = _userInfo!.username;
      _profilePicture = _userInfo?.profilePicture;

      // No profile picture URL in table, set to default
      _profilePicture ??= _defaultProfilePicture;

      // Set User's posts into a dynamic list.
      List<dynamic>? posts = userPostsData;
      // Iterate each postJson and parse into Post, Insert into List of posts
      List<ProfilePost> myPosts = [];
      for (var p in posts!) {
        myPosts.add(ProfilePost.fromJson(p));
      }

      // Add each post into the myPostsTiles list,
      // this will then add them into the grid.
      for (ProfilePost post in myPosts) {
        myPostTiles.add(InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PostDetails(
                          post))); // Passing post data to postDetails
            },
            child: Image.network(
              post.picture,
              fit: BoxFit.fill,
            )));
      }

      // Set User's Recipes
      List<dynamic>? recipes = userCreatedRecipes; // parse into dynamic list
      for (var r in recipes!) {
        myRecipeTiles.add(InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const RecipeWidget(),
                    settings: RouteSettings(arguments: r!['id'])),
              );
            },
            child: Image.network(
              r['image'],
              fit: BoxFit.fill,
            )));
      }

      // Favorited Recipes:
      List<Recipe> favoriteRecipes = [];
      for (var f in favoriteRecipeResponse) {
        // Limit to 6 cards
        if (favoriteRecipes.length == 20) {
          break;
        }
        favoriteRecipes.add(Recipe.setRecipe(f['recipes']));
      }

      favoriteRecipeCards = buildRecipeCards(favoriteRecipes);
    });
  }

  createRecipeOrPost(parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setState) => Theme(
                  data: Theme.of(context)
                      .copyWith(dialogBackgroundColor: primaryGray),
                  child: SimpleDialog(
                    title: const Text(
                      "Create a post or recipe?",
                      style: TextStyle(color: Colors.white),
                    ),
                    children: <Widget>[
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.of(context)
                              .pop(); // close popup before going to new page
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const CreatePost()));
                          setState(() {
                            // refresh
                          });
                        },
                        child: const Text(
                          "Post",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.of(context)
                              .pop(); // close popup before going to new page
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const CreateRecipe()));
                          setState(() {
                            // refresh
                          });
                        },
                        child: const Text(
                          "Recipe",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SimpleDialogOption(
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  )));
        });
  }

  refresh() {
    Future.delayed(Duration.zero, () {
      fetchFromDB();
    });
    return;
  }

// Example layout.
// Ref: https://github.com/iamshaunjp/flutter-beginners-tutorial
  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: background, // Main background color for page
      // Top most Bar
      appBar: AppBar(
        title: const Text('My Profile'),
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
      ), // Create Post Button
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            createRecipeOrPost(context);
          },
          backgroundColor: primaryOrange,
          child: const Icon(Icons.add)),
      // Profile is inside of Scrollable view.
      body: SingleChildScrollView(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // Children of Scaffold Class [List]
        children: <Widget>[
          // Centralized Profile picture inside a Circle avatar class to look pretty.
          const SizedBox(height: 30.0),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                width: _avatarDiameter,
                height: _avatarDiameter,
                decoration: const BoxDecoration(
                  color: primaryOrange,
                  shape: BoxShape.circle,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_avatarDiameter),
                  child: Image.network(_profilePicture!, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                    return const Text("");
                  }),
                ),
              ),
            ),
          ),
          // Gray Bar divider
          Divider(
            color: Colors.grey[800],
            height: 60.0,
          ),

          // Profile Information

          Padding(
            padding: textMargin,
            child: const Center(
              child: Text(
                'NAME',
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 2.0,
                  fontSize: 10.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10.0),

          // User Name
          Padding(
            padding: textMargin,
            child: Center(
              child: Text(
                _userName,
                style: TextStyle(
                  color: Colors.amberAccent[200],
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10.0),

          // User Settings
          Center(
            child: Wrap(
              spacing: 5,
              children: [
                ElevatedButton(
                    onPressed: openSettings,
                    child: const Padding(
                      padding: EdgeInsets.all(basePadding - 5),
                      child: Text("Settings"),
                    )),
                ElevatedButton(
                    onPressed: openPantry,
                    child: const Padding(
                      padding: EdgeInsets.all(basePadding - 5),
                      child: Text("My Pantry"),
                    )),
              ],
            ),
          ),

          Divider(color: Colors.grey[800], height: 60.0),

          // Fav Recipes
          Padding(
            padding: textMargin,
            child: const Text(
              'My Favorite Recipes',
              style: TextStyle(
                color: Colors.white,
                letterSpacing: 3.0,
                fontSize: 20.0,
              ),
            ),
          ),
          const SizedBox(height: 10.0),
          favoriteRecipeCards.isNotEmpty
              ? buildFavoriteRecipes()
              : const Center(
                  child: Text(
                  "No Favorite Recipes yet!",
                  style: TextStyle(color: secondaryOrange, fontSize: 15),
                )),
          Divider(
            color: Colors.grey[800],
            height: 5.0,
          ),

          // My Recipes
          Padding(
            padding: textMargin,
            child: const Text(
              'My Recipes',
              style: TextStyle(
                color: Colors.white,
                letterSpacing: 3.0,
                fontSize: 20.0,
              ),
            ),
          ),
          const SizedBox(height: 10.0),
          myRecipeTiles.isNotEmpty
              ? GridView.count(
                  crossAxisCount: 3,
                  scrollDirection: Axis.vertical,
                  padding: const EdgeInsets.all(6.0),
                  mainAxisSpacing: 4.0,
                  crossAxisSpacing: 4.0,
                  shrinkWrap: true,
                  children: [...myRecipeTiles],
                )
              : const Center(
                  child: Text(
                  "No Created Recipes yet!",
                  style: TextStyle(color: secondaryOrange, fontSize: 15),
                )),
          const SizedBox(height: 20.0),

          Divider(
            color: Colors.grey[800],
            height: 5.0,
          ),

          // My posts
          Padding(
            padding: textMargin,
            child: const Text(
              'My Posts',
              style: TextStyle(
                color: Colors.white,
                letterSpacing: 3.0,
                fontSize: 20.0,
              ),
            ),
          ),
          const SizedBox(height: 10.0),
          myPostTiles.isNotEmpty
              ? GridView.count(
                  crossAxisCount: 3,
                  scrollDirection: Axis.vertical,
                  padding: const EdgeInsets.all(6.0),
                  mainAxisSpacing: 4.0,
                  crossAxisSpacing: 4.0,
                  shrinkWrap: true,
                  children: [...myPostTiles],
                )
              : const Center(
                  child: Text(
                  "No Posts yet!",
                  style: TextStyle(color: secondaryOrange, fontSize: 15),
                )),
        ],
      )),
    );
  }

  void openPantry() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const PantryWidget(),
            settings: RouteSettings(arguments: userId)));
  }

  void openSettings() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const SettingsWidget(),
            settings: RouteSettings(arguments: userId)));
  }

  Widget buildFavoriteRecipes() {
    return SizedBox(
      height: screenSize.height * 0.30,
      child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: favoriteRecipeCards.length,
          separatorBuilder: (context, _) => const SizedBox(
                width: basePadding,
              ),
          itemBuilder: ((context, index) => favoriteRecipeCards[index])),
    );
  }

  List<Widget> buildRecipeCards(List<Recipe> favoriteRecipes) {
    List<Widget> list = [];
    for (var r in favoriteRecipes) {
      list.add(SizedBox(
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
}
