import 'dart:io';

import 'package:chefd_app/models/RecipeModel.dart';
import 'package:chefd_app/models/image_helper.dart';
import 'package:chefd_app/theme/colors.dart';
import 'package:chefd_app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateReviewWidget extends StatefulWidget {
  const CreateReviewWidget({super.key});

  @override
  State<CreateReviewWidget> createState() => _CreateReviewState();
}

class _CreateReviewState extends State<CreateReviewWidget> {
  File? _selectedImg;
  final _imageHelper = ImageHelper();
  final reviewInputController = TextEditingController();
  double rating = 0.0;
  Recipe? r;

  @override
  Widget build(BuildContext context) {
    setState(() {
      r = ModalRoute.of(context)!.settings.arguments as Recipe;
    });
    return Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: const Text('Create Review'),
          centerTitle: true,
          backgroundColor: primaryOrange,
          elevation: 0.0,
        ),
        resizeToAvoidBottomInset: false,
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(basePadding),
                child: RatingBar.builder(
                  initialRating: 0,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  maxRating: 5,
                  updateOnDrag: true,
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (value) => rating = value,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(basePadding / 2),
                child: TextLabel("Please share your thoughts below:",
                    primaryOrange, 14, true),
              ),
              Padding(
                padding: const EdgeInsets.all(basePadding / 2),
                child: TextField(
                    controller: reviewInputController,
                    maxLines: null,
                    style: const TextStyle(color: white)),
              ),
              _selectedImg != null
                  ? Padding(
                      padding: const EdgeInsets.all(basePadding / 2),
                      child: Image.file(
                        _selectedImg!,
                        width: 200,
                        height: 200,
                      ))
                  : Padding(
                      padding: const EdgeInsets.all(basePadding / 2),
                      child: ElevatedButton(
                        onPressed: () async {
                          selectImage(context);
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(1),
                          child: Text('Add an Image'),
                        ),
                      ),
                    ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(basePadding / 2),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await insertRecipeReviewToDB(
                            reviewInputController.text, r!.title);
                        await updateReviewScore(r!.id);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.done),
                      label: const Text('Submit'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(basePadding / 2),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          rating = 0.0;
                        });
                      },
                      icon: const Icon(Icons.cancel_rounded),
                      label: const Text('Cancel'),
                    ),
                  )
                ],
              )
            ],
          ),
        ));
  }

  void createReview() {
    //double rating = 0.0;
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("What do you think about this recipe?"),
              content: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RatingBar.builder(
                    initialRating: 0,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    maxRating: 5,
                    updateOnDrag: true,
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (value) => rating = value,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(basePadding / 2),
                    child: TextLabel("Please share your thoughts below:",
                        primaryOrange, 14, true),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(basePadding / 2),
                    child: TextField(
                      controller: reviewInputController,
                    ),
                  ),
                  // _selectedImg != null
                  //     ? Image.file(_selectedImg!)
                  //     : const DefaultTextStyle(
                  //         style: TextStyle(color: Colors.white, fontSize: 12),
                  //         child: Text("Please select an image")),
                  _selectedImg != null
                      ? Image.file(_selectedImg!)
                      : Padding(
                          padding: const EdgeInsets.all(basePadding / 2),
                          child: ElevatedButton(
                            onPressed: () async {
                              selectImage(context);
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(1),
                              child: Text('Add an Image'),
                            ),
                          ),
                        )
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    await insertRecipeReviewToDB(
                        reviewInputController.text, r!.title);
                    await updateReviewScore(r!.id);
                    Navigator.pop(context);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(1),
                    child: Text('Submit'),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    reviewInputController.text = "";
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(1),
                    child: Text('Cancel'),
                  ),
                ),
              ],
            ));
  }

  Future<void> insertRecipeReviewToDB(
    String body,
    String title,
  ) async {
    // Holds returned image URL from supabase storge.  Is then inserted into posts table.
    String imageUrl = "";

    // These two lines will save the image under storage->pictures->userId->filename
    if (_selectedImg == null) {
    } else {
      final imgName = _selectedImg!.path.split('/').last;
      final imagePath = '/$userId/$imgName';

      // Saves as a .jpg file.
      final imageExtension = _selectedImg!.path.split('.').last.toLowerCase();

      //String imageUrl = "";

      try {
        // upload photo to storage
        supabase.storage.from('pictures').upload(imagePath, _selectedImg!,
            fileOptions: FileOptions(contentType: 'image/$imageExtension'));

        // pull back the url from storage to insert into the posts table.
        imageUrl = supabase.storage.from('pictures').getPublicUrl(imagePath);
      } catch (e) {}
    }

    try {
      await supabase
          .from(recipeReviews)
          .select()
          .eq('recipe_id', r!.id)
          .eq('user_id', user!.id)
          .eq('title', title)
          .single();

      //Update if review already exists.
      await supabase
          .from(recipeReviews)
          .update({'body': body, 'rating': rating, 'picture': imageUrl})
          .eq('recipe_id', r!.id)
          .eq('user_id', user!.id)
          .eq('title', title);
    } catch (e) {
      await supabase.from(recipeReviews).insert({
        'recipe_id': r!.id,
        'user_id': user!.id,
        'body': body,
        'title': title,
        'rating': rating,
        'picture': imageUrl
      });
    }
    reviewInputController.text = "";
  }

  Future<void> updateReviewScore(int recipeId) async {
    double sum = 0.0;
    int count = 0;
    final reviewResponse = await supabase
        .from(recipeReviews)
        .select('rating')
        .eq('recipe_id', recipeId);

    for (var r in reviewResponse) {
      sum += r['rating'];
      count += 1;
    }
    if (count != 0) {
      sum /= count;
    }
    try {
      await supabase.from(recipes).update({'rating': sum}).eq('id', recipeId);
    } catch (e) {
      print(e);
    }
  }

  // Method that brings up popup to choose between phone camera or photo album
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
}
