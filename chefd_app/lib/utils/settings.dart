import 'dart:io';
import 'package:chefd_app/additional_info.dart';
import 'package:chefd_app/login.dart';
import 'package:chefd_app/main.dart';
import 'package:chefd_app/models/image_helper.dart';
import 'package:chefd_app/models/userInfo.dart';
import 'package:chefd_app/theme/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// The settings page where our user is able to adjust their information
// This was a referenced template.
// Ref: https://www.fluttertemplates.dev/widgets/must_haves/settings_page
class SettingsWidget extends StatefulWidget {
  const SettingsWidget({Key? key}) : super(key: key);

  // Int userId

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  // user info
  final _userId = supabase.auth.currentUser!.id;
  String? _profilePicture = "";
  String _userName = "";
  UserInfo? _userInfo;

  // Image
  File? _selectedImg;
  final _imageHelper = ImageHelper();

  final String _defaultProfilePicture =
      "https://zwokvovrkprpsdjozoqa.supabase.co/storage/v1/object/public/misc/blank-profile-picture.png";

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      fetchFromDB();
    });
  }

  Future<void> fetchFromDB() async {
    // Fetch User's data
    // User info
    final userInfoData =
        await supabase.from('userinfo').select('*').eq('user_id', _userId);
    // Set User's info
    List<dynamic>? infoAsList = userInfoData;
    _userInfo = UserInfo.fromJson(infoAsList![0]);

    if (!mounted) return;
    setState(() {
      _userName = _userInfo!.username;
      _profilePicture = _userInfo?.profilePicture;

      // No profile picture URL in table, set to default
      _profilePicture ??= _defaultProfilePicture;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryOrange,
          title: const Text("Settings"),
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: ListView(
              children: [
                const SizedBox(height: 30.0),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: primaryOrange,
                        shape: BoxShape.circle,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child:
                            Image.network(_profilePicture!, fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                          return const Text("");
                        }),
                      ),
                    ),
                  ),
                ),
                _SingleSection(
                  title: "Profile Options",
                  children: [
                    _CustomListTile(
                      title: "Change Profile Picture",
                      icon: Icons.photo_size_select_large_outlined,
                      onTap: () async {
                        await selectImage(context).then((value) => uploadPic());
                      },
                    ),
                    _CustomListTile(
                      title: "Remove Profile Picture",
                      icon: Icons.cancel,
                      onTap: () async {
                        await delProfilePic(context);
                      },
                    ),
                    _CustomListTile(
                      title: "Dietary & Allergen Restrictions",
                      icon: Icons.food_bank_rounded,
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const AdditionalInfoWidget()));
                      },
                    ),
                  ],
                ),
                const Divider(),

                // This would be a good place to add a link to our main website.

                _SingleSection(
                  children: [
                    _CustomListTile(
                      title: "About",
                      icon: Icons.info_outline_rounded,
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AboutWidget()));
                      },
                    ),
                  ],
                ),

                _SingleSection(
                  children: [
                    _CustomListTile(
                      title: "Sign out",
                      icon: Icons.exit_to_app_rounded,
                      onTap: () async {
                        // *** NOTE ** attempting to clear the nav stack
                        // by popping before redirecting to the login page
                        // would cause unexpected "anonymous closures"
                        // For now we will just push the login page,
                        // Either way when calling supabase.auth.signout
                        // The user will be logged out in the back end.

                        // while (Navigator.of(context).canPop()) {
                        //   Navigator.of(context).pop();
                        // }

                        // // pops last page on navigator stack (Should be home context)
                        //Navigator.of(context).pop(); // Pops Home Context

                        // Signs the user out then pushes
                        // The login page on the nav stack.
                        await supabase.auth.signOut().then((value) =>
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const LoginWidget())));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> selectImage(parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: const Text("Image selection"),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () => {pickImageFromCamera()},
                child: const Text("Photo with Camera"),
              ),
              SimpleDialogOption(
                onPressed: () => {pickImageFromGallery()},
                child: const Text("Image from Gallery"),
              ),
              SimpleDialogOption(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }

  // Utilizes ImageHelper to Select from Gallery & crop.
  Future pickImageFromGallery() async {
    final file = await _imageHelper.pickImageFromGallery();
    final croppedFile = await _imageHelper.crop(file: file);
    if (croppedFile != null) {
      setState(() {
        _selectedImg = File(croppedFile.path);
        Navigator.of(context, rootNavigator: true).pop();
      });
    }
  }

  // Utilizes ImageHelper to Select from Camera & crop.
  Future pickImageFromCamera() async {
    final file = await _imageHelper.pickImageFromCamera();
    final croppedFile = await _imageHelper.crop(file: file);
    if (croppedFile != null) {
      setState(() {
        _selectedImg = File(croppedFile.path);
        Navigator.of(context, rootNavigator: true).pop();
      });
    }
  }

  // Uploads and upserts (overtakes) old profile picture.
  Future<void> uploadPic() async {
    try {
      // Upload for current user
      final userId = supabase.auth.currentUser!.id;

      // These two lines will save the image under storage->pictures->userId->filename
      final imgName = _selectedImg!.path.split('/').last;
      final imagePath = '/$userId/$imgName';

      // Saves as a .jpg file.
      final imageExtension = _selectedImg!.path.split('.').last.toLowerCase();

      // Holds returned image URL from supabase storge.  Is then inserted into posts table.
      String imageUrl;

      // Remove old profile picture from storage if it exists.
      if (_profilePicture != null) {
        List<String> imgSplit = _profilePicture!.split('/');

        await supabase.storage
            .from('UserProfilePictures')
            .remove(['$userId/${imgSplit.last}']);
      }

      // Upload new photo.
      supabase.storage.from('UserProfilePictures').upload(
          imagePath, _selectedImg!,
          fileOptions:
              FileOptions(contentType: 'image/$imageExtension', upsert: true));

      // pull back the url from storage to update the userinfo table.
      imageUrl =
          supabase.storage.from('UserProfilePictures').getPublicUrl(imagePath);

      // Finally update the profile photo in the userinfo table
      await supabase
          .from('userinfo')
          .update({'profile_picture': imageUrl}).eq('user_id', _userId);

      // updates the profile photo on the settings page.
      await fetchFromDB();

      // Notify the parent to refresh (only used for profile page)
    } catch (e) {
      print(e);
    }
    return;
  }

  delProfilePic(BuildContext context) async {
    final userId = supabase.auth.currentUser!.id;

    // Remove old profile picture from storage if it exists.
    if (_profilePicture != null) {
      List<String> imgSplit = _profilePicture!.split('/');

      await supabase.storage
          .from('UserProfilePictures')
          .remove(['$userId/${imgSplit.last}']);
    }

    await supabase
        .from('userinfo')
        .update({'profile_picture': null}).eq('user_id', _userId);

    await fetchFromDB();
  }
}

// Custom Class found on reference.
// Voidcallback on tap was added, odd that wasnt already there.
class _CustomListTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _CustomListTile(
      {Key? key,
      required this.title,
      required this.icon,
      this.trailing,
      this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      leading: Icon(icon),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _SingleSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  const _SingleSection({
    Key? key,
    this.title,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        Column(
          children: children,
        ),
      ],
    );
  }
}

class AboutWidget extends StatelessWidget {
  const AboutWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("About Chef'd"),
          backgroundColor: primaryOrange,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                child: Image.network(
                  "https://zwokvovrkprpsdjozoqa.supabase.co/storage/v1/object/public/misc/dev_team.jpg",
                  fit: BoxFit.fill,
                ),
              ),
              divider(),
              ListTile(
                title: const Text("Abstract",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white70)),
                subtitle: Text(_abstract,
                    style:
                        const TextStyle(letterSpacing: 1, color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget divider() {
    return Column(
      children: [
        const SizedBox(
          height: 10,
        ),
        Divider(
          color: Colors.grey[800],
          height: 50,
        ),
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }

  final String _abstract =
      "Cooking is the one skill that everyone can (and should) use three times a day for the rest of their lives. "
      "With it being such a prominent part of our everyday lives, why is it that only 36% of Americans reported cooking on a daily basis? "
      "(Food Market Outlook 2022 - 2026) Many individuals, families, and friends enjoy the experience of going out to eat at their favorite "
      "restaurants and food destinations. The variety of food is absolutely delicious and being serviced while not having to do anything is the cherry on top. "
      "The problem arrives when the bill comes and takes out a chunk of money from your bank account. This, of course, starts to add up and simply is not"
      "financially sustainable when considering other life expenses. \nWe bring to you, Chef’d, a one-stop shop phone application for sharing, practicing, planning, "
      "and budgeting your meals. Users regardless of age and skill level will be able to pick out recipes for their comfortable skill levels, "
      "whilst being able to track and share their journey with others. A common problem with most people is that they always end up making the same "
      "recipes and this reason in particular results in going out to eat at restaurants because of lack of variety and simply boredom with eating the same "
      "food over and over. Users are able to discover new recipes and expand their cooking repertoire. Not only will the user have a vast amount of personalized "
      "and recommended recipes from all over the world to choose from, but they will have the ability to purchase and check out groceries within the app, which "
      "can then be delivered to their homes or available for in-store pickup.\nWithin Chef’d, users are able to create their own profile that keeps track of recipes "
      "used as well as recipes that they have created. They are then able to post those recipes for other users to see. This way potential stars or "
      "up-and-coming chefs have the opportunity to build a following on the platform and potentially gain celebrity status.";
}
