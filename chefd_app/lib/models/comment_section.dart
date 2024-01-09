import 'package:chefd_app/main.dart';
import 'package:chefd_app/models/other_profile.dart';
import 'package:flutter/material.dart';
import 'package:chefd_app/theme/colors.dart';
import 'package:flutter/services.dart';

// The Comments section page a user sees when clicking on a post.
class CommentsSection extends StatefulWidget {
  const CommentsSection(this.postID, this.postOwnerID, {super.key});

  // Passed into the _CommentsSectionState
  // Accessible via widget.postID
  final int postID;
  final String postOwnerID;

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  // Controller to grab input & upload the comment.
  final TextEditingController _commentController = TextEditingController();

  // All Comments of this post from DB
  List<Comment> _allComments = [];

  // All comments shown on current page
  List<Comment> _pageComments = [];

  // Page Logic
  int _pageLimit = 0;
  int _pageNumber = 1;
  final _commentsPerPage = 10;

  // Profile Picture logic.
  final String _defaultProfilePicture =
      "https://zwokvovrkprpsdjozoqa.supabase.co/storage/v1/object/public/misc/blank-profile-picture.png";
  final avatarDiameter = 44.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      fetchFromDB();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool _finishedCheckingDB = false;

  // Called upon first opening a comment section
  // Also Called upon a comment being uploaded,
  // In that case we'd need to reset and clear allcomments and page comments.
  Future<void> fetchFromDB() async {
    // Reset on comment upload,
    _allComments = [];
    _pageComments = [];

    // This should return a nested json.
    // Refer to "FeedPost.dart" for nested parsing.
    final commentsData = await supabase
        .from('comments')
        .select('*,userinfo(username,profile_picture)')
        .eq('post_id', widget.postID)
        .order('id', ascending: false); // ordering by id instead of date.

    if (!mounted) return;
    setState(() {
      // pase data into dynamic list, and parse the json.
      List<dynamic>? commentsDataAsList = commentsData;
      for (var c in commentsDataAsList!) {
        Comment com = Comment.fromJson(c);
        _allComments.add(com);
      }

      _pageLimit = (_allComments.length / 10).ceil();
      updatePage();

      _finishedCheckingDB = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(scaffoldBackgroundColor: background),
      home: Scaffold(
          appBar: AppBar(
            title: const Text("Comments"),
            backgroundColor: primaryOrange,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          extendBodyBehindAppBar: true,
          // Main body of page.
          body: Column(
            children: <Widget>[
              !_finishedCheckingDB
                  //? const Expanded(
                  ? Center(child: CircularProgressIndicator())
                  //)
                  : buildComments(),
              pageButtons(),
              pageDivider(),
              commentBox(),
            ],
          )),
    );
  }

  Widget buildComments() {
    return
        //_allComments.isEmpty
        //? const Expanded(
        // ? Center(
        //     child: Text(
        //     "Be the first to comment!",
        //     style: TextStyle(fontSize: 25, color: Colors.white),
        //   ))
        // //)
        // //: Expanded(:
        Container(
      height: MediaQuery.of(context).size.height / 1.4,
      margin: const EdgeInsets.all(10),
      child: ListView.separated(
          separatorBuilder: ((context, index) => const SizedBox(
                height: 5,
              )),
          itemCount: _pageComments.length, // Adjust for pages.
          shrinkWrap: true,
          itemBuilder: ((context, index) {
            //return Expanded(
            return Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(children: [
                    Container(
                      width: avatarDiameter,
                      height: avatarDiameter,
                      decoration: const BoxDecoration(
                        color: primaryOrange,
                        shape: BoxShape.circle,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(avatarDiameter / 2),
                        child: Image.network(
                          // The Owner's Profile picture
                          _pageComments[index].commentOwner.profilePicture ==
                                  null
                              ? _defaultProfilePicture
                              : _pageComments[index]
                                  .commentOwner
                                  .profilePicture!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Owner's Username
                    Text(
                      _pageComments[index].commentOwner.username,
                      style: const TextStyle(
                        color: white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),

                    // Options for the comment
                    IconButton(
                      onPressed: () {
                        commentOptions(_pageComments[index].userID, index);
                      },
                      icon: const Icon(
                        Icons.more_horiz,
                        color: primaryOrange,
                      ),
                    ),
                  ]),
                ),

                // Comment itself
                const SizedBox(width: 10),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 1.75,
                  child: Text(
                    _pageComments[index].comment,
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              ],
            );
            //);
          })),
    );
  }

  // Collects User input and UPLOADS the comment.
  Widget commentBox() {
    return ListTile(
      title: TextField(
          style: const TextStyle(color: Colors.black),
          controller: _commentController,
          keyboardType: TextInputType.multiline,
          inputFormatters: [LengthLimitingTextInputFormatter(50)],
          maxLines: null,
          decoration: InputDecoration(
            hintText: "leave a comment!",
            filled: true,
            fillColor: Colors.white,
            border: const OutlineInputBorder(),
            labelStyle: const TextStyle(color: Colors.black),
            suffixIcon: IconButton(
              onPressed: () => _commentController.clear(),
              icon: const Icon(Icons.clear),
            ),
          )),
      // Button to post comment
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
        child: const Text("Comment"),
        onPressed: () async {
          if (_commentController.text.trim().isEmpty) {
            showAlertDialog(context, "Please leave a comment first!");
            return;
          }

          dynamic comment = {
            'user_id': supabase.auth.currentUser!.id,
            'post_id': widget.postID,
            'comment': _commentController.text.trim(),
          };

          // Upload to the recipe_ingredients table
          await supabase
              .from('comments')
              .insert(comment)
              .then((value) =>
                  // Disappearing diaglog
                  showDialog(
                      context: context,
                      builder: (context) {
                        Future.delayed(const Duration(seconds: 1), () {
                          Navigator.of(context).pop(true);
                        });
                        return const AlertDialog(
                          title: Center(
                            child: Text(
                              'Posted!',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          backgroundColor: primaryGray,
                        );
                      }))
              .then((value) => _commentController.clear())
              .then((value) =>
                  fetchFromDB()); // fetching from db reloads the pages.
        },
      ),
    );
  }

  showAlertDialog(BuildContext context, String msg) {
    // set up the button
    Widget okButton = ElevatedButton(
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

  Widget pageDivider() {
    return const Divider(
      color: Colors.white,
      height: 60.0,
      thickness: 4,
      indent: 15,
      endIndent: 15,
    );
  }

  // Adjusts our global page number.
  Widget pageButtons() {
    return Row(
      children: [
        SizedBox(width: MediaQuery.of(context).size.width / 2.5), // spacer
        // Previous page button
        IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              if (_pageNumber == 1) {
                return;
              }
              _pageNumber -= 1;
              updatePage();
            });
          },
        ),
        const SizedBox(width: 30), // spacer
        // Next page button
        IconButton(
          icon: const Icon(
            Icons.arrow_forward,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              if (_pageNumber == _pageLimit) {
                return;
              }
              _pageNumber += 1;
              updatePage();
            });
          },
        ),
      ],
    );
  }

  // Handles logic to update the page of comments (Limit 10 per page)
  void updatePage() {
    setState(() {
      _pageComments = [];

      int pageOffset;
      if (_pageNumber == 1) {
        pageOffset = 0;
      } else {
        pageOffset = (10 * (_pageNumber - 1));
      }

      for (var i = 0; i < _commentsPerPage; i++) {
        if (pageOffset >= _allComments.length) {
          return;
        }

        _pageComments.add(_allComments[pageOffset]);
        pageOffset += 1;
      }
    });
  }

  commentOptions(owner, index) {
    List<Widget> options;

    return showDialog(
        context: context,
        builder: (parentContext) {
          return StatefulBuilder(
              builder: (context, setState) => Theme(
                  data: Theme.of(context)
                      .copyWith(dialogBackgroundColor: primaryGray),
                  child: SimpleDialog(
                      title: const Text(
                        "Options",
                        style: TextStyle(color: Colors.white),
                      ),
                      children: <Widget>[
                        SimpleDialogOption(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => OtherProfileWidget(
                                        _pageComments[index].userID)));
                          },
                          child: const Text("View Profile",
                              style: TextStyle(color: Colors.white)),
                        ),
                        // The delete field is only visible for the post / comment owner.
                        Visibility(
                          visible: (supabase.auth.currentUser!.id == owner ||
                                  supabase.auth.currentUser!.id ==
                                      widget.postOwnerID)
                              ? true
                              : false,
                          child: SimpleDialogOption(
                            onPressed: () async {
                              confirmDeletePopup(context).then((value) =>
                                  startDelete(context, index)
                                      .then((value) =>
                                          Navigator.of(context).pop())
                                      .then((value) => fetchFromDB()));
                            },
                            child: const Text("Delete",
                                style: TextStyle(color: Colors.red)),
                          ),
                        ),
                        SimpleDialogOption(
                          child: const Text("Cancel",
                              style: TextStyle(color: Colors.white)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ])));
        });
  }

