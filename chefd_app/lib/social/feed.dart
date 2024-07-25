import 'package:chefd_app/home_layout.dart';
import 'package:chefd_app/main.dart';
import 'package:chefd_app/social/comment_section.dart';
import 'package:chefd_app/social/create_post.dart';
import 'package:chefd_app/recipe/create_recipe.dart';
import 'package:chefd_app/models/feed_post_model.dart';
import 'package:chefd_app/social/other_profile.dart';
import 'package:chefd_app/theme/colors.dart';
import 'package:chefd_app/client_settings.dart';
import 'package:flutter/material.dart';

// Our social media feed from our users
// The layout was based off of a template
// ref: https://www.fluttertemplates.dev/widgets/must_haves/content_feed
class FeedWidget extends StatefulWidget {
  const FeedWidget({super.key});

  @override
  State<FeedWidget> createState() => _FeedWidgetState();
}

class _FeedWidgetState extends State<FeedWidget> {
  // How many posts are loaded in on this page.
  final _pageLimit = 30;
  final List<FeedPost> _postsOnFeed = [];
  bool hasData = false;
  final String defaultProfilePicture =
      "https://zwokvovrkprpsdjozoqa.supabase.co/storage/v1/object/public/misc/blank-profile-picture.png";

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      fetchPosts();
    });
  }

  // Query Posts from Database:
  Future<void> fetchPosts() async {
    // Join posts and userinfo.
    // later parsed by feedpost.dart.
    final postData = await supabase
        .from('posts')
        .select('*,userinfo(username,profile_picture)')
        .order('created')
        .limit(_pageLimit);

    // Tell main widget we've found data from the DB.
    if (!mounted) return;

    // Set the Posts on the social feed
    // uses feedpost.dart
    setState(() {
      List<dynamic> parsedData = postData;
      for (var p in parsedData) {
        FeedPost post = FeedPost.fromJson(p);
        _postsOnFeed.add(post);
      }
    });
    hasData = true;
  }

  refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryGray,
      appBar: AppBar(
        title: Center(
          child: Row(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width / 6,
              ),
              const Text('Social Feed'),
              SizedBox(
                width: MediaQuery.of(context).size.width / 8,
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomeWidget()));
                },
                label: const Text(
                  "refresh",
                  style: TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.underline),
                ),
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
              )
            ],
          ),
        ),
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
        backgroundColor: primaryOrange,
        centerTitle: true,
      ),

      // Create Post or recipe
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            createRecipeOrPost(context);
          },
          backgroundColor: primaryOrange,
          child: const Icon(Icons.add)),

      body: Center(
          child: _postsOnFeed.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: ListView.separated(
                    itemCount: _postsOnFeed.length,
                    separatorBuilder: (BuildContext context, int index) {
                      return const Divider(
                        color: Colors.white12,
                      );
                    },
                    itemBuilder: (BuildContext context, int index) {
                      final item = _postsOnFeed[index];
                      return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Prof Pic
                              _AvatarImage(item.postOwner.profilePicture ??
                                  defaultProfilePicture),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // UserName
                                      Expanded(
                                          child: RichText(
                                        overflow: TextOverflow.ellipsis,
                                        text: TextSpan(children: [
                                          TextSpan(
                                            text: item.postOwner.username,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: secondaryOrange),
                                          ),
                                        ]),
                                      )),
                                      // "Delete button" RHS
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: item.userId ==
                                                supabase.auth.currentUser!.id
                                            ? IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                color: Colors.white,
                                                onPressed: () async {
                                                  confirmDeletePopup(context).then(
                                                      (value) => startDelete(
                                                              context, item.id)
                                                          .then((value) =>
                                                              _requestDelete
                                                                  ? Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                          builder: (context) => const HomeWidget())).then((value) =>
                                                                      showDialog(
                                                                          context: context,
                                                                          builder: (context) {
                                                                            Future.delayed(const Duration(seconds: 2),
                                                                                () {
                                                                              Navigator.of(context).pop(true);
                                                                            });
                                                                            return const AlertDialog(
                                                                              title: Text('Posted!'),
                                                                            );
                                                                          }))
                                                                  : null));
                                                },
                                              )
                                            : Text(""),
                                      )
                                    ],
                                  ),
                                  // Description
                                  Text(
                                    item.body,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  // Post Photo
                                  Container(
                                    height: 200,
                                    margin: const EdgeInsets.only(top: 8.0),
                                    decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        image: DecorationImage(
                                          fit: BoxFit.cover,
                                          image: NetworkImage(item.picture),
                                        )),
                                  ),
                                  _ActionsRow(item: item)
                                ],
                              ))
                            ],
                          ));
                    },
                  ))),
    );
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
                        child: const Text("Post",
                            style: TextStyle(color: Colors.white)),
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
                        child: const Text("Recipe",
                            style: TextStyle(color: Colors.white)),
                      ),
                      SimpleDialogOption(
                        child: const Text("Cancel",
                            style: TextStyle(color: Colors.white)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  )));
        });
  }

  bool _requestDelete = false;
  confirmDeletePopup(context) {
    return showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) => Theme(
              data: Theme.of(context)
                  .copyWith(dialogBackgroundColor: primaryGray),
              child: AlertDialog(
                content: const Text("Delete your post?",
                    style: TextStyle(color: Colors.white)),
                actions: [
                  ElevatedButton(
                      child: const Text("No"),
                      onPressed: () {
                        _requestDelete = false;
                        Navigator.of(context).pop(); // pops the popup
                      }),
                  ElevatedButton(
                      child: const Text("Yes"),
                      onPressed: () {
                        _requestDelete = true;
                        Navigator.of(context).pop(); // pops the popup
                      })
                ],
              ),
            ),
          );
        });
  }

  // Check if user confirmed they want to upload Recipe
  Future<void> startDelete(context, postID) async {
    if (!_requestDelete) {
      return;
    }
    await supabase.from('posts').delete().eq('id', postID);
  }
}

class _AvatarImage extends StatelessWidget {
  final String url;
  const _AvatarImage(this.url, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(image: NetworkImage(url))),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  final FeedPost item;
  const _ActionsRow({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
          iconTheme: const IconThemeData(color: Colors.grey, size: 18),
          textButtonTheme: TextButtonThemeData(
              style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all(Colors.grey),
          ))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => OtherProfileWidget(item.userId)));
            },
            icon: const Icon(Icons.person_search),
            label: const Text("Profile"),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          CommentsSection(item.id, item.userId)));
            },
            icon: const Icon(Icons.mode_comment_outlined),
            label: const Text("Comments"),
          ),
        ],
      ),
    );
  }
}

class FeedItem {
  final String? content;
  final String? imageUrl;
  final User user;
  final int commentsCount;
  final int likesCount;
  final int retweetsCount;

  FeedItem(
      {this.content,
      this.imageUrl,
      required this.user,
      this.commentsCount = 0,
      this.likesCount = 0,
      this.retweetsCount = 0});
}

class User {
  final String fullName;
  final String imageUrl;
  final String userName;

  User(
    this.fullName,
    this.userName,
    this.imageUrl,
  );
}
