import 'dart:convert';
import 'package:chefd_app/models/user_model.dart';

import '../utils/constants.dart';
import 'ingredient_model.dart';
import 'package:http/http.dart' as http;

class Shopping_List {
  String userID;

  int ingrID;

  double amount;

  String unit;

  bool done;

  String recipeImg;

  String recipeTitle;

  Ingredient ingr;

  double cost;

  String aisle;

  String img;

  String storeIngrName;

  String bay;

  String shelf;

  Shopping_List(
      this.userID,
      this.ingrID,
      this.amount,
      this.unit,
      this.done,
      this.recipeImg,
      this.recipeTitle,
      this.ingr,
      this.cost,
      this.aisle,
      this.img,
      this.storeIngrName,
      this.bay,
      this.shelf);

  // Takes in DB response and returns list of ingredients for that user.
  List<Shopping_List> getShoppingList(
      List<dynamic> ingrs,
      double cost,
      String aisle,
      String img,
      String storeIngrName,
      String bay,
      String shelf) {
    List<Shopping_List> l = [];
    for (int i = 0; i < ingrs.length; i++) {
      dynamic curIngr = ingrs[i];

      l.add(Shopping_List(
          curIngr['user_id'],
          curIngr['ingredient_id'],
          double.parse(curIngr['amount'].toString()),
          curIngr['unit'],
          curIngr['done'],
          curIngr['recipes']['image'],
          curIngr['recipes']['title'],
          Ingredient(curIngr['ingredients']['label']),
          cost,
          aisle,
          img,
          storeIngrName,
          bay,
          shelf));
    }

    return l;
  }
}

Map<String, String> requestHeaders = {
  "Content-Type": "application/x-www-form-urlencoded",
  "Authorization": "Basic $krogerEncoded"
};

Future<dynamic> getRecipe(int recipeId) async {
  final recipeResponse =
      await supabase.from(recipes).select("title, image").eq('id', recipeId);
  return recipeResponse;
}

Future<List?> getShoppingList() async {
  String currentUser = "";
  try {
    currentUser = supabase.auth.currentUser!.id;
  } catch (e) {}
  final listReponse = await supabase
      .from(shoppingCart)
      .select(
          'user_id, ingredient_id, amount, unit, done, recipes(image, title), ingredients(label)')
      .eq('user_id', currentUser);
  List<Shopping_List> l = [];
  for (int i = 0; i < listReponse.length; i++) {
    dynamic curIngr = listReponse[i];
    try {
      l.add(Shopping_List(
          curIngr['user_id'],
          curIngr['ingredient_id'],
          double.parse(curIngr['amount'].toString()),
          curIngr['unit'],
          curIngr['done'],
          curIngr['recipes']['image'],
          curIngr['recipes']['title'],
          Ingredient(curIngr['ingredients']['label']),
          0.0,
          "",
          "",
          "",
          "",
          ""));
    } catch (e) {
      l.add(Shopping_List(
          curIngr['user_id'],
          curIngr['ingredient_id'],
          double.parse(curIngr['amount'].toString()),
          curIngr['unit'],
          curIngr['done'],
          "",
          "",
          Ingredient(curIngr['ingredients']['label']),
          0.0,
          "",
          "",
          "",
          "",
          ""));
      //print("ERROR WHILE BUILDING MODEL LIST: " + e.toString());
    }
  }
  return l;
}

Future<dynamic> getKrogerToken() async {
  dynamic token;

  String baseUrl = "https://api.kroger.com/v1/connect/oauth2/token";
  Map<String, String> requestHeaders = {
    "Content-Type": "application/x-www-form-urlencoded",
    "Authorization": "Basic $krogerEncoded"
  };
  Map<String, String> data = {
    'grant_type': "client_credentials",
    'scope': "product.compact"
  };
  try {
    var url = Uri.parse(baseUrl);

    var response = await http.post(url, headers: requestHeaders, body: data);
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);
      token = decodedResponse['access_token'];
    }
  } catch (e) {
    print(e.toString());
  }
  return token;
}

Future<List<dynamic>> getLocation(String location, dynamic token) async {
  List<dynamic> locations = [];
  String locationId = "";
  Map<String, String> requestHeadersToken = {
    "Accept": "application/json",
    "Authorization": "Bearer $token"
  };

  Map<String, String> dataLocation = {
    'filter.zipCode.near': location,
    'filter.limit': "5"
  };

  try {
    var locationUri =
        Uri.https("api.kroger.com", "/v1/locations", dataLocation);

    var locationResponse =
        await http.get(locationUri, headers: requestHeadersToken);
    print('Location response status: ${locationResponse.statusCode}');
    print('Location response body: ${locationResponse.body}');
    if (locationResponse.statusCode == 200) {
      final decodedResponse = jsonDecode(locationResponse.body);
      locations = decodedResponse['data'];
      locationId = decodedResponse['data'][0]['locationId'];
      print(locationId);
    }
  } catch (e) {
    print(e.toString());
  }

  return locations;
}

