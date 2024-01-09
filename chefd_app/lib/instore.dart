import 'package:chefd_app/models/shopping_list.dart';
import 'package:chefd_app/theme/colors.dart';
import 'package:chefd_app/utils/constants.dart';
import 'package:flutter/material.dart';

class InStore extends StatefulWidget {
  const InStore({super.key});

  @override
  State<InStore> createState() => _InStoreState();
}

class _InStoreState extends State<InStore> {
  List<dynamic> ingrs = [];
  Map location = {};
  final ingrInputController = TextEditingController();
  late Size screenSize;
  bool isPhone = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      ingrs = args['ingrs'] as List<dynamic>;
      location = args['location'] as Map;
      screenSize = MediaQuery.of(context).size;
      if (screenSize.width > 500) {
        isPhone = false;
      } else {
        isPhone = true;
      }
    });
    return Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: const Text('In-Store Shopping'),
          // leading: IconButton(
          //   icon: const Icon(Icons.settings),
          //   onPressed: () {
          //     Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //             builder: (context) => const SettingsWidget(),
          //             settings: RouteSettings(
          //                 arguments: supabase.auth.currentUser!.id)));
          //   },
          // ),
          centerTitle: true,
          backgroundColor: primaryOrange,
          elevation: 0.0,
        ),
        body: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(basePadding),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(basePadding),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            "Welcome to ${location['name']}",
                            style: const TextStyle(color: white, fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(basePadding),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            "Don't see what you're looking for? Try searching for it!",
                            style: TextStyle(color: white, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(basePadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: TextField(
                            style: const TextStyle(color: white),
                            controller: ingrInputController,
                          ),
                        ),
                        Expanded(
                            flex: 4,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                if (ingrInputController.text.isEmpty) {
                                  showAlertDialog(
                                      context, "Item name can't be empty.");
                                } else {
                                  List<dynamic> rec = await getRecommendations(
                                      ingrInputController.text,
                                      location["locationId"],
                                      6);
                                  setState(() {
                                    showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                              title: Text(
                                                  "Results for ${ingrInputController.text}"),
                                              content: buildRecommendations(
                                                  ingrInputController.text,
                                                  rec),
                                              //Text("tesing"),
                                              actions: [
                                                ElevatedButton(
                                                  onPressed: () {
                                                    if (Navigator.canPop(
                                                        context)) {
                                                      Navigator.pop(context);
                                                    }
                                                  },
                                                  child: const Padding(
                                                    padding: EdgeInsets.all(1),
                                                    child: Text('Done'),
                                                  ),
                                                ),
                                              ],
                                            ));
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(basePadding),
                                  elevation: 10.0,
                                  textStyle:
                                      const TextStyle(color: Colors.white)),
                              icon: const Icon(Icons.search_rounded),
                              label: const Text('Find Item'),
                            ))
                      ],
                    ),
                  ),
                  ingrListView(),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.done),
                    label: const Text('Done'),
                  ),
                ])));
  }

  Widget ingrListView() {
    return Container(
      height: screenSize.height * 0.60,
      alignment: Alignment.center,
      child: ListView.builder(
          itemCount: ingrs.length,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemBuilder: (context, index) {
            return buildIngr(index, ingrs[index]);
          }),
    );
  }

  Widget buildIngr(int i, Shopping_List s) {
    return Container(
        decoration: const BoxDecoration(
            color: secondaryOrange,
            borderRadius: BorderRadius.all(Radius.circular(4))),
        margin: const EdgeInsets.all(4.0),
        key: ValueKey(i),
        child: ListTile(
          key: Key('$i'),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: basePadding, vertical: basePadding),
          leading: s.img == "" || s.img == "null"
              ? const Text("")
              : CircleAvatar(
                  backgroundImage: NetworkImage(s.img),
                ),
          title: s.done
              ? s.storeIngrName == ""
                  ? Text(
                      s.ingr.name,
                      style: const TextStyle(
                          decoration: TextDecoration.lineThrough, fontSize: 12),
                    )
                  : Text(
                      s.storeIngrName,
                      style: const TextStyle(
                          decoration: TextDecoration.lineThrough, fontSize: 12),
                    )
              : s.storeIngrName == ""
                  ? Text(s.ingr.name)
                  : s.storeIngrName.length > 15
                      ? Text(
                          s.storeIngrName,
                          style: const TextStyle(fontSize: 12),
                        )
                      : Text(s.storeIngrName),
          subtitle: Text(s.aisle),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // s.aisle.toLowerCase().startsWith("aisle") ||
              //         s.aisle.toLowerCase().startsWith("meat")
              if (!s.done)
                s.shelf != "null" || s.bay != "null"
                    ? Column(
                        children: [
                          Text("Shelf - ${s.shelf}"),
                          if (s.bay != "999") Text("Bay - ${s.bay}"),
                        ],
                      )
                    : const Text(""),
              s.done
                  ? IconButton(
                      icon: const Icon(Icons.check_box, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          s.done = false;
                          //modifyShoppingList("Undone", s);
                        });
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.check_box_outline_blank,
                          color: Colors.white),
                      onPressed: () {
                        setState(() {
                          s.done = true;
                          //modifyShoppingList("Done", s);
                          ingrs.removeAt(i);
                          ingrs.add(s);
                        });
                      },
                    ),
              if (!s.done)
                IconButton(
                    onPressed: () async {
                      List<dynamic> rec = await getRecommendations(
                          s.ingr.name, location["locationId"], 6);
                      setState(() {
                        showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  title: Text(
                                      "Other Recommendations for ${s.ingr.name}"),
                                  content: buildRecommendations(
                                      s.storeIngrName, rec),
                                  //Text("tesing"),
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () {
                                        if (Navigator.canPop(context)) {
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(1),
                                        child: Text('Done'),
                                      ),
                                    ),
                                  ],
                                ));
                      });
                    },
                    icon: const Icon(
                      Icons.question_mark_rounded,
                      color: white,
                    ))
            ],
          ),
        ));
  }

  Widget buildRecommendations(String storeIngrName, List<dynamic> rec) {
    return SingleChildScrollView(
        child: Column(
      children: [
        for (int i = 0; i < rec.length; i++)
          if (storeIngrName != rec[i]['description']) buildRec(i, rec[i])
      ],
    ));
  }

  Widget buildRec(int i, Map<dynamic, dynamic> ingr) {
    String image = "";
    String bay = "";
    String shelf = "";
    String desc = "";
    String aisle = "";
    // Grab aisle information
    try {
      var aisleLocations = ingr['aisleLocations'][0];
      aisle = aisleLocations['description'].toString();
      bay = aisleLocations['bayNumber'].toString();
      shelf = aisleLocations['shelfNumber'].toString();
    } catch (e) {}
    try {
      desc = ingr['description'];
    } catch (e) {}

    try {
      //Grab thumbnail
      var img = ingr['images'][0]['sizes'] as List<dynamic>;
      var thumbnail = img[img.length - 1] as Map;
      image = thumbnail['url'].toString();
    } catch (e) {}
    return Container(
        decoration: const BoxDecoration(
            color: secondaryOrange,
            borderRadius: BorderRadius.all(Radius.circular(4))),
        margin: const EdgeInsets.all(4.0),
        key: ValueKey(i),
        child: ListTile(
          key: Key('$i'),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: basePadding, vertical: basePadding),
          leading: image == ""
              ? const Text("")
              : Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(image),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(2),
                        child: Text(
                          aisle,
                          style: const TextStyle(
                              fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      )
                    ]),
          title: Text(
            desc,
            style: const TextStyle(fontSize: 12),
          ),
          subtitle:
              shelf == "null" || bay == "null" || shelf == "" || bay == "null"
                  ? const Text("")
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text(
                            "Shelf - $shelf    ",
                            style: const TextStyle(fontSize: 12),
                          ),
                          bay == "999"
                              ? const Text("")
                              : Text(
                                  "Bay - $bay",
                                  style: const TextStyle(fontSize: 12),
                                ),
                        ]),
        ));
  }

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
}