  Future<void> startDelete(context, index) async {
    // Check if user confirmed they want to upload Recipe
    if (!_requestDelete) {
      return;
    }
    await supabase.from('comments').delete().eq('id', _pageComments[index].id);
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
                content: const Text("Delete Comment?",
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
                        Navigator.of(context).pop(); // pops the page
                      })
                ],
              ),
            ),
          );
        });
  }
}

// Comment class constructed w/ the Data pulled from the DB.
// This class expects a nested Json.
// Expected Json Example:
// {
//   id: 1,
//   user_id: bbe4d1ea-1c59-4a2a-bcce-8ebe0884ae50,
//   post_id: 126,
//   comment: Freedom,
//   userinfo:{
//       username: Eren Yaeger ,
//       profile_picture: null
//   }
// }

class Comment {
  final int id;
  final String userID;
  final int postID;
  final String comment;

  final CommentOwner commentOwner;

  const Comment({
    required this.id,
    required this.userID,
    required this.postID,
    required this.comment,
    required this.commentOwner,
  });

// Parse from json:
  factory Comment.fromJson(Map<String, dynamic> json) {
    CommentOwner owner = CommentOwner.fromJson(json['userinfo']);
    return Comment(
        id: json['id'] as int,
        userID: json['user_id'] as String,
        postID: json['post_id'] as int,
        comment: json['comment'] as String,
        commentOwner: json['userinfo'] = owner);
  }
}

// Owner details to be parsed from the nested JSON
class CommentOwner {
  final String username;
  final String? profilePicture;

  const CommentOwner({required this.username, required this.profilePicture});

  factory CommentOwner.fromJson(Map<String, dynamic> json) {
    return CommentOwner(
        username: json['username'] as String,
        profilePicture: json['profile_picture'] as String?);
  }
}
