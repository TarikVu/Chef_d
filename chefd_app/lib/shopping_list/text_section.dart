import 'package:flutter/material.dart';


class TextSection extends StatelessWidget {
  /// The name of the ingredient.
  final String name;
  /// The estimated cost of the ingredient.
  final String cost;
  /// horizontal padding for the text
  static const double hPad = 16.0; 

  /// The ingredients text section of the shopping list, 
  /// includes both the title and list of ingredients.
  TextSection(this.name, this.cost);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(hPad, 32.0, hPad, 4.0),
          child: Text("${name} - \$$cost", textAlign: TextAlign.left, 
            style: const TextStyle( 
              fontSize: 30.0,
            ),
          ),
        ),
        // Container(
        //   padding: const EdgeInsets.fromLTRB(hPad, 32.0, hPad, 4.0),
        //   child: Text(body, textAlign: TextAlign.center,
        //     style: const TextStyle(
        //       fontSize: 30.0,
        //     )
        //   ),
        // )
      ],
    );

  }
}