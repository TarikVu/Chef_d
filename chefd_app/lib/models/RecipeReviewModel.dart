class RecipeReview {
  int id;

  String userID;

  String body;

  String title;

  double rating;

  String username;

  String picture;

  RecipeReview(this.id, this.userID, this.body, this.title, this.rating,
      this.username, this.picture);

  static List<RecipeReview> setReviews(List<dynamic> reviews) {
    List<RecipeReview> list = [];
    for (int i = 0; i < reviews.length; i++) {
      dynamic curReview = reviews[i];
      if (curReview['picture'] == null) {
        list.add(RecipeReview(
            curReview['recipe_id'],
            curReview['user_id'],
            curReview['body'],
            curReview['title'],
            double.parse(curReview['rating'].toString()),
            curReview['userinfo']['username'],
            ""));
      } else {
        list.add(RecipeReview(
            curReview['recipe_id'],
            curReview['user_id'],
            curReview['body'],
            curReview['title'],
            double.parse(curReview['rating'].toString()),
            curReview['userinfo']['username'],
            curReview['picture']));
      }
    }
    return list;
  }
}
