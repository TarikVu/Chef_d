import 'package:chefd_app/models/user_info_model.dart';
import 'package:chefd_app/recipe/recipe_view.dart';
import 'package:chefd_app/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:chefd_app/models/profile_post_model.dart';
import 'package:chefd_app/social/post_details.dart';
import 'package:chefd_app/utils/constants.dart';
import 'package:chefd_app/social/create_post.dart';

class OtherProfileWidget extends StatefulWidget {
  const OtherProfileWidget(this.otherUserID, {super.key});

  final String otherUserID;
  @override
  State<OtherProfileWidget> createState() => _OtherProfileWidgetState();
}

class _OtherProfileWidgetState extends State<OtherProfileWidget> {
  // Static posts to be displayed 3x3
  List<Widget> myRecipeTiles = [];
  List<dynamic>? posts;
  List<Widget> myPostTiles = [];

  // Initialize the Userinfo for now.
  // Overwritten after Db Query.
  UserInfo _userInfo = const UserInfo(
      difficulty: 0,
      timespend: 0,
      profilePicture: null,
      userId: "-1",
      username: "loading");
  String? _profilePicture = "";
  String _userName = "";
  final String _defaultProfilePicture =
      "https://zwokvovrkprpsdjozoqa.supabase.co/storage/v1/object/public/misc/blank-profile-picture.png";
  bool hasData = false;
  double avatarDiameter = 100;
  static EdgeInsets textMargin = const EdgeInsets.fromLTRB(8.0, 0, 0, 0);
  final double _avatarDiameter = 100;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      fetchUserData();
    });
  }

  Future<void> fetchUserData() async {
    // Fetch User info
    final userInfoData = await supabase
        .from(userInfo)
        .select('*')
        .eq('user_id', widget.otherUserID);

    // Set User's info
    List<dynamic>? infoAsList = userInfoData;
    _userInfo = UserInfo.fromJson(infoAsList![0]);
    _userName = _userInfo.username;
    _profilePicture = _userInfo.profilePicture;

    // Fetch User's posts
    final userPostsData = await supabase
        .from('posts')
        .select('*')
        .eq('user_id', widget.otherUserID)
        .order('created');

    // Fetch User's Created Recipes.
    final userCreatedRecipes = await supabase
        .from(recipes)
        .select("id, title, image, rating")
        .eq('author', _userInfo!.username);

    if (!mounted) return;
    setState(() {
      // Set User's info
      List<dynamic>? infoAsList = userInfoData;
      _userInfo = UserInfo.fromJson(infoAsList![0]);
      _userName = _userInfo!.username;
      _profilePicture = _userInfo?.profilePicture;

      // No profile picture URL in table, set to default
      _profilePicture ??= _defaultProfilePicture;

      posts = userPostsData; // parses out response from List<dynamic>

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
    });

    hasData = true;
  }

// Example layout.
// Ref: https://github.com/iamshaunjp/flutter-beginners-tutorial
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background, // Main background color for page
      // Top most Bar
      appBar: AppBar(
        title: Text("$_userName's Profile"),
        centerTitle: true,
        backgroundColor: primaryOrange,
        elevation: 0.0,
      ), // Create Post Button

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
                  color: Colors.grey,
                  letterSpacing: 2.0,
                  fontSize: 10.0,
                ),
              ),
            ),
          ),
          // Invis Spacer
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
          const SizedBox(height: 20.0),
          Divider(
            color: Colors.grey[800],
            height: 5.0,
          ),
          // My Recipes
          Padding(
            padding: textMargin,
            child: Text(
              "$_userName's Recipes",
              style: const TextStyle(
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
              'Social Media',
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
}
