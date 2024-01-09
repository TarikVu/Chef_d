import 'package:chefd_app/models/allergen_diet.dart';
import 'package:chefd_app/models/tag.dart';
import 'package:chefd_app/models/image_helper.dart';
import 'package:chefd_app/utils/suggestions.dart';
import 'package:chefd_app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:chefd_app/theme/colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

// References for this class. - Tarik Vu
// Nested List Views: https://www.youtube.com/watch?v=TKgj_1Iv55M&fbclid=IwAR1cFErOsig_6L84_r6wpHG9bpCwGaH6UxmljOe3UnfP2a-FA0EwkhPr-Ws
// Dynamic textfields for Ingredients: https://www.technicalfeeder.com/2021/09/flutter-add-textfield-dynamically/#toc4
// Alert dialogs:  https://stackoverflow.com/questions/53844052/how-to-make-an-alertdialog-in-flutter
// TypeAheadField: ChatGPT
// Reoderable list view: https://github.com/JohannesMilke/reorderable_listview_example/blob/master/lib/page/home_page.dart#L1
// This class Creates and uploads a recipe to Supabase.

class CreateRecipe extends StatefulWidget {
  const CreateRecipe({super.key});

  @override
  State<CreateRecipe> createState() => _CreateRecipeState();
}

class _CreateRecipeState extends State<CreateRecipe> {
  // "Title and Desc" Globals
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // "Ingredients" Globals
  List<Ingr> _ingrs = [];
  final TextEditingController _ingrNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _customUnitController = TextEditingController();
  final TextEditingController _ingrDescController = TextEditingController();
  String _selectedUnit = "Units";
  bool _enableCustomUnits = false;
  // ignore: unused_field
  String _selectedIngr = '';

  // "Steps" Globals
  List<String> _steps = [];
  final TextEditingController _stepController = TextEditingController();

  // "Allergens" Globals
  List<dynamic> _allergensDiets = [];
  final Map<String, int> _allergenDietIDs = {};

  // List of Allergens, and a starting value
  final String _selectedAllergenDiet = 'Add Allergen or Diet';
  final List<DropdownMenuItem<String>> _allergenDietOptions = [
    const DropdownMenuItem(
        value: "Add Allergen or Diet", child: Text("Add Allergen or Diet"))
  ];

  // "Tags" Globals
  List<dynamic> _tags = [];
  final Map<String, int> _tagsIDs = {};

  // List of Tags and a starting value
  final String _selectedTag = 'Add Tag';
  final List<DropdownMenuItem<String>> _tagOptions = [
    const DropdownMenuItem(value: "Add Tag", child: Text("Add Tag"))
  ];

  // "Nutrition" Globals
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _cholesterolController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _sodiumController = TextEditingController();
  final TextEditingController _sugarController = TextEditingController();
  final TextEditingController _fiberController = TextEditingController();
  final TextEditingController _unsatFatController = TextEditingController();
  final TextEditingController _satFatController = TextEditingController();
  int _totalFats = 0;
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();

  // "Cook Time" Globals
  final _cookTimeController = TextEditingController(); // nullable
  final _prepTimeController = TextEditingController(); // nullable
  int _totalTime = 0;

  // "Recipe Photo" Globals
  File? _selectedImg;
  final _imageHelper = ImageHelper();

  // Upload logic
  bool _uploaded = false;
  bool _uploading = false; // used for circle indicator.
  bool _exitPage = false;
  bool _requestUpload = false;

  @override
  void initState() {
    super.initState();

    // prefillData();

    // Db Query:
    Future.delayed(Duration.zero, () {
      fetchFromDB();
    });
  }

  // Initialize Fields for testing: REMOVE ON RELASE! set fields back to "final" after
  prefillData() {
    _titleController.text = "Tarik's Curry";
    _descriptionController.text =
        ("This is a curry Recipe that I've been working on for a few years."
            "I originally got inspired from a Naruto episode when him and Rock Lee "
            "had to make curry to save the daughter of Ichiran ramen's owner.");

    _ingrs = [
      Ingr(null, "Beef", 3.0, "pound", ""),
      Ingr(null, "Curry powder", 2.5, "cup", ""),
      Ingr(null, "Onion", 1.0, "medium", "half chewed"),
      Ingr(null, "Olive Oil", 1.3, "teaspoon", "in shot glass"),
    ];
    _steps = [
      "Cut the beef up",
      "Cook beef in broth at a low temp until soft",
      "Add Curry Powder and stir until Dissolved",
      "Call mom",
      "Simmer and serve",
    ];
    _allergensDiets = [
      "Red Meat Allergy (Alpha-Gal)",
    ];

    _tags = ["Asian", "Dinner,Entree", "Dinner,Lunch"];

    _carbsController.text = "3";
    _cholesterolController.text = "999";
    _proteinController.text = "57";
    _sodiumController.text = "4";
    // Sugars and fibers not entered. Default to zero when uploading
    _unsatFatController.text = "88";
    _satFatController.text = "23";
    _totalFats = 111;
    _caloriesController.text = "2300";
    _servingsController.text = "2.5";

    _cookTimeController.text = "120";
    _prepTimeController.text = "30";
    _totalTime = 150;
  }

