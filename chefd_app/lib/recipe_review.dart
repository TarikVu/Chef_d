import 'package:chefd_app/models/RecipeReviewModel.dart';
import 'package:chefd_app/theme/colors.dart';
import 'package:chefd_app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RecipeReviewWidget extends StatefulWidget {
  const RecipeReviewWidget({super.key});

  @override
  State<RecipeReviewWidget> createState() => _RecipeReviewState();
}

class _RecipeReviewState extends State<RecipeReviewWidget> {
  List<RecipeReview>? reviews = [];
  int recipeID = 0;
  bool hasData = false;

  @override
  void initState() {
    super.initState();
    //https://stackoverflow.com/questions/56395081/unhandled-exception-inheritfromwidgetofexacttype-localizationsscope-or-inheri
    Future.delayed(Duration.zero, () {
      recipeID = ModalRoute.of(context)!.settings.arguments as int;
      getReviews();
    });
  }

  Future<List> _processData() {
    return Future.wait([getReviews()]);
  }

  Future<void> getReviews() async {
    final reviewResponse =
        await supabase.from(recipeReviews).select().eq('recipe_id', recipeID);

    // Ensure that widget is mounted before setting state.
    if (!mounted) return;

    setState(() {
      if (reviewResponse.length != 0) {
        reviews = RecipeReview.setReviews(reviewResponse);
      }
      if (reviews != null) {
        hasData = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _processData(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (!hasData) {
            return _loadingScreen();
          } else {
            return _reviewScreen();
          }
        });
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

  Widget _reviewScreen() {
    return Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: const Text("Reviews"),
          centerTitle: true,
          backgroundColor: primaryOrange,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(basePadding),
          child: displayReviews(),
        ));
  }

  Widget displayReviews() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildReviewsColumn(),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Padding(
                padding: EdgeInsets.all(basePadding),
                child: Text('Done'),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget buildReviewsColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: buildReviewRows(),
    );
  }

  List<Widget> buildReviewRows() {
    List<Row> list = [];
    reviews?.sort(((a, b) {
      return a.body.toLowerCase().compareTo(b.body.toLowerCase());
    }));
    for (RecipeReview r in reviews!) {
      list.add(Row(
        children: [
          RatingBar.builder(
            initialRating: r.rating,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            maxRating: 5,
            ignoreGestures: true,
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (value) => value,
          ),
          Flexible(
              child: TextLabel("${r.rating} stars", secondaryOrange, 10, false))
        ],
      ));
      list.add(Row(
        children: [
          Flexible(child: TextLabel(r.body, white, 14, false)),
          const SizedBox(
            height: divHeight,
          ),
        ],
      ));
    }
    return list;
  }
}
