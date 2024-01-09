import 'package:chefd_app/home.dart';
import 'package:chefd_app/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:chefd_app/utils/constants.dart';
import 'package:google_fonts/google_fonts.dart';

class AdditionalInfoWidget extends StatefulWidget {
  const AdditionalInfoWidget({super.key});

  @override
  State<AdditionalInfoWidget> createState() => _AdditionalInfoState();
}

class _AdditionalInfoState extends State<AdditionalInfoWidget> {
  List<dynamic>? allergiesDietsList = List.empty(growable: true);
  List<dynamic>? userAllerDietList = List.empty(growable: true);

  List<dynamic>? DBList = List.empty(growable: true);
  List<dynamic>? selectedAllergiesDiets = List.empty(growable: true);
  List<String> selectedFilters = [];
  List<String> translatedFilters = [];
  final List<String> categories = ['Allergies', 'Diets'];

  bool hasData = false;
  bool _isLoading = false;
  bool createdList = false;
  bool searchActive = false;
  dynamic uID;

  Future<String?> uploadToDB({
    required final String user_id,
  }) async {
    // Clears all allergens and diets everytime we update
    await supabase
        .from(userAllergiesDiets)
        .delete()
        .match({'user_id': user_id});

    // uploads new and prexisting diets and allergies.
    if (selectedAllergiesDiets!.isNotEmpty) {
      for (var i = 0; i < selectedAllergiesDiets!.length; i++) {
        await supabase.from(userAllergiesDiets).insert({
          'user_id': user_id,
          'allergy_diet_id': selectedAllergiesDiets?[i]["id"]
        });
      }
    }
  }

  Future<void> fetchFromDB() async {
    if (!createdList) {
      uID = supabase.auth.currentUser?.id;

      // Pull all allergens & diets currently available.
      final allAllerDietsData = await supabase.from(allergiesDiets).select("*");

      // Pull user Data
      List<int> userAllerDietsIDs = [];
      try {
        final userData = await supabase
            .from(userAllergiesDiets)
            .select("*")
            .eq('user_id', uID);
        userAllerDietList = userData;

        // Make list of ID's of user's aller Diets
        for (var i = 0; i < userAllerDietList!.length; i++) {
          userAllerDietsIDs.add(userAllerDietList![i]['allergy_diet_id']);
        }
      } catch (e) {
        // User DNE
      }

      // Populate UI list
      allergiesDietsList = allAllerDietsData;

      if (allAllerDietsData.length != 0 || allAllerDietsData != null) {
        for (var i = 0; i < allergiesDietsList!.length; i++) {
          // cross reference user's selected allerDiet info w/ allerDiet's available.
          if (userAllerDietsIDs.contains(allergiesDietsList?[i]['id'])) {
            allergiesDietsList?[i]["isSelected"] = true;

            // Also add into selectedDiets to later be (re)uploaded
            // This is since we clear the table and upload the new allergies and
            // diets every time. So we add the prexisting ones back into this list.
            selectedAllergiesDiets!.add({
              'id': allergiesDietsList?[i]['id'],
              'label': allergiesDietsList?[i]['label'],
              'is_allergy': allergiesDietsList?[i]['is_allergy'],
              'is_selected': true,
            });
          } else {
            allergiesDietsList?[i]["isSelected"] = false;
          }
        }
      }

      DBList = allergiesDietsList;
      createdList = true;
    }

    if (allergiesDietsList != null && !searchActive) {
      allergiesDietsList = DBList;
      hasData = true;
    }
    // return data;
  }

  void getFilters() {
    translatedFilters = [];
    if (selectedFilters.contains('Allergies')) {
      translatedFilters.add('true');
    }
    if (selectedFilters.contains('Diets')) {
      translatedFilters.add('false');
    }

    final filterProducts = allergiesDietsList?.where((item) {
      return translatedFilters.isEmpty ||
          translatedFilters.contains(item["is_allergy"].toString());
    }).toList();

    if (filterProducts!.isNotEmpty) {
      allergiesDietsList = filterProducts;
    }
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
    return FutureBuilder(
      future: fetchFromDB(),
      builder: (context, snapshot) {
        if (!hasData) {
          return _loadingScreen();
        }
        if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        } else {
          getFilters();
          return getBackground();
        }
      },
    );
  }

  Widget getBackground() {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/logo.jpg',
          width: 250,
          height: 60,
        ),
        backgroundColor: primaryOrange,
        centerTitle: true,
      ),
      backgroundColor: background,
      body: SafeArea(
        child: Container(
            child: Column(
          children: [
            const SizedBox(height: 30),
            const Text(
              "Please Select Allergies or Diets",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 15,
                ),
                child: TextField(
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: white),
                  decoration: InputDecoration(
                      hintStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: white),
                      suffixIcon: const Icon(
                        Icons.search,
                        color: white,
                      ),
                      fillColor: white,
                      hintText: 'Name of Allergy or Diet',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40),
                      )),
                  onChanged: searchList,
                )),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: categories
                  .map((category) => FilterChip(
                      selected: selectedFilters.contains(category),
                      label: Text(category),
                      onSelected: (selected) async {
                        setState(() {
                          if (selected) {
                            selectedFilters.add(category);
                          } else {
                            selectedFilters.remove(category);
                          }
                        });
                      }))
                  .toList(),
            ),
            Expanded(
              child: ListView.builder(
                  itemCount: allergiesDietsList?.length,
                  itemBuilder: (BuildContext context, int index) {
                    //return item
                    return allergenDietItem(
                      allergiesDietsList?[index]['label'],
                      allergiesDietsList?[index]['isSelected'],
                      index,
                    );
                  }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 15,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });
                    await uploadToDB(user_id: uID);
                    setState(() {
                      _isLoading = false;
                    });
                    // Acc creation -> Home Screen
                    _navigateToHome();
                  },
                  style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(color: Colors.white),
                      padding: const EdgeInsets.all(3)),
                  child: const Text("Save"),
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeWidget()),
      (route) => false,
    );
  }

  void searchList(String q) async {
    if (q.isEmpty)
      searchActive = false;
    else
      searchActive = true;
    final suggestions = allergiesDietsList?.where((element) {
      final label = element['label'].toString().toLowerCase();
      final input = q;
      return label.contains(input);
    }).toList();

    setState(() {
      allergiesDietsList = suggestions;
    });
  }

  //TODO CHANGE COLOR TO BE UNIFORM
  Widget allergenDietItem(String name, bool isSelected, int id) {
    return ListTile(
      title: Text(name,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: white)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.blue)
          : const Icon(Icons.circle, color: Colors.white),
      onTap: () async {
        setState(() {
          allergiesDietsList?[id]['isSelected'] =
              !allergiesDietsList?[id]['isSelected'];

          if (allergiesDietsList?[id]['isSelected'] == true) {
            selectedAllergiesDiets?.add(allergiesDietsList?[id]);
          } else if (allergiesDietsList?[id]['isSelected'] == false) {
            selectedAllergiesDiets?.removeWhere((element) =>
                element['label'] == allergiesDietsList?[id]['label']);
          }
        });
      },
    );
  }
}