  // Cleanup Controllers to help prevent memory leakage.
  @override
  void dispose() {
    // Other Controllers
    _titleController.dispose();
    _stepController.dispose();
    _descriptionController.dispose();

    // Ingr Controllers
    _ingrNameController.dispose();
    _amountController.dispose();
    _customUnitController.dispose();

    // Nutrition Controllers
    _carbsController.dispose();
    _cholesterolController.dispose();
    _proteinController.dispose();
    _sodiumController.dispose();
    _sugarController.dispose();
    _fiberController.dispose();
    _unsatFatController.dispose();
    _satFatController.dispose();
    _caloriesController.dispose();
    _servingsController.dispose();

    // Cook Time Controllers
    _cookTimeController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  // Query needed info from db.
  // Here we fetch the current allergens listed in
  // our allergen table Limit 100.
  Future<void> fetchFromDB() async {
    // Fetch allergens
    final allergensDietsData = await supabase
        .from('allergies_diets')
        .select('*')
        .order('label', ascending: true);

    // Fetch Tags
    final tagsData =
        await supabase.from('tags').select('*').order('label', ascending: true);

    // Tell main widget we've found data from the DB.
    if (!mounted) return;
    setState(() {
      // parse the Json of Allergens
      List<dynamic>? allergensDietsAsList = allergensDietsData;
      for (var a in allergensDietsAsList!) {
        AllergenDiet ad = AllergenDiet.fromJson(a);
        // Store item and id to later upload
        _allergenDietIDs.putIfAbsent(ad.label, () => ad.id);

        // Put the allergen info into a dropdown menu Item.
        DropdownMenuItem<String> d = DropdownMenuItem(
          value: ad.label,
          child: Text(ad.label),
        );

        _allergenDietOptions.add(d);
      }
      // parse the Json of Tags
      List<dynamic>? tagsAsList = tagsData;
      for (var t in tagsAsList!) {
        Tag tag = Tag.fromJson(t);

        // store name of tag and id to later upload.
        _tagsIDs.putIfAbsent(tag.label, () => tag.id);

        // Put the tag info into a dropdown menu Item.
        DropdownMenuItem<String> d = DropdownMenuItem(
          value: tag.label,
          child: Text(tag.label),
        );

        _tagOptions.add(d);
      }
    });
  }

  // Main
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryOrange,
      appBar: AppBar(
        title: const Text("Back"),
        backgroundColor: primaryGray,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            await exitPopup(context).then((value) => confirmExit(context));
          },
        ),
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: primaryOrange,
        child: ListView(children: [
          // Logo & "My Recipe"
          Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
            Image.asset(
              'assets/logo.jpg',
              height: 80.0,
            ),
            const Text(
              "My Recipe",
              style: TextStyle(color: white, fontSize: 40),
            )
          ]),

          // Title Field ----------------------------------------------------
          titleView(),

