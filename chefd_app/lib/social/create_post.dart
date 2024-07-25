import 'package:chefd_app/home_layout.dart';
import 'package:chefd_app/utils/image_helper.dart';
import 'package:chefd_app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:chefd_app/theme/colors.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

// Our Post Creation page.
// Ref: https://www.youtube.com/watch?v=v9g0mxTNbKQ
class CreatePost extends StatefulWidget {
  const CreatePost({super.key});

  @override
  State<CreatePost> createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  // Global Variables:
  File? _selectedImg;
  final _imageHelper = ImageHelper();

  // Grab user inputs.
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  // Used for finalizeUpload method.
  bool _uploaded = false;

  @override
  Widget build(BuildContext context) {
    return buildScreen();
  }

  // Main post creation screen:
  Widget buildScreen() {
    return MaterialApp(
      theme: ThemeData(scaffoldBackgroundColor: primaryOrange),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Back"),
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Container(
            padding: const EdgeInsets.all(10),
            color: primaryOrange,
            child: SingleChildScrollView(
                // Logo
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                  Image.asset(
                    'assets/logo.jpg',
                    height: 80.0,
                  ),
                  const Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: DefaultTextStyle(
                          style: TextStyle(color: white, fontSize: 30.0),
                          child: Text("Create a Post!"))), // Description box
                  // Title
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Material(
                        child: TextFormField(
                      controller:
                          _titleController, // hook up controller to get user input
                      keyboardType: TextInputType.multiline,
                      inputFormatters: [LengthLimitingTextInputFormatter(15)],
                      maxLines: null,
                      decoration: InputDecoration(
                          hintText: "Title your post!",
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                _titleController.clear(), // clear Desc
                            icon: const Icon(Icons.clear),
                          )),
                    )),
                  ),
                  // Description
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Material(
                        child: TextFormField(
                      controller:
                          _bodyController, // hook up controller to get user input
                      keyboardType: TextInputType.multiline,
                      inputFormatters: [LengthLimitingTextInputFormatter(200)],
                      maxLines: 10,
                      decoration: InputDecoration(
                          hintText: "Tell us about your post!",
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                _bodyController.clear(), // clear Desc
                            icon: const Icon(Icons.clear),
                          )),
                    )),
                  ),
                  // Where the Image goes.
                  const SizedBox(height: 20),
                  _selectedImg != null
                      ? Image.file(_selectedImg!)
                      : const DefaultTextStyle(
                          style: TextStyle(color: Colors.white, fontSize: 12),
                          child: Text("Please select an image")),
                  // Upload button
                  Padding(
                    padding: const EdgeInsets.only(top: 1.0),
                    child: ElevatedButton(
                      onPressed: () => selectImage(context),
                      child: const Text(
                        "Upload Image",
                        style: TextStyle(color: Colors.white, fontSize: 22.0),
                      ),
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Cancel Button
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 22.0),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(10),
                          ),
                          // Post Button
                          ElevatedButton(
                            onPressed: () async {
                              await uploadPost()
                                  .then((value) => finishUploadPost(context));
                            }, // Upload to DB. ref https://www.youtube.com/watch?v=SZ09mPSNu4k
                            child: const Text(
                              "Post",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 22.0),
                            ),
                          ),
                        ],
                      )),
                ]))),
      ),
    );
  }

  // Closes Creatpost screen, and reports a dialog.
  Future<void> finishUploadPost(context) async {
    if (_uploaded) {
      _uploaded = false;
      Navigator.of(context).pop();
      showDialog(
          context: context,
          builder: (context) {
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.of(context).pop(true);
            });
            return const AlertDialog(
              title: Text('Posted!'),
            );
          });

      return;
    } else {
      return;
    }
  }

  // Upload the Post to the db.
  Future<void> uploadPost() async {
    // Required fields.
    if (_titleController.text == "") {
      showAlertDialog(context, "Please enter a title.");
      return;
    }
    if (_bodyController.text == "") {
      showAlertDialog(context, "Please enter a description.");
      return;
    }
    if (_selectedImg == null) {
      showAlertDialog(context, "Please select an image.");
      return;
    }

    // Upload for current user
    final userId = supabase.auth.currentUser!.id;

    // These two lines will save the image under storage->pictures->userId->filename
    final imgName = _selectedImg!.path.split('/').last;
    final imagePath = '/$userId/$imgName';

    // Saves as a .jpg file.
    final imageExtension = _selectedImg!.path.split('.').last.toLowerCase();

    // Holds returned image URL from supabase storge.  Is then inserted into posts table.
    String imageUrl;

    try {
      // upload photo to storage
      supabase.storage.from('pictures').upload(imagePath, _selectedImg!,
          fileOptions: FileOptions(contentType: 'image/$imageExtension'));

      // pull back the url from storage to insert into the posts table.
      imageUrl = supabase.storage.from('pictures').getPublicUrl(imagePath);

      // Finally insert into the posts table.
      await supabase.from(posts).insert({
        'user_id': userId,
        'title': _titleController.text,
        'body': _bodyController.text,
        'picture': imageUrl,
      });
      _uploaded = true;
    } catch (e) {
      print(e);
    }

    return;
  }

  // Simple alert dialogs prompting to enter fields.
  // ref: https://stackoverflow.com/questions/53844052/how-to-make-an-alertdialog-in-flutter
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

  // Popup screen for selecting an image after pressing the elevated button
  // ref https://www.youtube.com/watch?v=vwSY5Q-mVMs
  selectImage(parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setState) => Theme(
                    data: Theme.of(context)
                        .copyWith(dialogBackgroundColor: primaryGray),
                    child: SimpleDialog(
                      title: const Text("Image selection",
                          style: TextStyle(color: Colors.white)),
                      children: <Widget>[
                        SimpleDialogOption(
                          onPressed: () => {pickImageFromCamera()},
                          child: const Text("Photo with Camera",
                              style: TextStyle(color: Colors.white)),
                        ),
                        SimpleDialogOption(
                          onPressed: () => {pickImageFromGallery()},
                          child: const Text(
                            "Image from Gallery",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        SimpleDialogOption(
                          child: const Text("Cancel",
                              style: TextStyle(color: Colors.white)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ));
        });
  }
}