Future<List> getRecommendations(
    String ingrName, String locationId, int limit) async {
  List<dynamic> rec = [];
  String token;
  late dynamic decodedResponse;
  token = await getKrogerToken();
  Map<String, String> dataProduct = {
    'filter.term': ingrName,
    'filter.locationId': locationId,
    'filter.limit': limit.toString(),
    'filter.fulfillment': "ais"
  };
  Map<String, String> requestHeadersToken = {
    "Accept": "application/json",
    "Authorization": "Bearer $token"
  };

  try {
    var productUri = Uri.https("api.kroger.com", "/v1/products", dataProduct);
    var productResponse =
        await http.get(productUri, headers: requestHeadersToken);
    print('Location response status: ${productResponse.statusCode}');
    print('Location response body: ${productResponse.body}');
    if (productResponse.statusCode == 200) {
      decodedResponse = jsonDecode(productResponse.body);
      rec = decodedResponse['data'];
    }
  } catch (e) {}

  return rec;
}

Future<List> getIngrCosts(List<dynamic> l, String locationId) async {
  String token;
  token = await getKrogerToken();
  //locationId = await getLocation(location, token) as String;

  Map<String, String> dataProduct = {
    'filter.term': "",
    'filter.locationId': locationId,
    'filter.limit': "1",
    'filter.fulfillment': "ais"
  };
  Map<String, String> requestHeadersToken = {
    "Accept": "application/json",
    "Authorization": "Bearer $token"
  };

  for (int i = 0; i < l.length; i++) {
    Shopping_List curIngr = l[i];
    dataProduct['filter.term'] = curIngr.ingr.name;
    try {
      var productUri = Uri.https("api.kroger.com", "/v1/products", dataProduct);

      var productResponse =
          await http.get(productUri, headers: requestHeadersToken);
      print('Location response status: ${productResponse.statusCode}');
      print('Location response body: ${productResponse.body}');
      if (productResponse.statusCode == 200) {
        final decodedResponse = jsonDecode(productResponse.body);
        var productCost =
            decodedResponse['data'][0]['items'][0]['price']['regular'];
        var aisleLocations = decodedResponse['data'][0]['aisleLocations'][0];
        var aisle = aisleLocations['description'];
        String bay = aisleLocations['bayNumber'].toString();
        String shelf = aisleLocations['shelfNumber'].toString();
        String desc = decodedResponse['data'][0]['description'];
        try {
          var img =
              decodedResponse['data'][0]['images'][0]['sizes'] as List<dynamic>;
          var thumbnail = img[img.length - 1] as Map;
          curIngr.img = thumbnail['url'].toString();
        } catch (e) {}
        try {
          curIngr.cost = double.parse(productCost.toString());
        } catch (e) {}
        curIngr.aisle = aisle;
        curIngr.storeIngrName = desc;
        curIngr.bay = bay;
        curIngr.shelf = shelf;
        l[i] = curIngr;
      }
    } catch (e) {
      print(e.toString());
    }
  }
  return l;
}

double getTotalCost(List<dynamic> l) {
  double sum = 0;
  for (int i = 0; i < l.length; i++) {
    Shopping_List curIngr = l[i];
    sum += curIngr.cost;
  }
  return sum;
}

Future<void> deleteOneShoppingList(Shopping_List s) async {
  try {
    await supabase
        .from(shoppingCart)
        .delete()
        .match({'user_id': s.userID, 'ingredient_id': s.ingrID});
  } catch (e) {
    print(e);
  }
}

Future<void> modifyShoppingList(String mod, Shopping_List s) async {
  switch (mod) {
    case "Add":
      final response = await supabase
          .from(shoppingCart)
          .update({'amount': s.amount + 1.0})
          .eq('ingredient_id', s.ingrID)
          .eq('user_id', s.userID)
          .select();
      break;
    case "Minus":
      if (s.amount - 1.0 <= 0) {
      } else {
        final response = await supabase
            .from(shoppingCart)
            .update({'amount': s.amount - 1.0})
            .eq('ingredient_id', s.ingrID)
            .eq('user_id', s.userID)
            .select();
      }
      break;
    case "Done":
      final response = await supabase
          .from(shoppingCart)
          .update({'done': s.done})
          .eq('ingredient_id', s.ingrID)
          .eq('user_id', s.userID)
          .select();
      break;
    case "Undone":
      final response = await supabase
          .from(shoppingCart)
          .update({'done': s.done})
          .eq('ingredient_id', s.ingrID)
          .eq('user_id', s.userID)
          .select();
      break;
  }
}

Future<void> deleteAllShoppingList(dynamic l) async {
  Shopping_List item = l;
  try {
    await supabase.from(shoppingCart).delete().eq('user_id', item.userID);
  } catch (e) {
    print(e);
  }
}
