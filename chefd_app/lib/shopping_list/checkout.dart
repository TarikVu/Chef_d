import 'package:chefd_app/utils/db_functions.dart';
import 'package:flutter/material.dart';
import 'package:chefd_app/utils/constants.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// The `CheckoutPage` class is a StatefulWidget that represents the checkout page of the app.
/// It takes a `shoppingList` parameter, which is a list of dynamic objects representing the items in the shopping list.
/// The class handles the OAuth flow, token exchange, product search, adding items to the cart, and navigating to the cart.
class CheckoutPage extends StatefulWidget {
  final List<dynamic> shoppingList;

  const CheckoutPage({Key? key, required this.shoppingList}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _CheckoutPageState createState() => _CheckoutPageState();
}

/// The `_CheckoutPageState` class is the state of the `CheckoutPage` widget.
/// It manages the shopping list, OAuth credentials, access token, cart URL, web view controller, and initial URL.
/// It also handles the initialization, OAuth flow, token exchange, processing the shopping list, product search, adding items to the cart, and navigating to the cart.
class _CheckoutPageState extends State<CheckoutPage> {
  var shoppingList = [];
  final String clientId = krogerClientId;
  final String clientSecret = krogerClientSecret;
  final String redirectUri = 'com.chefdapp://oauth2redirect'; // URL-encoded
  String accessToken = '';
  String cartUrl = 'https://www.kroger.com/cart';
  InAppWebViewController? webViewController;
  String initialUrl = 'about:blank';
  bool canPop = true;

  @override
  void initState() {
    shoppingList = widget.shoppingList;
    super.initState();
    startOAuthFlow();
  }

  /// Starts the OAuth flow by constructing the authorization URL and updating the initial URL.
  void startOAuthFlow() {
    const scope = 'product.compact cart.basic:write';
    final authUrl =
        Uri.https('api.kroger.com', '/v1/connect/oauth2/authorize', {
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'scope': scope,
    }).toString();

    setState(() {
      initialUrl = authUrl;
    });
  }

  /// Exchanges the authorization code for an access token by making a POST request to the token endpoint.
  /// Updates the access token and processes the shopping list if the request is successful.
  Future<void> exchangeCodeForToken(String authorizationCode) async {
    final String authorization =
        base64Encode(utf8.encode('$clientId:$clientSecret'));
    final response = await http.post(
      Uri.parse('https://api.kroger.com/v1/connect/oauth2/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Basic $authorization',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': authorizationCode,
        'redirect_uri': redirectUri,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        accessToken = data['access_token'];
      });
      await processShoppingList();
    } else {
      //print('Failed to exchange code for token: ${response.body}');
    }
  }

  /// Processes the shopping list by searching for each item, adding it to the cart if found, and navigating to the cart.
  Future<void> processShoppingList() async {
    for (var item in shoppingList) {
      if (!item.done) {
        var productIdAndSoldBy = await searchProduct(item.ingr.name);
        if (productIdAndSoldBy != null) {
          await addToCart(productIdAndSoldBy, item.amount);
        }
      }
    }
    navigateToCart();
    canPop = true;
  }

  /// Searches for a product by the given search term and returns the product ID and sold by information.
  Future<List<String>?> searchProduct(String searchTerm) async {
    List<String> productIdAndSoldBy = [];
    if (accessToken.isEmpty) {
      //print('Access token is not available.');
      return null;
    }

    final response = await http.get(
      Uri.parse('https://api.kroger.com/v1/products?filter.term=$searchTerm'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['data'] != null && data['data'].isNotEmpty) {
        //print('soldBy: ${data['data'][0]['items'][0]['size']}');
        productIdAndSoldBy.add(data['data'][0]['productId']);
        productIdAndSoldBy.add(data['data'][0]['items'][0]['size']);
      }
    } else {
      //print('Failed to search product: ${response.body}');
    }
    return productIdAndSoldBy;
  }

  /// Extracts the first double value from the input string using regular expressions.
  double extractFirstDouble(String inputString) {
    final regex = RegExp(r'(-?\d+(\.\d+)?)');
    final match = regex.firstMatch(inputString);

    return double.parse(match!.group(0)!);
  }

  /// Adds the product with the given product ID and sold by information to the cart with the specified quantity.
  Future<void> addToCart(
      List<String> productIdAndSoldBy, double quantity) async {
    if (accessToken.isEmpty) {
      //print('Access token is not available.');
      return;
    }

    double soldAmount = extractFirstDouble(productIdAndSoldBy[1]);

    double quan = quantity / soldAmount;
    int quanInt = quan.ceil().toInt();

    final response = await http.put(
      Uri.parse('https://api.kroger.com/v1/cart/add'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode({
        'items': [
          {
            'upc': productIdAndSoldBy[0],
            'quantity': quanInt,
            'modality': 'DELIVERY',
          },
        ],
      }),
    );

    if (response.statusCode != 204) {
      //print('Failed to add product to cart: ${response.body} $productIdAndSoldBy[0]');
    } else {
      //print('Product added to cart successfully');
    }
  }

  /// Navigates to the cart by loading the cart URL in the web view.
  void navigateToCart() {
    if (webViewController != null) {
      webViewController!
          .loadUrl(urlRequest: URLRequest(url: Uri.parse(cartUrl)));
    }
  }

  Future<bool> _onWillPop() async {
    if (canPop) {
      Navigator.pop(context);
    }
    return canPop;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          appBar: AppBar(title: const Text('Kroger Checkout'), actions: [
            IconButton(
              onPressed: () => showDialog<String>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('Transfer to Pantry'),
                  content: const Text(
                    'Would you like to transfer shopping list to your pantry?',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        insertCartIntoPantry();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Yes'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('No'),
                    ),
                  ],
                ),
              ),
              icon: const Icon(Icons.check),
            ),
          ]),
          body: InAppWebView(
            initialUrlRequest: URLRequest(url: Uri.parse(initialUrl)),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onLoadStart: (controller, url) {
              if (url.toString().startsWith(redirectUri)) {
                final code = Uri.parse(url.toString()).queryParameters['code'];
                if (code != null) {
                  canPop = false;
                  exchangeCodeForToken(code);
                }
                controller.loadUrl(
                    urlRequest: URLRequest(url: Uri.parse('about:blank')));
              }
            },
          ),
        ));
  }
}
