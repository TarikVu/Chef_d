import 'package:chefd_app/home.dart';
import 'package:chefd_app/models/comment_section.dart';
import 'package:chefd_app/models/other_profile.dart';
import 'package:chefd_app/models/profilepost.dart';
import 'package:chefd_app/models/userInfo.dart';
import 'package:chefd_app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:chefd_app/theme/colors.dart';
import 'package:flutter/services.dart';

// This class represents what a user's post would look like
class PostDetails extends StatefulWidget {
  PostDetails(this.post, {super.key});

  // Usable in _PostDetailsState by calling widget.post
  ProfilePost post;

  @override
  State<PostDetails> createState() => _PostDetailsState();
}

class _PostDetailsState extends State<PostDetails> {
  final TextEditingController _commentController = TextEditingController();

  // Information of the owner.
  final String defaultProfilePicture =
      "https://zwokvovrkprpsdjozoqa.supabase.co/storage/v1/object/public/misc/blank-profile-picture.png";

  UserInfo? _ownerInfo;
  String? _ownerPicture = "";
  String _ownerName = "";

  @override
  void initState() {
    super.initState();

    // Db Query:
    Future.delayed(Duration.zero, () {
      fetchFromDB();
    });
  }

  Future<void> fetchFromDB() async {
    // Post owner info
    final ownerInfoData = await supabase
        .from(userInfo)
        .select('*')
        .eq('user_id', widget.post.userId);

    if (!mounted) return;
    setState(() {
      // Set Owner's info
      List<dynamic>? infoAsList = ownerInfoData;
      _ownerInfo = UserInfo.fromJson(infoAsList![0]);
      _ownerName = _ownerInfo!.username;
      _ownerPicture = _ownerInfo?.profilePicture;
    });
  }

  // Rough template of what a user's post looks like
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: primaryOrange,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(15),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 20.0),

                // Main photo
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Image.network(
                    widget.post.picture,
                    fit: BoxFit.contain,
                    width: 500,
                    height: 500,
                  ),
                ),

                // Post Owner Details
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: primaryOrange,
                          shape: BoxShape.circle,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(44 / 2),
                          child: Image.network(
                              // The Owner's Profile picture
                              _ownerPicture ?? defaultProfilePicture,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                            return const Text("");
                          }),
                        ),
                      ),
                    ),
                    // The Owner's username
                    Text(
                      _ownerName,
                      style: const TextStyle(
                        color: white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                // Title and Description
                ListTile(
                  title: Text(widget.post.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white70)),
                  subtitle: Text(widget.post.body,
                      style: const TextStyle(
                          letterSpacing: 1, color: Colors.white)),
                ),
                const SizedBox(height: 10),
                const Divider(
                  color: Colors.white,
                  height: 10.0,
                  thickness: 2.0,
                ),
                const SizedBox(height: 20),
                // Comment Section & Comment button

                Row(children: [
                  IconButton(
                    onPressed: () {
                      postOptions(_ownerInfo!.userId);
                    },
                    icon: const Icon(
                      Icons.more_horiz,
                      color: secondaryOrange,
                    ),
                  ),
                  IconButton(
                      icon: const Icon(Icons.chat_bubble),
                      color: secondaryOrange,
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CommentsSection(
                                    widget.post.id, widget.post.userId)));
                        setState(() {
                          // refresh
                        });
                      }),

                  // Sized box to push Elevated button to size on this row.
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 2,
                  ),
                ]),
              ]),
        ),
      ),
    );
  }

  postOptions(owner) {
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
                                    builder: (context) =>
                                        OtherProfileWidget(owner)));
                          },
                          child: const Text("View Profile",
                              style: TextStyle(color: Colors.white)),
                        ),
                        // The delete field is only visible for the post / comment owner.
                        Visibility(
                          visible: (supabase.auth.currentUser!.id == owner)
                              ? true
                              : false,
                          child: SimpleDialogOption(
                            onPressed: () async {
                              confirmDeletePopup(context).then((value) =>
                                  startDelete(context)
                                      .then((value) =>
                                          Navigator.of(context).pop())
                                      .then((value) => _requestDelete
                                          ? Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const HomeWidget()))
                                          : null));
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
                content: const Text("Delete Post?",
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
  Future<void> startDelete(context) async {
    if (!_requestDelete) {
      return;
    }
    await supabase.from('posts').delete().eq('id', widget.post.id);
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
}

Widget pageDivider() {
  return const Column(children: [
    SizedBox(height: 10),
    Divider(
      color: Colors.white,
      height: 60.0,
      thickness: 4,
      indent: 15,
      endIndent: 15,
    ),
    SizedBox(height: 10),
  ]);
}

class Comment {
  String userID;
  String userName;
  String userPhoto;
  String comment;

  Comment(this.userID, this.userName, this.userPhoto, this.comment);
}