          // Description field ----------------------------------------------
          const Text(
            "Description",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 25),
          ),
          const Text(
            "Required",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          pageDivider(),
          Container(
              height: 200,
              alignment: Alignment.center,
              color: primaryOrange,
              child: descriptionView()),

          // Ingredients ----------------------------------------------------
          const Padding(
            padding: EdgeInsets.all(30),
          ),
          const Text(
            "Ingredients",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 25),
          ),
          const Text(
            "Required",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          pageDivider(),

          Container(
            height: 320,
            alignment: Alignment.center,
            color: primaryOrange,
            //child: Expanded(

            child: _ingrs.isEmpty
                ? const Text(
                    "Add your ingredients here!",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  )
                : ingrListView(),
          ),

          const Padding(
            padding: EdgeInsets.all(10),
          ),
          Container(
            alignment: Alignment.center,
            child: addIngredientButton(),
          ),

          // Steps --------------------------------------------
          const Padding(
            padding: EdgeInsets.all(30),
          ),
          const Text(
            "Steps",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 25),
          ),
          const Text(
            "Required",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          const Text(
            "(Drag to reorder)",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          pageDivider(),

          const Padding(
            padding: EdgeInsets.all(10),
          ),
          Container(
            height: 275,
            alignment: Alignment.center,
            color: primaryOrange,
            // child: Expanded(
            child: _steps.isEmpty
                ? const Text(
                    "Add some Steps!",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  )
                : stepsListView(),
          ),
          //  ),
          const Padding(
            padding: EdgeInsets.all(10),
          ),
          Container(
            alignment: Alignment.center,
            child: addStepsButton(),
          ),

          // Allergens ---------------------------------------
          const Padding(
            padding: EdgeInsets.all(30),
          ),
          const Text(
            "Allergens & Diets",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 25),
          ),
          pageDivider(),

          Wrap(
            children: [
              // list view
              Container(
                height: 250,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                alignment: Alignment.center,
                color: primaryOrange,
                child: _allergensDiets.isEmpty
                    ? const Text(
                        "Add allergens & Diets here!",
                        style: TextStyle(color: Colors.white),
                      )
                    : allergensView(),
              ),

              // dropdown
              allergenDropdown(),
            ],
          ),

          // Tags -----------------------------------------
          const Padding(
            padding: EdgeInsets.all(30),
          ),
          const Text(
            "Tags",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 25),
          ),
          pageDivider(),

          Wrap(
            children: [
              // list view
              Container(
                height: 250,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                alignment: Alignment.center,
                color: primaryOrange,
                child: _tags.isEmpty
                    ? const Text(
                        "Add your tags!",
                        style: TextStyle(color: Colors.white),
                      )
                    : tagsView(),
              ),

              // dropdown
              tagsDropdown(),
            ],
          ),

          // Nutrition -----------------------------------------------------
          const Padding(
            padding: EdgeInsets.all(30),
          ),
          const Text(
            "Nutrition & Servings",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 25),
          ),
          const Text(
            "Defaults to zero unless specified*",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          pageDivider(),

          Container(
            height: 275,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.center,
            color: primaryOrange,
            child: nutritionView(),
          ),

          // Cooking Time --------------------------------------------------
          const Padding(
            padding: EdgeInsets.all(30),
          ),
          const Text(
            "Cook Time",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 25),
          ),
          const Text(
            "Defaults to zero unless specified*",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          pageDivider(),
          Container(
            height: 90,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.center,
            color: primaryOrange,
            child: cookTimeView(),
          ),

          // Photo----------------------------------------------
          const Padding(
            padding: EdgeInsets.all(30),
          ),
          const Text(
            "Recipe Photo",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 25),
          ),
          const Text(
            "Required",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          pageDivider(),
          Container(
            height: 500,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.center,
            color: primaryOrange,
            child: photoView(),
          ),
          pageDivider(),

          // UPLOAD & CANCEL BUTTONS -------------------------------
          Wrap(alignment: WrapAlignment.center, spacing: 5, children: [
            ElevatedButton(
                onPressed: () async {
                  await exitPopup(context)
                      .then((value) => confirmExit(context));
                },
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () async {
                  //showUploadDialog(context);
                  await confirmUploadPopup(context)
                      .then((value) => startUpload(context))
                      .then((value) => closePage(context));
                },
                child: const Text("Continue"))
          ])
        ]),
      ),
    );
  }

  // The Main upload function.
  Future<void> startUpload(context) async {
    // Check if user confirmed they want to upload Recipe
    if (!_requestUpload) {
      return;
    }

    // Check Required fields
    String missingFields = checkRequiredFields();
    if (missingFields != "") {
      showAlertDialog(
          context, "Please fill out the following:\n\n$missingFields");
      _uploading = false;
      return;
    }

    _uploading = true;
    showCircleIndicator();

    // More prep before uploading, see methods for further details.
    defaultOptionalFields();
    await prepareIngredients(); // UPLOADS NEW INGRS.

    // Commence Uploading
    final userId = supabase.auth.currentUser!.id;

    // Set up Username for upload
    final userNameData = await supabase
        .from('userinfo')
        .select("username")
        .eq("user_id", userId);

    // Parse Username from List<Map<String,Dynamic>> -> String
    List<Map<String, dynamic>> convertedList =
        List<Map<String, dynamic>>.from(userNameData);
    Map<String, dynamic> tempMap = convertedList[0];
    String username = tempMap["username"];

    // Set up photo data for upload
    // These two lines will save the image under storage->pictures->userId->filename
    final imgName = _selectedImg!.path.split('/').last;
    final imagePath = '/$userId/$imgName';

    // Saves as a .jpg file.
    final imageExtension = _selectedImg!.path.split('.').last.toLowerCase();

    // upload photo to storage
    await supabase.storage.from('pictures').upload(imagePath, _selectedImg!,
        fileOptions: FileOptions(contentType: 'image/$imageExtension'));

    // pull back the url from storage to insert into the posts table.
    String imageUrl = supabase.storage.from('pictures').getPublicUrl(imagePath);

    // UPLOAD
    try {
      // Upload to "recipes" table ----------------
      final List<Map<String, dynamic>> uploadedRecipe =
          await supabase.from("recipes").insert({
        'title': _titleController.text,
        'image': imageUrl,
        'difficulty': 1, // Defaulted to one
        'total_time': _totalTime,
        'source': 'chefd', // Defaulted to 'chefd'
        'rating': 0, // Defaulted to zero
        'popularity': 0, // Defaulted to zero
        'calories': _caloriesController.text,
        'servings': _servingsController.text,
        'author': username,
        'prep_time': _prepTimeController.text,
        'description': _descriptionController.text,
        'cook_time': _cookTimeController.text,
        'carbs': _carbsController.text,
        'cholesterol': _cholesterolController.text,
        'fiber': _fiberController.text,
        'protein': _proteinController.text,
        'saturated_fat': _satFatController.text,
        'sodium': _sodiumController.text,
        'sugar': _sugarController.text,
        'fat': _totalFats,
        'unsaturated_fat': _unsatFatController.text,
      }).select();

      // Parse out the Recipe ID.
      List<Map<String, dynamic>> convertedRecipe;
      convertedRecipe = List<Map<String, dynamic>>.from(uploadedRecipe);
      Map<String, dynamic> recipeMap = convertedRecipe[0];
      int recipeID = recipeMap["id"];

      // Upload to Recipe_Ingredients ---------------

      // Construct a dynamic list to upload multiple rows in one insertion call.
      List<dynamic> allIngrs = [];
      for (Ingr i in _ingrs) {
        dynamic d = {
          'recipe_id': recipeID.toString(),
          'ingredient_id': i.id.toString(),
          'amount': i.amnt.toString(),
          'unit': i.unit.toString(),
          'full_text': i.desc.toString()
        };
        allIngrs.add(d);
      }

      // Upload to the recipe_ingredients table
      await supabase.from('recipe_ingredients').insert(allIngrs);

      // Upload Steps -------------------
      List<dynamic> allSteps = [];
      for (var i = 0; i < _steps.length; i++) {
        dynamic s = {
          'recipe_id': recipeID.toString(),
          'step_number': i + 1, // step number corresponds to List index +1
          'step': _steps[i],
        };
        allSteps.add(s);
      }
      await supabase.from('recipe_steps').insert(allSteps);

      // Upload Tags --------------------
      List<dynamic> allTags = [];
      for (var i = 0; i < _tags.length; i++) {
        dynamic t = {
          'recipe_id': recipeID,
          'tag_id': _tagsIDs[_tags[i]]
        }; // Get the id of the tag using it's name
        allTags.add(t);
      }
      await supabase.from('recipe_tags').insert(allTags);

      // Upload Allergens & Diets ------
      List<dynamic> allAllergenDiets = [];
      for (var i = 0; i < _allergensDiets.length; i++) {
        dynamic ad = {
          'recipe_id': recipeID,
          'allergy_diet_id': _allergenDietIDs[
              _allergensDiets[i]] // Get id of allergen using it's name
        };
        allAllergenDiets.add(ad);
      }
      await supabase.from('recipe_allergies_diets').insert(allAllergenDiets);

      setState(() {
        _uploaded = true;
        _uploading = false;
      });
    } catch (e) {
      print(e);
    }
  }

  // Closes the page and reports the upload after our upload method is called.
  Future<void> closePage(BuildContext context) async {
    if (_uploaded) {
      _uploaded = false;
      Navigator.of(context).pop(); // pops circle indicator
      Navigator.of(context).pop(); // pops page
      showDialog(
          context: context,
          builder: (context) {
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.of(context).pop(true); // pops "Recipe Uploaded" alert
            });
            // Display a dialog on the previous page that the upload was successful.
            return StatefulBuilder(
                builder: (context, setState) => Theme(
                    data: Theme.of(context)
                        .copyWith(dialogBackgroundColor: primaryOrange),
                    child: const AlertDialog(
                      title: Text(
                        'Recipe uploaded!',
                        style: TextStyle(color: Colors.white),
                      ),
                    )));
          });

      return;
    } else {
      return;
    }
  }

  // "Prepares" The ingredients for a lack of a better word.
  // Here we normalize the user's ingredients to lowercase and query against
  // the DB to see if we have the ingredient.  If not, we add to the DB.
  // After that initial check is done, we grab the Ingredient's ID.
  Future<void> prepareIngredients() async {
    for (final i in _ingrs) {
      int ingrID = 0;
      Map<String, dynamic> ingrResponse;

      // Normalize to lowercase
      i.name = i.name.toLowerCase();
      i.name.trim();

      // Check if name exists in Ingredients Table, else insert
      // Record IngrID in both cases.
      try {
        ingrResponse = await supabase
            .from(ingredients)
            .select()
            .eq('label', i.name)
            .single();
        ingrID = ingrResponse['id'];
      } catch (e) {
        ingrResponse = await supabase
            .from(ingredients)
            .insert({'label': i.name})
            .select('id')
            .single();
        ingrID = ingrResponse['id'];
      }

      // Set the Id
      i.id = ingrID;
    }
  }

  // Records whether or not user wants to request uploading their recipe.
  confirmUploadPopup(context) {
    return showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) => Theme(
              data: Theme.of(context)
                  .copyWith(dialogBackgroundColor: primaryGray),
              child: AlertDialog(
                content: const Text("Finish recipe creation?",
                    style: TextStyle(color: Colors.white)),
                actions: [
                  ElevatedButton(
                      child: const Text("No"),
                      onPressed: () {
                        _requestUpload = false;
                        Navigator.of(context).pop(); // pops the popup
                      }),
                  ElevatedButton(
                      child: const Text("Yes"),
                      onPressed: () {
                        _requestUpload = true;
                        Navigator.of(context).pop(); // pops the page
                      })
                ],
              ),
            ),
          );
        });
  }

  Widget titleView() {
    return Container(
      height: 100,
      alignment: Alignment.center,
      color: primaryOrange,
      child: TextField(
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black),
        controller: _titleController,
        keyboardType: TextInputType.multiline,
        inputFormatters: [LengthLimitingTextInputFormatter(20)],
        maxLines: null,
        decoration: InputDecoration(
          hintText: "My Title",
          filled: true,
          fillColor: Colors.white,
          border: const OutlineInputBorder(),
          labelStyle: const TextStyle(color: Colors.black),
          labelText: "Title (required)",
          suffixIcon: IconButton(
            onPressed: () => _titleController.clear(),
            icon: const Icon(Icons.clear),
          ),
        ),
      ),
    );
  }

  Widget descriptionView() {
    return TextField(
        style: const TextStyle(color: Colors.black),
        controller: _descriptionController,
        keyboardType: TextInputType.multiline,
        inputFormatters: [LengthLimitingTextInputFormatter(300)],
        maxLines: 10,
        decoration: InputDecoration(
          hintText: "Tell us about your dish!",
          filled: true,
          fillColor: Colors.white,
          border: const OutlineInputBorder(),
          labelStyle: const TextStyle(color: Colors.black),
          suffixIcon: IconButton(
            onPressed: () => _descriptionController.clear(),
            icon: const Icon(Icons.clear),
          ),
        ));
  }

  Widget ingrListView() {
    return ListView.builder(
      shrinkWrap: false,
      itemCount: _ingrs.length,
      itemBuilder: (context, index) {
        // The card of our Ingredient.
        return Card(
          color: sandWhite,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: ListTile(
              title: Center(
                child: Text(
                  "${_ingrs[index].name} (${_ingrs[index].amnt.toString()} ${_ingrs[index].unit})",
                  style: const TextStyle(color: Colors.black, fontSize: 15),
                ),
              ),

              // RHS Buttons
              trailing: SizedBox(
                width: 70,
                child: Row(
                  children: [
                    // Edit Ingr
                    IconButton(
                      onPressed: () async {
                        // Prepopulate controllers and fields
                        // before bringing up the window to edit
                        _ingrNameController.text = _ingrs[index].name;
                        _amountController.text = _ingrs[index].amnt.toString();

                        _ingrDescController.text = _ingrs[index].desc;

                        if (unitOptionsList.contains(_ingrs[index].unit)) {
                          _selectedUnit = _ingrs[index].unit;
                        } else {
                          _customUnitController.text = _ingrs[index].unit;
                          _enableCustomUnits = true;
                          _selectedUnit = "other";
                        }
                        final i = await addIngrPopup();

                        // If User hit cancel, no info was recorded,
                        //add nothing to the list of ingridients.
                        if (i?.amnt == 0.0) return;

                        // Set the new fields on the ingredient in the list.
                        setState(() {
                          _ingrs[index].name = i!.name;
                          _ingrs[index].amnt = i.amnt;
                          _ingrs[index].unit = i.unit;
                        });
                      },
                      icon: const Icon(Icons.edit, color: Colors.blue),
                    ),

                    // Remove Ingr
                    Expanded(
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _ingrs.removeAt(index);
                          });
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Calls a method that records an ingredient input by the user.
  // Added to our Ingr List.
  Widget addIngredientButton() {
    return ElevatedButton(
      onPressed: () async {
        final i = await addIngrPopup();
        setState(() {
          // User hit cancel, no info was recorded,
          if (i?.amnt == 0.0) return;
          // else add to List of Ingredients.
          _ingrs.add(i!);
        });
      },
      child: const Text("Add an ingredient"),
    );
  }

  // Provides a popup window to record a new ingredient.
  Future<Ingr?> addIngrPopup() => showDialog<Ingr>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => Theme(
            data: Theme.of(context)
                .copyWith(dialogBackgroundColor: primaryOrange),
            child: AlertDialog(
              title: Image.asset(
                'assets/logo.jpg',
                height: 80.0,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(20),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ingr Name Field
                    TypeAheadField(
                      textFieldConfiguration: TextFieldConfiguration(
                        controller: _ingrNameController,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          labelText: "Ingredient Name",
                        ),
                      ),
                      suggestionsCallback: (pattern) {
                        return ingrOptions.where(
                          (suggestion) => suggestion.toLowerCase().contains(
                                pattern.toLowerCase(),
                              ),
                        );
                      },
                      itemBuilder: (context, suggestion) {
                        return ListTile(
                          title: Text(suggestion),
                        );
                      },
                      onSuggestionSelected: (suggestion) {
                        setState(
                          () {
                            _ingrNameController.text = suggestion;
                            _selectedIngr = suggestion;
                          },
                        );
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.all(10),
                    ),

                    // Get Ingr Amount
                    TextField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^(\d+)?\.?\d{0,2}'), // Regex for Decimals
                        )
                      ],
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                        labelText: "Amount",
                      ),
                    ),
                    pageDivider(),

                    // Get Ingr Units
                    Flexible(
                      child: Wrap(
                        children: [
                          // Custom Units only availible if
                          // "other" was selected on unit dropdown.
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: _customUnitController,
                              enabled: _enableCustomUnits,
                              decoration: const InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(),
                                labelText: "Custom Unit",
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),

                          // Predetermined units DropDown
                          Container(
                            decoration:
                                const BoxDecoration(color: primaryOrange),
                            child: DropdownButton(
                              value: _selectedUnit,
                              menuMaxHeight: 200,
                              icon: const Icon(
                                  Icons.format_line_spacing_outlined),
                              style: const TextStyle(color: Colors.white),
                              underline:
                                  Container(height: 2, color: secondaryOrange),
                              dropdownColor: Colors.black,
                              items: unitOptions,
                              onChanged: (String? newValue) {
                                setState(
                                  () {
                                    _selectedUnit = newValue!;
                                    if (newValue == "other") {
                                      _enableCustomUnits = true;
                                    } else {
                                      _enableCustomUnits = false;
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    pageDivider(),
                    // Ingr Description Field
                    TextField(
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black),
                      controller: _ingrDescController,
                      keyboardType: TextInputType.multiline,
                      inputFormatters: [LengthLimitingTextInputFormatter(15)],
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: "finely diced",
                        filled: true,
                        fillColor: Colors.white,
                        border: const OutlineInputBorder(),
                        //labelStyle: const TextStyle(color: Colors.black),
                        labelText: "Description (optional)",
                        suffixIcon: IconButton(
                          onPressed: () => _ingrDescController.clear(),
                          icon: const Icon(Icons.clear),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Buttons in Ingr Window
              actions: [
                // Cancel Button
                ElevatedButton(
                  onPressed: () {
                    // Reset popup
                    _ingrNameController.clear();
                    _amountController.clear();
                    _customUnitController.clear();
                    _ingrDescController.clear();
                    _selectedUnit = "Units";
                    _enableCustomUnits = false;

                    // Returns an empty Ingr if canceled, handeled @parentcall
                    Navigator.of(context).pop(
                      Ingr(-1, "", 0, "", ""),
                    );
                    return;
                  },
                  child: const Text("Cancel"),
                ),

                // Submit Button
                ElevatedButton(
                  onPressed: () {
                    // Error Checking for ingr Input
                    if (_ingrNameController.text.isEmpty ||
                        _amountController.text.isEmpty ||
                        (_selectedUnit == 'Units' &&
                            _customUnitController.text.isEmpty)) {
                      showAlertDialog(
                          context, "Please fill out all required fields.");
                      return;
                    }

                    // Determine the if the unit is custom
                    String u = "";
                    if (_selectedUnit == "other") {
                      u = _customUnitController.text;
                    } else {
                      u = _selectedUnit;
                    }

                    // The Ingredient returned
                    Ingr i = Ingr(
                      null,
                      _ingrNameController.text,
                      double.parse(_amountController.text),
                      u,
                      _ingrDescController.text,
                    );

                    // Reset popup
                    _ingrNameController.clear();
                    _amountController.clear();
                    _customUnitController.clear();
                    _ingrDescController.clear();
                    _enableCustomUnits = false;
                    _selectedUnit = "Units";

                    // Pop The window and pass back the ingredient.
                    Navigator.of(context).pop(i);
                  },
                  child: const Text('Submit'),
                )
              ],
            ),
          ),
        ),
      );

  Widget stepsListView() {
    return ReorderableListView.builder(
      itemCount: _steps.length,
      onReorder: (oldIndex, newIndex) => setState(() {
        // Reorder logic
        final index = newIndex > oldIndex ? newIndex - 1 : newIndex;
        final step = _steps.removeAt(oldIndex);
        _steps.insert(index, step);
      }),
      itemBuilder: (context, index) {
        final step = _steps[index];
        return buildStep(index, step);
      },
    );
  }

  // Step information inside the tiles of stepsListView.
  Widget buildStep(int index, String step) => Container(
        decoration: const BoxDecoration(
            color: sandWhite,
            borderRadius: BorderRadius.all(Radius.circular(4))),
        margin: const EdgeInsets.all(4.0),
        key: ValueKey(step),
        child: ListTile(
          key: ValueKey(step),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Text(
            "Step ${index + 1}:",
            style: const TextStyle(color: Colors.black),
          ),
          title: Text(
            step,
            style: const TextStyle(color: Colors.black),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,

            // RHS buttons
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () async {
                  // Prepopulate edit window
                  _stepController.text = _steps[index];
                  final i = await addStepsPopup();
                  // user canceled editing.
                  if (i == null) return;
                  // Change step at index
                  setState(() {
                    _steps[index] = i;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => setState(
                  () => _steps.removeAt(index),
                ),
              ),
              const SizedBox(
                width: 5.0,
              )
            ],
          ),
        ),
      );

  // Add Steps Logic
  Widget addStepsButton() {
    return ElevatedButton(
        onPressed: () async {
          // Popup to add Ingr
          final i = await addStepsPopup();

          setState(
            () {
              //User hit cancel, no info was recorded,
              if (i!.isEmpty) return;

              // else add to List of Ingredients.
              _steps.add(i!);
            },
          );
        },
        child: const Text("Add a new step"));
  }

  // Provides a popup window to record a new step.
  // Returns a String for the step if entered, else returns null.
  Future<String?> addStepsPopup() => showDialog<String>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => Theme(
            data: Theme.of(context)
                .copyWith(dialogBackgroundColor: primaryOrange),
            child: AlertDialog(
              // Title
              title: const Text(
                "New Step",
                style: TextStyle(color: Colors.white, fontSize: 20),
                textAlign: TextAlign.center,
              ),

              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              content:
                  // Step Details Field
                  Builder(builder: (context) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: TextField(
                      style: const TextStyle(color: Colors.black),
                      controller: _stepController,
                      keyboardType: TextInputType.multiline,
                      inputFormatters: [LengthLimitingTextInputFormatter(300)],
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: "Details",
                        filled: true,
                        fillColor: Colors.white,
                        border: const OutlineInputBorder(),
                        labelStyle: const TextStyle(color: Colors.black),
                        labelText: "Step Details",
                        suffixIcon: IconButton(
                          onPressed: () => _stepController.clear(),
                          icon: const Icon(Icons.clear),
                        ),
                      )),
                );
              }),

              // Buttons in Step Window
              actions: [
                // Cancel
                ElevatedButton(
                    onPressed: () {
                      // Reset popup
                      _stepController.clear();

                      // Returns an empty Ingr if canceled
                      Navigator.of(context).pop();
                      return;
                    },
                    child: const Text("Cancel")),

                // Submit
                ElevatedButton(
                    // Set the fields for the ingredient.
                    onPressed: () {
                      // Error Checking for ingr Input
                      if (_stepController.text.isEmpty) {
                        showAlertDialog(context, "Please fill out the step!");
                        return;
                      }
                      // Clear controller, and return string.
                      String i = _stepController.text;
                      _stepController.clear();

                      // Pop The popup and pass back the ingredient.
                      Navigator.of(context).pop(i);
                    },
                    child: const Text('Submit'))
              ],
            ),
          ),
        ),
      );

  Widget allergensView() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _allergensDiets.length,
      itemBuilder: (context, index) {
        // The card of our Ingredient.
        return Card(
          color: sandWhite,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: ListTile(
                // Allergen Name
                title: SizedBox(
                  width: 80,
                  child: Center(
                    child: Text(
                      _allergensDiets[index],
                      style: const TextStyle(color: Colors.black, fontSize: 15),
                    ),
                  ),
                ),

                // RHS Buttons
                trailing: SizedBox(
                  width: 50,
                  child:
                      // Remove Ingr
                      IconButton(
                    onPressed: () {
                      setState(() {
                        _allergensDiets.removeAt(index);
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget allergenDropdown() {
    return Column(children: [
      const SizedBox(height: 80),
      DropdownButton(
        value: _selectedAllergenDiet,
        menuMaxHeight: 200,
        isExpanded: true,
        icon: const Icon(Icons.format_line_spacing_outlined),
        style: const TextStyle(color: Colors.white),
        dropdownColor: Colors.black,
        items: _allergenDietOptions,
        onChanged: (String? newValue) {
          setState(
            () {
              // skip adding default value / repeats.
              if (_allergensDiets.contains(newValue) ||
                  newValue == "Add Allergen or Diet") {
                return;
              }

              _allergensDiets.insert(0, newValue!);
            },
          );
        },
      ),
    ]);
  }

  Widget tagsView() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _tags.length,
      itemBuilder: (context, index) {
        // The card of our Ingredient.
        return Card(
          color: sandWhite,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: ListTile(
                // Tag Name
                title: SizedBox(
                  width: 80,
                  child: Center(
                    child: Text(
                      _tags[index],
                      style: const TextStyle(color: Colors.black, fontSize: 15),
                    ),
                  ),
                ),

                // RHS Buttons
                trailing: SizedBox(
                  width: 50,
                  child:
                      // Remove Ingr
                      IconButton(
                    onPressed: () {
                      setState(() {
                        _tags.removeAt(index);
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget tagsDropdown() {
    return Column(children: [
      const SizedBox(height: 80),
      DropdownButton(
        value: _selectedTag,
        menuMaxHeight: 200,
        isExpanded: true,
        icon: const Icon(Icons.format_line_spacing_outlined),
        style: const TextStyle(color: Colors.white),
        dropdownColor: Colors.black,
        items: _tagOptions,
        onChanged: (String? newValue) {
          setState(
            () {
              // skip adding default value / repeats.
              if (_tags.contains(newValue) || newValue == "Add Tag") {
                return;
              }

              _tags.insert(0, newValue!);
            },
          );
        },
      ),
    ]);
  }

  Widget nutritionView() {
    return Wrap(
      spacing: 5.0,
      children: [
        nutritionField("Carbs", _carbsController, "grams"),
        nutritionField("Cholesterol", _cholesterolController, "grams"),
        nutritionField("Protein", _proteinController, "grams"),
        nutritionField("Sodium", _sodiumController, "grams"),
        nutritionField("Sugar", _sugarController, "grams"),
        nutritionField("Fiber", _fiberController, "grams"),
        nutritionField("Unsat. Fats", _unsatFatController, "grams"),
        nutritionField("Sat. Fats", _satFatController, "grams"),

        // Total Fats
        Container(
          height: 65,
          width: MediaQuery.of(context).size.width / 4,
          alignment: Alignment.center,
          color: primaryOrange,
          child: Column(
            children: [
              const Text(
                "Total Fats: ",
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 10),
              Text(
                "${_totalFats.toString()} grams",
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ],
          ),
        ),
        nutritionField("Calories", _caloriesController, "cal"),
        nutritionField("Servings", _servingsController, "portions"),
      ],
    );
  }

  // Builds the fields for the Nurtrition section.
  Widget nutritionField(
      String nLabel, TextEditingController nController, String suffix) {
    return Container(
        height: 75,
        width: MediaQuery.of(context).size.width / 4,
        alignment: Alignment.center,
        color: primaryOrange,
        child: Column(children: [
          Text(
            nLabel,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          TextFormField(
            controller: nController,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),

            // Text input formatter Servings allow Decimals, else use regular
            // int formatters.
            inputFormatters: nLabel == "Servings"
                ? <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^(\d+)?\.?\d{0,2}'), // Regex for Decimals
                    )
                  ]
                : <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(5),
                    FilteringTextInputFormatter.digitsOnly
                  ],
            decoration: InputDecoration(
              isDense: true,
              suffixIcon: Text("$suffix  ",
                  style: const TextStyle(color: Colors.black)),
              suffixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              filled: true,
              fillColor: Colors.white,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              // Update the total Fats label when unsat/sat fats is updated
              if (nLabel == "Unsat. Fats" || nLabel == "Sat. Fats") {
                int? unFat = 0;
                int? satFat = 0;
                try {
                  if (_unsatFatController.text != "") {
                    unFat = int.tryParse(_unsatFatController.text);
                  }
                } catch (e) {
                  unFat = 0;
                }
                try {
                  if (_satFatController.text != "") {
                    satFat = int.tryParse(_satFatController.text);
                  }
                } catch (e) {
                  satFat = 0;
                }

                // Set the Total Fats label
                int totalFats = unFat! + satFat!;
                setState(() {
                  _totalFats = totalFats;
                });
              }
            },
          ),
        ]));
  }

  Widget cookTimeView() {
    //return Expanded(
    return Column(children: [
      //  Expanded(
      Row(
        children: [
          cooktimeField("Cook Time", _cookTimeController),
          cooktimeField("Prep Time", _prepTimeController),
          Container(
            height: 65,
            width: MediaQuery.of(context).size.width / 4,
            alignment: Alignment.center,
            color: primaryOrange,
            child: Column(
              children: [
                const Text(
                  "Total Time: ",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 5),
                Text(
                  "${_totalTime.toString()} minutes",
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
      //   ),
    ]);
    //);
  }

  // Builds the fields for the cooktime Section.
  Widget cooktimeField(String ctLabel, TextEditingController ctController) {
    return Container(
        height: 85,
        width: MediaQuery.of(context).size.width / 4,
        alignment: Alignment.center,
        color: primaryOrange,
        child: Column(children: [
          Text(
            ctLabel,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          TextFormField(
            controller: ctController,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),

            // Text input formatter Servings allow Decimals, else use regular
            // int formatters.
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(5),
              FilteringTextInputFormatter.digitsOnly
            ],
            decoration: const InputDecoration(
              isDense: true,
              suffixIcon:
                  Text("minutes  ", style: TextStyle(color: Colors.black)),
              suffixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              // Update the total time Label
              int? ctime = 0;
              int? ptime = 0;
              try {
                if (_cookTimeController.text != "") {
                  ctime = int.tryParse(_cookTimeController.text);
                }
              } catch (e) {
                ctime = 0;
              }
              try {
                if (_prepTimeController.text != "") {
                  ptime = int.tryParse(_prepTimeController.text);
                }
              } catch (e) {
                ptime = 0;
              }

              // Set the Total Fats label
              int totalTime = ptime! + ctime!;
              setState(() {
                _totalTime = totalTime;
              });
            },
          ),
        ]));
  }

  Widget photoView() {
    return Column(
      children: [
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
      ],
    );
  }

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

  Widget pageDivider() {
    return const Divider(
      color: secondaryOrange,
      height: 60.0,
      thickness: 4,
      indent: 15,
      endIndent: 15,
    );
  }

  // Any optional fields that were left blank are defaulted to
  // a default value before uploaded to DB.
  void defaultOptionalFields() {
    if (_carbsController.text == "") {
      _carbsController.text = "0";
    }
    if (_cholesterolController.text == "") {
      _cholesterolController.text = "0";
    }
    if (_proteinController.text == "") {
      _proteinController.text = "0";
    }
    if (_sodiumController.text == "") {
      _sodiumController.text = "0";
    }
    if (_sugarController.text == "") {
      _sugarController.text = "0";
    }
    if (_fiberController.text == "") {
      _fiberController.text = "0";
    }
    if (_unsatFatController.text == "") {
      _unsatFatController.text = "0";
    }
    if (_satFatController.text == "") {
      _satFatController.text = "0";
    }
    if (_caloriesController.text == "") {
      _caloriesController.text = "0";
    }
    if (_servingsController.text == "") {
      _servingsController.text = "0";
    }
    if (_cookTimeController.text == "") {
      _cookTimeController.text = "0";
    }
    if (_prepTimeController.text == "") {
      _prepTimeController.text = "0";
    }
  }

  // Checks the required fields for a Recipe.
  // Returns a string of the fields needed to be filled to be
  // reported in an alert dialog.
  // Returns an empty string if all required fields are filled.
  String checkRequiredFields() {
    String emptyFields = "";
    if (_titleController.text == "") {
      emptyFields += "Recipe Title\n";
    }
    if (_descriptionController.text == "") {
      emptyFields += "Description\n";
    }
    if (_ingrs.isEmpty) {
      emptyFields += "Ingredients (one minimum requried.)\n";
    }
    if (_steps.isEmpty) {
      emptyFields += "Steps (one minimum requried.)\n";
    }
    if (_selectedImg == null) {
      emptyFields += "Photo of recipe required.\n";
    }

    return emptyFields;
  }

  // Records whether user wants to leave page
  exitPopup(context) {
    return showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) => Theme(
              data: Theme.of(context)
                  .copyWith(dialogBackgroundColor: primaryGray),
              child: AlertDialog(
                content: const Text("End Recipe creation?",
                    style: TextStyle(color: Colors.white)),
                actions: [
                  ElevatedButton(
                      child: const Text("No"),
                      onPressed: () {
                        _exitPage = false;
                        Navigator.of(context).pop(); // pops the popup
                      }),
                  ElevatedButton(
                      child: const Text("Yes"),
                      onPressed: () {
                        _exitPage = true;
                        Navigator.of(context).pop(); // pops the page
                      })
                ],
              ),
            ),
          );
        });
  }

  // Leaves page if user requested from exitPopup.
  confirmExit(context) {
    if (_exitPage) {
      Navigator.of(context).pop(); // pops the page.
    } else {
      return;
    }
  }

  // Circle Indicator shown when upload is in progress.
  showCircleIndicator() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => Theme(
            data:
                Theme.of(context).copyWith(dialogBackgroundColor: primaryGray),
            child: AlertDialog(
                // Show the indicator if uploading
                content: _uploading
                    ? const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [Center(child: CircularProgressIndicator())])
                    // Show nothing otherwise, The dialog will still need to be popped.
                    : null),
          ),
        );
      },
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
}

// Ingr for Recipe creation, created here seperately modifying
// Ingredient.dart throws errors in shopping cart.
class Ingr {
  int? id;
  String name;
  double amnt;
  String unit;
  String desc = "";
  Ingr(this.id, this.name, this.amnt, this.unit, this.desc);
}
